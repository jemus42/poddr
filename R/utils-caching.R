#' Cache episode data to disk
#'
#' Writes a tibble to RDS (and optionally CSV) in `dir`. Default `dir` is
#' resolved with [here::here()] so the path is anchored to the project
#' root rather than the current working directory.
#'
#' @param x Object to cache.
#' @param dir Directory to save data to. Default: `here::here("data_cache")`.
#' @param filename Optional filename sans extension; defaults to `deparse(substitute(x))`.
#' @param csv If `TRUE` (default), also saves a CSV file with the same base name.
#'
#' @return Invisibly returns the path(s) written, or `NULL` for empty input.
#' @export
#'
#' @examples
#' \dontrun{
#' atp <- atp_get_episodes(page_limit = 1)
#' cache_podcast_data(atp, csv = FALSE)
#' }
cache_podcast_data <- function(
  x,
  dir = here::here("data_cache"),
  filename = NULL,
  csv = TRUE
) {
  if (nrow(x) == 0) {
    return(NULL)
  }

  if (is.null(filename)) {
    filename <- deparse(substitute(x))
  }

  fs::dir_create(dir)

  path_rds <- fs::path(dir, filename, ext = "rds")
  cli::cli_alert_info("Caching {.val {filename}} to {.file {path_rds}}")
  saveRDS(x, path_rds)
  paths <- path_rds

  if (csv) {
    path_csv <- fs::path(dir, filename, ext = "csv")
    cli::cli_alert_info("Caching {.val {filename}} to {.file {path_csv}}")
    readr::write_delim(x, path_csv, delim = ";")
    paths <- c(paths, path_csv)
  }

  invisible(paths)
}

#' Fetch all sources and cache results to disk
#'
#' Convenience entry point used by the scheduled GitHub Action. Calls each
#' fetch orchestrator and writes its output via [cache_podcast_data()].
#' Targets users typically don't want this — call the individual
#' `*_get_episodes()` functions instead.
#'
#' @param dir Directory to save data to. Default: `here::here("data_cache")`.
#' @return Invisibly returns the list of paths written.
#' @export
#'
#' @examples
#' \dontrun{
#' update_cached_data()
#' }
update_cached_data <- function(dir = here::here("data_cache")) {
  atp <- atp_get_episodes()
  paths_atp <- cache_podcast_data(atp, dir = dir, filename = "atp", csv = FALSE)

  relay_shows <- relay_get_shows()
  paths_relay_shows <- cache_podcast_data(
    relay_shows,
    dir = dir,
    filename = "relay_shows"
  )
  relay_episodes <- relay_get_episodes(relay_shows)
  paths_relay_episodes <- cache_podcast_data(
    relay_episodes,
    dir = dir,
    filename = "relay_episodes"
  )

  incomparable_shows <- incomparable_get_shows()
  paths_inc_shows <- cache_podcast_data(
    incomparable_shows,
    dir = dir,
    filename = "incomparable_shows"
  )
  incomparable_episodes <- incomparable_get_episodes(incomparable_shows)
  paths_inc_episodes <- cache_podcast_data(
    incomparable_episodes,
    dir = dir,
    filename = "incomparable_episodes"
  )

  invisible(c(
    paths_atp,
    paths_relay_shows,
    paths_relay_episodes,
    paths_inc_shows,
    paths_inc_episodes
  ))
}
