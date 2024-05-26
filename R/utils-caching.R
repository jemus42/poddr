#' Cache episode data
#'
#' @param x Object to cache.
#' @param dir `["data_cache"]` Directory to save data to.
#' @param filename Optional filename sans extension, if not specified the name of `x` is used.
#' @param csv If `TRUE` (default), also saves a CSV file with the same base name.
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' atp_new <- atp_get_episodes(page_limit = 1)
#' cache_podcast_data(atp_new, csv = FALSE)
#' }
cache_podcast_data <- function(x, dir = "data_cache", filename = NULL, csv = TRUE) {
  # Early return just in case the data is wrong and empty
  if (nrow(x) == 0) return(NULL)

  # Get the filename from the data name
  if (is.null(filename)) {
    filename <- deparse(substitute(x))
  }

  path_rds <- fs::path(dir, filename, ext = "rds")
  saveRDS(x, path_rds)

  if (csv) {
    path_csv <- fs::path(dir, filename, ext = "csv")
    readr::write_delim(x, path_csv, delim = ";")
  }
}

#' Update and cache data locally
#'
#' @param dir `["data_cache"]` Directory path to save cached data to.
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' update_cached_data()
#' }
update_cached_data <- function(dir = "data_cache") {
  atp <- atp_get_episodes()
  cache_podcast_data(atp, csv = FALSE, dir = dir)

  relay_shows <- relay_get_shows()
  relay_episodes <- relay_get_episodes(relay_shows)
  cache_podcast_data(relay_shows, dir = dir)
  cache_podcast_data(relay_episodes, dir = dir)

  incomparable_shows <- incomparable_get_shows()
  incomparable_episodes <- incomparable_get_episodes(incomparable_shows)

  cache_podcast_data(incomparable_shows, dir = dir)
  cache_podcast_data(incomparable_episodes, dir = dir)
}
