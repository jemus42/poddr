vcr::vcr_configure(
  dir = vcr::vcr_test_path("_vcr"),
  warn_on_empty_cassette = FALSE
)
vcr::check_cassette_names()

# Per-test override of the httr2 cache so cassettes record the
# real upstream response instead of a 304 short-circuit, and so
# the user's real ~/.cache/R/poddr is never touched in tests.
local_isolated_cache <- function(envir = parent.frame()) {
  withr::local_options(
    poddr_cache_dir = withr::local_tempdir(.local_envir = envir),
    .local_envir = envir
  )
}

# robotstxt caches robots.txt fetches in-process. vcr cassettes only record
# requests they observe, so when a cassette is replayed in a fresh session
# the robotstxt lookup needs to be in the cassette — otherwise the cached
# in-process value short-circuits the call and vcr's recording is incomplete.
#
# robotstxt does not export a public cache-clearing function; reach into the
# internal `rt_cache` environment. This is a deliberate, documented use of `:::`.
local_clear_robotstxt_cache <- function(envir = parent.frame()) {
  cache_env <- robotstxt:::rt_cache
  rm(list = ls(envir = cache_env), envir = cache_env)
  withr::defer(
    rm(list = ls(envir = cache_env), envir = cache_env),
    envir = envir
  )
  invisible()
}

# Schema printer used by cassette-backed tests — captures column
# names and classes only, so the snapshot survives cassette
# re-records.
glimpse_schema <- function(x) {
  tibble::tibble(
    col = names(x),
    class = purrr::map_chr(x, \(c) class(c)[1])
  )
}
