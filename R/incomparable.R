#' Get The Incomparable shows
#'
#' @param url Show index URL: `"https://www.theincomparable.com/shows/"`.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_get_shows()
#' }
incomparable_get_shows <- function(url = "https://www.theincomparable.com/shows/") {
  show_index <- read_html(url)

  shows <- show_index %>%
    html_nodes("h3 a") %>%
    html_text()

  show_partials <- show_index %>%
    html_nodes("h3 a") %>%
    html_attr("href") %>%
    stringr::str_replace_all("\\/", "")

  tibble(
    show = shows,
    partial = show_partials,
    stats_url =  glue::glue("https://www.theincomparable.com/{partial}/stats.txt"),
    archive_url = glue::glue("https://www.theincomparable.com/{partial}/archive/")
  )
}
