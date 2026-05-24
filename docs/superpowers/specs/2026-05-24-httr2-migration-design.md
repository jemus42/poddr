# httr2 migration design

**Status:** draft → awaiting user spec review
**Date:** 2026-05-24
**Target version:** poddr 0.3.0
**Predecessors:** poddr 0.2.7 maintenance pass (same session)
**Companion:** `~/vault/personal/projects/poddr inventory.md`, `~/vault/personal/projects/tRakt inventory.md`

## Summary

Replace poddr's `polite` + `httr`-based scraping layer with `httr2`. Introduce a single internal request helper (`poddr_get()`) that centralises user-agent, per-host throttling, retries on transient failures, and cross-run HTTP caching. Move robots.txt enforcement to an explicit `robotstxt::paths_allowed()` check at scraper entry points. Separate the disk-write side effect from the request orchestrators so the package composes cleanly with `targets`. Bring testing closer to tRakt's pattern by adding vcr cassettes for the network-touching layer while keeping the existing synthetic HTML fixture tests. Land opportunistic cleanups along the way.

## Background and motivation

poddr currently uses `polite::bow()` + `polite::scrape()` (built on `httr`). The 0.2.7 maintenance pass wrapped the one remaining bare `readr::read_delim()` call in `polite::politely()` so all HTTP requests now respect a per-host delay and robots.txt. `polite` is actively maintained (CRAN 0.1.4, 2026-05-11), so this migration is *not* driven by upstream rot.

It is driven by:

1. **No cross-run HTTP cache.** `polite`'s memoisation lives in process. Every scheduled GH Action run refetches every page, including thousands of effectively-immutable ATP archive pages and retired Incomparable show archives.
2. **No retry/backoff.** A single transient 5xx fails the entire run.
3. **httr2 is the substrate the rest of the user's R work is moving to.** tRakt 0.17.0 (2024) migrated to httr2 and the working pattern there is the reference implementation for this plan.

## Goals

- Cut upstream request volume on the nightly Action by an order of magnitude via `req_cache()` + `actions/cache@v4` persistence of the httr2 cache directory between runs.
- Survive transient upstream failures without rerunning the whole workflow.
- Compose cleanly with a `targets` pipeline (separating HTTP caching from disk-write side effects).
- Bring the package's structure into line with tRakt — single request helper, vcr cassettes, `Makefile` of devtools targets, `cli` throughout — so the two personal R packages share a maintenance template.

## Non-goals (explicit)

- Recovering Incomparable mothership subcategories lost in the June 2022 site redesign. Tracked as deferred TODO, not part of this migration.
- Async/parallel scraping. `req_throttle()`'s realm-based semantics are designed for sequential calls; concurrency would complicate throttle/cache reasoning for marginal wall-clock gain on a nightly job.
- CRAN release. Status stays WIP.
- Schema changes to returned tibbles. Column names, types, and semantics are preserved.
- OAuth / authenticated requests. All three sources are public.
- `lifecycle`-style deprecation of old `cache` semantics. Cosmetic for a sole-user package; we ship 0.3.0 with a clear `NEWS.md` entry instead.

## Architecture

### Layered model

```
                  ┌──────────────────────────────────┐
                  │   *_get_episodes / *_get_shows   │  <- entry points
                  │   (robotstxt check + iteration)  │
                  └──────────────┬───────────────────┘
                                 │
                  ┌──────────────▼───────────────────┐
                  │  *_parse_* (build URL,           │  <- per-source
                  │   call poddr_get, parse body)    │     parsers
                  └──────────────┬───────────────────┘
                                 │
                  ┌──────────────▼───────────────────┐
                  │  poddr_get(url, as)              │  <- single
                  │  request() |> req_user_agent     │     request
                  │   |> req_throttle(host realm)    │     function
                  │   |> req_retry(max_tries = 3)    │
                  │   |> req_cache(user_cache_dir,   │
                  │                7d, 100MB)        │
                  │   |> req_perform()               │
                  │   -> dispatch on `as`            │
                  └──────────────────────────────────┘
```

### Responsibilities

| Layer | Responsibility |
|---|---|
| Entry orchestrators (`*_get_episodes`, `*_get_shows`) | Iterate over inputs, call `robotstxt::paths_allowed()` once per host per invocation, drive progress reporting, forward `cache` to `poddr_get()`, return a tibble. **No disk side effects.** |
| Per-source parsers (`*_parse_*`) | Build a URL, call `poddr_get()`, parse the body into a tibble. `atp_parse_page()` is the exception — it takes an already-fetched HTML page (no request of its own) and stays as-is. |
| `poddr_get()` (internal) | Construct an httr2 request, attach UA / throttle / retry / cache, perform, dispatch the body by `as`. |
| `cache_podcast_data()` (exported) | Writes RDS (+ optional CSV) to disk. Caller-driven; no longer invoked from inside the orchestrators. |
| `update_cached_data()` (exported) | Convenience wrapper that fetches everything and writes everything. Sole-user, used by the GH Action. |

### `cache` argument semantics

`cache` refers exclusively to httr2 HTTP cache (per-request, 304-aware, cross-session via the user cache dir). Disk write of returned tibbles is a deliberate, semantically distinct, optional downstream step invoked via `cache_podcast_data()` or `update_cached_data()`. This separation is what makes the package compose with `targets`: orchestrators are side-effect free; the GH Action is the one caller that opts back in to disk persistence.

## `poddr_get()` API

Internal (not exported). Signature:

```r
poddr_get <- function(url,
                      as = c("html", "xml", "text"),
                      query = NULL,
                      cache = TRUE)
```

Implementation:

```r
poddr_get <- function(url, as = c("html", "xml", "text"), query = NULL, cache = TRUE) {
  as <- rlang::arg_match(as)

  req <- httr2::request(url) |>
    httr2::req_user_agent(getOption("poddr_user_agent", default_user_agent())) |>
    httr2::req_throttle(
      rate  = getOption("poddr_throttle_rate", 1 / 2),
      realm = httr2::url_parse(url)$hostname
    ) |>
    httr2::req_retry(
      max_tries    = 3,
      is_transient = \(resp) httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504)
    )

  if (!is.null(query)) req <- httr2::req_url_query(req, !!!query)

  if (isTRUE(cache)) {
    req <- httr2::req_cache(
      req,
      path     = getOption("poddr_cache_dir", tools::R_user_dir("poddr", "cache")),
      max_age  = getOption("poddr_cache_max_age", 7 * 86400),
      max_size = getOption("poddr_cache_max_size", 100 * 1024^2)
    )
  }

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) == 204 || identical(httr2::resp_body_string(resp), "")) {
    return(switch(as, html = NULL, xml = NULL, text = ""))
  }

  switch(
    as,
    html = rvest::read_html(httr2::resp_body_string(resp)),
    xml  = xml2::read_xml(httr2::resp_body_string(resp)),
    text = httr2::resp_body_string(resp)
  )
}
```

`default_user_agent()` returns `"poddr/<package version> (+https://github.com/jemus42/poddr)"`. Honest and contactable; mirrors tRakt.

## Package options (set in `.onLoad`)

| Option | Default | Purpose |
|---|---|---|
| `poddr_user_agent` | `default_user_agent()` | Override UA if needed. |
| `poddr_throttle_rate` | `1/2` (one request per 2 s per host) | Per-host throttle bucket. |
| `poddr_cache_dir` | `tools::R_user_dir("poddr", "cache")` | httr2 cache directory. |
| `poddr_cache_max_age` | `7 * 86400` | One week. |
| `poddr_cache_max_size` | `100 * 1024^2` | 100 MB. |

Defaults match tRakt's cache policy exactly.

## File-by-file migration

| File | Change |
|---|---|
| `R/zzz.R` | Drop `polite_read_delim`. `.onLoad()` sets the five package options above. `podcast_urls` list retained. |
| `R/utils-http.R` *(new)* | `poddr_get()`, `default_user_agent()`, `assert_scrapable(url)` (wraps `robotstxt::paths_allowed()` with informative error). |
| `R/atp.R` | `atp_get_episodes()`: replace `polite::bow()`/`scrape()` with `poddr_get(url, "html", query = list(page = n))`. Call `assert_scrapable()` once on `podcast_urls$atp$base`. Drop the inline `cache_podcast_data()` call. `cache` arg = HTTP cache only. `atp_parse_page()` unchanged (HTML in, tibble out). |
| `R/relay.R` | `relay_get_shows()` and `relay_parse_feed()` use `poddr_get(url, "html")` and `poddr_get(url, "xml")` respectively. The current `polite::scrape(accept = "html", content = "text/html; charset=utf-8")` workaround for RSS goes away. `relay_get_episodes()`: drop disk side effect. Robots check once at `relay_get_shows()` entry. |
| `R/incomparable.R` | `incomparable_get_shows`/`_parse_archive`/`_get_subcategories` → `poddr_get(url, "html")`. `incomparable_parse_stats` → `poddr_get(url, "text") |> readr::read_delim(file = I(_), …)`. `incomparable_get_episodes()`: drop disk side effect. Robots check once per host at the orchestrators. |
| `R/utils-caching.R` | `cache_podcast_data(dir = here::here("data_cache"))` replaces the hardcoded relative path. `update_cached_data(dir = …)` propagates and now calls `cache_podcast_data()` explicitly after each orchestrator (current behaviour, just no longer hidden). |
| `R/utils.R` | Unchanged. |
| `DESCRIPTION` | Imports: drop `polite`, `memoise`; add `httr2`, `xml2`, `robotstxt`, `here`. Suggests: add `vcr`. Bump version to 0.3.0. |
| `NAMESPACE` | Regenerated; `poddr_get` stays internal. |
| `tests/testthat/` | Existing parsing tests stay. New synthetic fixtures for `relay_parse_feed` (XML), `incomparable_parse_archive` (HTML), `incomparable_parse_stats` (semicolon text). New cassette-backed tests per section "Test strategy". |
| `Makefile` *(new)* | Trimmed copy of tRakt's: `format`, `doc`, `check`, `test`, `coverage`, `build`, `install`, `site`, `release`, `clean`. |
| `.github/workflows/get-data.yaml` | Add `actions/cache@v4` step for `~/.cache/R/poddr` keyed on `${{ runner.os }}-poddr-http-${{ hashFiles('.github/workflows/get-data.yaml') }}`. Replace the three separate `library(poddr); …()` blocks with a single `Rscript -e "poddr::update_cached_data()"` invocation — `update_cached_data()` is the deliberate fetch + write entry point for this workflow. |
| `.github/workflows/R-CMD-check.yaml` | Unchanged. |
| `.github/workflows/pkgdown.yaml` | Unchanged. |
| `README.Rmd` / `README.md` | Refreshed: drop "December 2020" + "to not bother the webserver" framing, show new pure-orchestrator + explicit `cache_podcast_data()` flow. Re-knit. |
| `attic/`, `fiddle.R`, `README_cache/` | Deleted (already `.Rbuildignore`d). |
| `NEWS.md` | New `# poddr 0.3.0` section (see "Breaking changes" below). |

## Test strategy

Two layers, deliberately complementary.

### Synthetic fixture tests

Hand-rolled tiny HTML / XML / text inputs in `tests/testthat/`. Exact-value assertions are appropriate here because we author every value.

Coverage to add or retain:
- `atp_parse_page` — existing fixture, retained.
- `parse_duration`, `label_n`, `gather_people` — existing.
- `relay_parse_feed` — new XML fixture (channel + 2 items). To keep the parser testable offline, factor out a small private `parse_relay_feed_xml(xml)` from the public `relay_parse_feed(url)` and test the inner function against the fixture.
- `incomparable_parse_archive` — same approach: extract `parse_incomparable_archive_html(html)`, test against an HTML fixture.
- `incomparable_parse_stats` — same: `parse_incomparable_stats_text(text)`, test against a fake stats.txt line.

Run on every `R CMD check`. Offline. No flakiness.

### vcr cassette tests

Record real upstream responses once; replay until the cassette ages out.

```
tests/testthat/
├── helper-vcr.R
├── _vcr/
│   ├── atp_get_episodes-page1.yml
│   ├── relay_get_shows.yml
│   ├── relay_parse_feed-connected.yml
│   ├── relay_get_episodes-one_show.yml
│   ├── incomparable_get_shows.yml
│   ├── incomparable_parse_archive-gameshow.yml
│   ├── incomparable_parse_stats-salvage.yml
│   └── incomparable_get_episodes-one_show.yml
├── test-atp-recorded.R
├── test-relay-recorded.R
└── test-incomparable-recorded.R
```

**Re-record interval:** 30 days (`re_record_interval = 30L * 86400L`), matching tRakt.

**httr2 cache vs vcr conflict:** the httr2 cache dir would shortcut requests before they reach vcr's recorder. Resolved per-test by `withr::local_options(poddr_cache_dir = withr::local_tempdir())` in a vcr helper, so the production default stays exercised but tests never share cache state across runs or with the user's real cache.

**Cassette size budget:** under ~500 KB total. Each orchestrator cassette is the minimum that yields a non-empty result (`page_limit = 1`, single show selected, single retired show).

**What cassette assertions check (content-agnostic by design):**

- Result is a tibble of expected class.
- `nrow(out) > 0`.
- Column names match the documented schema.
- Date columns are `Date`, durations are `hms`, numbers parse cleanly, etc.
- No `NA`s in load-bearing columns (`date`, `number`, `title`).
- Static fields (e.g. `network == "ATP"`, `network == "The Incomparable"`) match.

Plus one schema snapshot per orchestrator using a small `glimpse_schema()` helper (`tibble(col, class)`) — survives re-records because it captures structure, not values.

**What cassette assertions do NOT check:**

- Specific episode titles, dates, hosts, or any value that will shift on the next re-record.

This boundary is deliberate. The cassette layer catches:
- Upstream HTML restructure (next re-record yields a cassette that fails schema/parseability assertions).
- Our regressions in parser or orchestrator code (fails on replay against an unchanged cassette).
- Schema drift in our own code (fails `expect_named()` and snapshot).

Content currency is the nightly Action's job, not the test suite's.

## GH Action cache persistence

`get-data.yaml` gains, before the first poddr call:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/R/poddr
    key: ${{ runner.os }}-poddr-http-${{ hashFiles('.github/workflows/get-data.yaml') }}
    restore-keys: |
      ${{ runner.os }}-poddr-http-
```

Effect: scheduled runs reuse the cache built by the previous run. Pages that haven't changed upstream return 304 and don't count toward upstream load. The 7-day `max_age` in `req_cache()` ensures stale entries get evicted at the package layer regardless of Action cache lifetime.

## Breaking changes (NEWS 0.3.0)

- `atp_get_episodes()`, `relay_get_episodes()`, `incomparable_get_episodes()` no longer write RDS/CSV files as a side effect of `cache = TRUE`. The `cache` argument now controls the httr2 HTTP cache only. Callers that need disk artefacts must invoke `cache_podcast_data()` explicitly, or use `update_cached_data()` which bundles the fetch + write.
- HTTP layer migrated from `polite` to `httr2`; behaviour-visible changes: faster throttle default (1 req / 2 s per host, was 5 s globally via polite), cross-session HTTP cache, retries on transient failures.
- `cache_podcast_data(dir = …)` now defaults to `here::here("data_cache")` instead of the literal relative path `"data_cache"`. GH Action workflow runs in repo root so behaviour is preserved; other callers benefit from explicit, working-directory-independent path resolution.
- New package options: `poddr_user_agent`, `poddr_throttle_rate`, `poddr_cache_dir`, `poddr_cache_max_age`, `poddr_cache_max_size`.
- Removed `polite` and `memoise` from `Imports`. Added `httr2`, `xml2`, `robotstxt`, `here`.

## Acceptance criteria

The migration is complete when:

1. `R CMD check` is **0 errors / 0 warnings / 0 notes** on macOS, Windows, and the Ubuntu matrix.
2. `devtools::test()` passes — synthetic fixture tests + cassette tests in replay mode.
3. Fresh cassette recording (delete `_vcr/`, set `VCR_TURN_OFF = "false"`, run with network) produces cassettes that replay cleanly and that all cassette assertions pass against.
4. A targeted local run of `update_cached_data()` produces RDS/CSV files in `data_cache/` matching the schema produced by 0.2.7 (column names, types, row count within expected drift).
5. A second consecutive `update_cached_data()` run with no `data_cache/` deletion shows >50% of requests served from cache (verify via `httr2::with_verbosity()` or by inspecting `~/.cache/R/poddr/` mtimes).
6. The `get-data.yaml` workflow runs green on `workflow_dispatch`.
7. Cleanups landed: README rebuilt, Makefile present, `attic/` / `fiddle.R` / `README_cache/` deleted.

## Deferred (post-migration TODO pile)

- Recover Incomparable mothership subcategories (Book Club, Old Movie Club, …) lost in the June 2022 site redesign.
