#' Cache episode data
#'
#' @param x Object to cache
#' @param dir Directory to save data to
#' @param filename Optional filename, if not specified the name of `x`.
#' @param csv If `TRUE`, also saves a CSV file with the same base name.
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' if (FALSE) cache_podcast_data()
#' }
cache_podcast_data <- function(x, dir = "data", filename = NULL, csv = TRUE) {
  if (is.null(filename)) {
    filename <- deparse(substitute(x))
  }

  path_rds <- paste0(file.path(dir, filename), ".rds")

  # cliapp::cli_alert_success("Saving {filename} to {path_rds}")
  saveRDS(x, path_rds)

  if (csv) {
    path_csv <- paste0(file.path(dir, filename), ".csv")
    cliapp::cli_alert_success("Saving {filename} to {path_csv}")
    readr::write_delim(x, path_csv, delim = ";")
  }
}
