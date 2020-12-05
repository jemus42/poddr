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
#' atp_new <- atp_get_episodes(page_limit = 1)
#' cache_podcast_data(atp_new, csv = FALSE)
#' }
cache_podcast_data <- function(x, dir = "data", filename = NULL, csv = TRUE) {
  # Early return just in case the data is wrong and empty
  if (nrow(x) == 0) return(NULL)

  # Get the filename from the data name
  if (is.null(filename)) {
    filename <- deparse(substitute(x))
  }

  path_rds <- paste0(file.path(dir, filename), ".rds")
  saveRDS(x, path_rds)

  if (csv) {
    path_csv <- paste0(file.path(dir, filename), ".csv")
    readr::write_delim(x, path_csv, delim = ";")
  }
}
