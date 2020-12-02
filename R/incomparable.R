#' Get The Incomparable shows
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_get_shows()
#' }
incomparable_get_shows <- function() {
  base_url <- "https://www.theincomparable.com"
  show_index <- polite::bow(glue::glue("{base_url}/shows")) %>%
    polite::scrape()

  shows <- show_index %>%
    html_nodes("h3 a") %>%
    html_text()

  show_partials <- show_index %>%
    html_nodes("h3 a") %>%
    rvest::html_attr("href") %>%
    stringr::str_replace_all("\\/", "")

  tibble(
    show = shows,
    # partial = show_partials,
    stats_url =  glue::glue("{base_url}/{show_partials}/stats.txt"),
    archive_url = glue::glue("{base_url}/{show_partials}/archive/")
  )
}

#' Parse a show's archive page on The Incomparable website
#'
#' @param archive_url E.g. `"https://www.theincomparable.com/theincomparable/archive/"`.
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' archive_url <- "https://www.theincomparable.com/theincomparable/archive/"
#' incomparable <- incomparable_parse_archive(archive_url)
#' }
incomparable_parse_archive <- function(archive_url) {

  archive_parsed <- polite::bow(archive_url) %>%
    polite::scrape()

  # One element per entry, iterate over this to ensure
  # each episode and respective elements can be matched correctly
  # for things like topics and categories where not every episode
  # has such an element
  entries <- archive_parsed %>%
    html_nodes(css = "#entry")

  purrr::map_dfr(entries, ~{
    epnums <- .x %>%
      html_nodes(css = ".episode-number") %>%
      html_text() %>%
      as.character()

    # Comic book club test case
    # if (epnums == "526") browser()
    # Non-categorized test case
    # if (epnums == "541") browser()

    summaries <- .x %>%
      html_nodes(css = ".episode-description") %>%
      html_text() %>%
      stringr::str_replace_all("^(\\W)*", "") %>%
      stringr::str_replace_all("\\W*$", "")

    titles <- .x %>%
      html_nodes(css = ".entry-title a") %>%
      html_text()

    postdate <- .x %>%
      html_nodes(".postdate:nth-child(1)") %>%
      html_text()

    date <- postdate[[1]] %>%
      stringr::str_trim(side = "both") %>%
      stringr::str_extract("^.*\\n") %>%
      stringr::str_trim(side = "both") %>%
      lubridate::mdy()

    # Handling of duration is wonly and WIP
    # also there are no seconds as of 2020-12-02
    # but maybe Jason adds those soonish
    duration <- postdate[[2]]

    duration <- list(
      hours = stringr::str_extract(duration, pattern = "\\d+(?=(\\shours))"),
      minutes = stringr::str_extract(duration, pattern = "\\d+(?=(\\sminutes))"),
      seconds = stringr::str_extract(duration, pattern = "\\d+(?=(\\sseconds))")
    )

    duration <- purrr::map(duration, ~{
      if (is.na(.x)) return(0)
      as.numeric(.x)
    })

    duration <- hms::hms(
      seconds = duration$seconds,
      minutes = duration$minutes,
      hours = duration$hours
    )

    host <- .x %>%
      rvest::html_nodes(".postdate+ a") %>%
      html_text()

    guest <- .x %>%
      html_nodes("a+ a") %>%
      html_text() %>%
      paste(collapse = ";")

    categories <- .x %>%
      html_nodes(".subcast img") %>%
      rvest::html_attr("alt")

    if (identical(categories, character(0))) {
      categories <- NA
    }

    topics <- .x %>%
      html_nodes(".postdate+ .postdate") %>%
      html_text() %>%
      stringr::str_extract("•.*") %>%
      stringr::str_replace_all("•", "") %>%
      stringr::str_trim("both")

    if (identical(topics, character(0))) {
      topics <- NA
    }

    tibble::tibble(
      number = epnums,
      title = titles,
      duration = duration,
      date = date,
      year = lubridate::year(date),
      month = lubridate::month(date, abbr = FALSE, label = TRUE),
      weekday = lubridate::wday(date, abbr = FALSE, label = TRUE),
      host = host,
      guest = guest,
      category = categories,
      topic = topics,
      summary = summaries,
      network = "The Incomparable"
    )
  })

}

#' WIP Parse The Incomparable stats.txt files
#'
#' @param stats_url URL to the `stats.txt`.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' stats_url <- "https://www.theincomparable.com/theincomparable/stats.txt"
#' incomparable_parse_stats(stats_url)
#' }
incomparable_parse_stats <- function(stats_url) {

  # stats_url <- "https://www.theincomparable.com/theincomparable/stats.txt"

  readr::read_delim(
    stats_url, delim = ";", quote = "",
    col_names = c(
      "number", "date", "duration", "title", "host", "guest"
    ),
    col_types = "cccccc",
    trim_ws = TRUE
  )
#
#   showstats <- readr::read_lines(stats_url) %>%
#     stringr::str_c(";") %>%
#     paste0(collapse = "\n") %>%
#     stringr::str_c("\n") %>% # Append extra newline at EOF to prevent failure for single-row files
#     readr::read_delim(
#       file = ., delim = ";", quote = "",
#       col_names = FALSE, col_types = cols(X1 = col_character(), X3 = col_character())
#     )
}


#' Get all The Incomparable shows
#'
#' @param incomparable_shows Dataset of shows with title and URLs
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable <- incomparable_get_episodes(incomparable_get_shows())
#' }
incomparable_get_episodes <- function(incomparable_shows) {
  pb <- progress::progress_bar$new(
    format = "Getting :show [:bar] :current/:total (:percent) ETA: :eta",
    total = nrow(incomparable_shows)
  )

  incomparable_episodes <- purrr::pmap_dfr(incomparable_shows, ~{
    pb$tick(tokens = list(show = ..1))

    incomparable_parse_archive(..3) %>%
      dplyr::mutate(
        show = ..1
      ) %>%
      dplyr::relocate(.data$show)
  })
}
