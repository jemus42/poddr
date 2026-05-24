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

# Schema printer used by cassette-backed tests — captures column
# names and classes only, so the snapshot survives cassette
# re-records.
glimpse_schema <- function(x) {
  tibble::tibble(
    col = names(x),
    class = purrr::map_chr(x, \(c) class(c)[1])
  )
}
