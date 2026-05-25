# poddr 0.3.2

## New features

* `incomparable_get_episodes()` now fetches each per-episode page for
  episodes that appear in `stats.txt` but aren't listed on the show's
  archive page yet (the archive renders on a slower cadence than
  `stats.txt` updates, so the newest episode is typically missing from
  the archive for hours to weeks). This recovers `summary` for those
  episodes from the per-episode `og:description` meta tag. `topic`
  remains `NA` for newest-episode gaps unless the individual page
  happens to populate `.episode-subtitle`.

* New exported helper `incomparable_parse_episode(episode_url, cache)`
  returns a one-row tibble (`summary`, `topic`) for a given episode
  URL — exposed for direct use; called automatically by the
  orchestrator's gap-fill.

* The gap-fill is lazy: zero extra HTTP requests when the archive is
  current. Worst case scales with the gap size (typically 0–1 episodes
  per show per scheduled run).

# poddr 0.3.1

## Bug fixes

* `incomparable_get_episodes()` no longer returns `NA` for `year`,
  `month`, `weekday`, and `network` on episodes that appear in
  `stats.txt` but haven't been added to the archive page yet (the
  Incomparable site renders the two surfaces independently and
  `stats.txt` typically leads by hours-to-weeks for new episodes).
  These four columns are now derived from the canonical
  `stats.txt` date / a constant after the join, so any row that
  has a `date` also has `year`, `month`, `weekday`, and `network`.
  `category`, `topic`, and `summary` remain `NA` for episodes the
  archive hasn't listed yet — those fields genuinely have no source
  to recover them from. Reported by the
  [podcasts.jemu.name](https://github.com/jemus42/podcasts.jemu.name)
  consumer (2026-05-25).

* Same fix also protects against the historical join-key mismatch
  case where `stats.txt` and the archive page disagree on an episode
  number (e.g. legacy sub-indexed entries like `123a` / `123b`):
  derived columns are populated from the surviving `date` regardless
  of whether the archive row matched.

# poddr 0.3.0

## Breaking changes

* HTTP layer migrated from `polite` to `httr2`. The `cache` argument on
  `atp_get_episodes()`, `relay_get_episodes()`, `relay_get_shows()`,
  `incomparable_get_episodes()`, `incomparable_get_shows()`,
  `incomparable_parse_archive()`, `incomparable_parse_stats()`,
  `incomparable_get_subcategories()`, and `relay_parse_feed()` now
  controls the httr2 HTTP cache *only*. None of these functions write
  RDS/CSV files as a side effect any more.

* Callers that need disk artefacts must invoke `cache_podcast_data()`
  explicitly, or use `update_cached_data()` which bundles fetch + write.

* `cache_podcast_data(dir = …)` defaults to `here::here("data_cache")`
  instead of the literal relative path `"data_cache"`.

## New features

* New internal request helper centralises user-agent, per-host
  throttling (default 1 req / 2 s), transient retries (429/5xx), and
  cross-session HTTP caching via `tools::R_user_dir("poddr", "cache")`.

* New package options for tuning the request layer:
  `poddr_user_agent`, `poddr_throttle_rate`, `poddr_cache_dir`,
  `poddr_cache_max_age`, `poddr_cache_max_size`.

* `robotstxt::paths_allowed()` is now checked once per host at
  orchestrator entry (i.e. inside `*_get_shows()` and effectively by
  the per-show parsers fired from `*_get_episodes()`).

## Testing

* Added vcr cassettes for the network-touching functions, covering
  `atp_get_episodes()`, `relay_get_shows()`, `relay_parse_feed()`,
  `relay_get_episodes()`, `incomparable_get_shows()`,
  `incomparable_parse_archive()`, `incomparable_parse_stats()`, and
  `incomparable_get_episodes()`. Cassettes re-record after 30 days.

* Parser logic for relay and Incomparable was factored into inner
  private functions taking already-parsed XML / HTML / text, so the
  parsing layer is tested offline against synthetic fixtures.

## Dependencies

* Removed: `polite`, `memoise`.
* Added: `httr2`, `xml2`, `robotstxt`, `here`.
* Suggests: `vcr`, `withr`.

# poddr 0.2.7

* Maintenance release.
* `incomparable_parse_stats()` now fetches `stats.txt` through
  `polite::politely()` so that requests respect `robots.txt` and a
  per-host delay, matching the rest of the scrapers.
* Switched progress bars from the `progress` package to `cli`, dropping
  one direct dependency.
* Replaced superseded `purrr::map_dfr()`/`pmap_dfr()` with
  `purrr::map()`/`pmap()` + `purrr::list_rbind()`.
* `relay_get_shows()` now caches to `relay_shows.rds` instead of
  overwriting the episode cache.
* Fixed deprecation warnings from `tidyselect` in `gather_people()`.
* Added `testthat` tests for `parse_duration()`, `label_n()`,
  `gather_people()`, and `atp_parse_page()`.
* Declared `R (>= 4.1.0)` in `DESCRIPTION` to match use of `|>` and
  `\(x)`.

# poddr 0.2.6

* [ATP] Append (redundant) `Show` and `Network` column equal `"ATP"` for consistency with other podcasts.

# poddr 0.2.5

* [ATP] Fix error in page enumeration due to unnumbered member special episodes.
* [Incomparable] Fix date parsing regex failing when topics included 4-digit number

# poddr 0.2.4

* [ATP] Ignore members-only posts rather than including them with missing data.

# poddr 0.2.3

* [Relay FM] Fix incorrect host parsing, leading to all hosts being displayed as "Relay FM".

# poddr 0.2.2

*  [Incomparable] Add safety check in case an archive page returns `500` and is not parseable.
*  [Incomparable] Slightly improve date parsing from archive pages. 

# poddr 0.2.1

* [Incomparable] Fix missing subcategory handling for the mothership, game show and some others.

# poddr 0.2.0

* [Incomparable] Update for the new [Incomparable website](https://www.theincomparable.com/) in June 2022.  
  * Some information like sub-categories for the mothership (Book Club, Old Movie Club etc.) are not yet recovered though.

# poddr 0.1.1

* [Incomparable] Fix bug where empty show archive pages broke the whole episode gathering.
  * Yields message such as `Empty archive page for Doctor Who Flashcast at https://www.theincomparable.com/dwf/archive/`

# poddr 0.1.0

* Add `pkgdown` site.
* Pass R CMD check.
* Add functions to get episodes from The Incomparable, Relay FM and ATP.
* Added a `NEWS.md` file to track changes to the package.
