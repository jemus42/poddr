#' Retrieve all The Incomparable shows
#'
#' Parses the show overview page and returns a tibble of show names
#' with corresponding URLs, which in turn can then be passed to
#' `incomparable_parse_archive()` and `incomparable_parse_stats()` individually.
#'
#' @param cache (`logical(1)`) Set to `FALSE` to disable caching.
#' @return A tibble with following columns:
#' ```
#' Columns: 4
#' $ show        <chr>
#' $ stats_url   <glue>
#' $ archive_url <glue>
#' $ status      <chr>
#' ```
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_get_shows()
#' }
incomparable_get_shows <- function(cache = TRUE) {
  base_url <- podcast_urls$incomparable$base
  show_index <- polite::bow(podcast_urls$incomparable$shows) |>
    polite::scrape()

  shows <- show_index |>
    rvest::html_nodes("#recent h5 a") |>
    rvest::html_text()

  show_partials <- show_index |>
    rvest::html_nodes("#recent h5 a") |>
    rvest::html_attr("href") |>
    stringr::str_replace_all("\\/", "")

  shows_active <- tibble(
    show = shows,
    # partial = show_partials,
    stats_url = glue::glue("{base_url}/{show_partials}/stats.txt"),
    archive_url = glue::glue("{base_url}/{show_partials}/archive/"),
    status = "active"
  )

  shows <- show_index |>
    rvest::html_nodes("#retired h5 a") |>
    rvest::html_text()

  show_partials <- show_index |>
    rvest::html_nodes("#retired h5 a") |>
    rvest::html_attr("href") |>
    stringr::str_replace_all("\\/", "")

  shows_retired <- tibble(
    show = shows,
    # partial = show_partials,
    stats_url = glue::glue("{base_url}/{show_partials}/stats.txt"),
    archive_url = glue::glue("{base_url}/{show_partials}/archive/"),
    status = "retired"
  )

  shows <- dplyr::bind_rows(shows_active, shows_retired)

  checkmate::assert_data_frame(shows, min.rows = 15, ncols = 4)

  if (cache) {
    cache_podcast_data(shows, filename = "incomparable_shows")
  }

  shows
}

#' Parse a show's archive page on The Incomparable website
#'
#' Retrieves all episodes for one or more shows passed as a tibble.
#' The archive page *does not* include full duration information, as it is
#' limited to hours and minutes. Use `incomparable_parse_stats()` for
#' accurate episode durations.
#' @param archive_url E.g.
#' `"https://www.theincomparable.com/theincomparable/archive/"`.
#'
#' @return A tibble, with following format:
#' ```
#' #> dplyr::glimpse(incomparable_parse_archive(archive_url))
#'  Columns: 12
#'  $ number   <chr>
#'  $ title    <chr>
#'  $ date     <date>
#'  $ year     <dbl>
#'  $ month    <ord>
#'  $ weekday  <ord>
#'  $ host     <chr>
#'  $ guest    <chr>
#'  $ category <chr>
#'  $ topic    <chr>
#'  $ summary  <chr>
#'  $ network  <chr>
#' ```
#' @export
#'
#' @examples
#' \dontrun{
#' archive_url <- "https://www.theincomparable.com/gameshow/archive/"
#' incomparable_parse_archive(archive_url)
#' }
incomparable_parse_archive <- function(archive_url) {
  archive_parsed <- polite::bow(archive_url) |>
    polite::scrape()

  # Catch 500 error for archive pages, e.g. https://www.theincomparable.com/pod4ham/
  # 2022-07-31
  if (is.null(archive_parsed)) {
    return(tibble())
  }

  # One element per entry, iterate over this to ensure
  # each episode and respective elements can be matched correctly
  # for things like topics and categories where not every episode
  # has such an element
  entries <- archive_parsed |>
    rvest::html_nodes(css = ".episode-list li")

  # Subcategory detection
  subcat_header <- archive_parsed |>
    rvest::html_nodes("h6") |>
    rvest::html_text()

  has_categories <- identical(subcat_header, "Subcategories")

  purrr::map(entries, \(x) {
    # Treat episode numbers as character in case of letter suffixes
    epnums <- x |>
      rvest::html_nodes(css = ".ep-num") |>
      rvest::html_text() |>
      as.character()

    summaries <- x |>
      rvest::html_nodes(css = "p") |>
      rvest::html_text() |>
      stringr::str_c(collapse = "")

    titles <- x |>
      rvest::html_nodes(css = "h5 a") |>
      rvest::html_text() |>
      stringr::str_remove_all("^\\d+\\w?[\\n\\s\\t]*")

    date <- x |>
      rvest::html_nodes(".episode-date") |>
      rvest::html_text() |>
      stringr::str_extract("^[A-Za-z0-9\\s,]+?,\\s+\\d{4}") |>
      lubridate::mdy()

    host <- x |>
      rvest::html_nodes(".hosts a:nth-child(1)") |>
      rvest::html_text()

    guest <- x |>
      rvest::html_nodes("a+ a") |>
      rvest::html_text() |>
      paste(collapse = ";")

    categories <- NA_character_
    if (has_categories) {
      categories <- x |>
        rvest::html_nodes("img") |>
        rvest::html_attr("alt") |>
        stringr::str_remove_all("(^.*\\s-\\s)|(\\scover\\sart)")
    }

    topics <- x |>
      rvest::html_nodes(".episode-subtitle") |>
      rvest::html_text()

    if (identical(topics, character(0))) {
      topics <- NA_character_
    }

    tibble(
      number = epnums,
      title = titles,
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
  }) |>
    purrr::list_rbind()
}

#' Extract subcategory index for given show
#'
#' Not actively used in other functions but could come in handy.
#'
#' @inheritParams incomparable_parse_archive
#'
#' @return A tibble with subcategory links `link` and category name `category`
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_get_subcategories("https://www.theincomparable.com/gameshow/archive/")
#' }
incomparable_get_subcategories <- function(
  archive_url = "https://www.theincomparable.com/gameshow/archive/"
) {
  show_index <- polite::bow(archive_url) |>
    polite::scrape()

  show_index |>
    rvest::html_nodes("#recent aside a") |>
    purrr::map(\(x) {
      link <- paste0(
        "https://www.theincomparable.com",
        rvest::html_attr(x, "href")
      )
      tibble(link = link, category = rvest::html_text(x))
    }) |>
    purrr::list_rbind()
}

#' Parse The Incomparable stats.txt files
#'
#' The `stats.txt` files have a slightly different format, especially the
#' host/guest information may differ from what is returned by
#' `incomparable_parse_archive()`, which implicitly assumes the first person
#' mentioned to be the host of the episode. However, this data source
#' does not include podcast subcategories (e.g. "Old Movie Club") or
#' topic information, which is only available on the archive page.
#' @param stats_url URL to the `stats.txt`, e.g.
#' `"https://www.theincomparable.com/salvage/stats.txt"`.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_parse_stats("https://www.theincomparable.com/salvage/stats.txt")
#' }
incomparable_parse_stats <- function(stats_url) {
  polite_read_delim(
    stats_url,
    delim = ";",
    quote = "",
    col_names = c(
      "number",
      "date",
      "duration",
      "title",
      "host",
      "guest"
    ),
    col_types = "cccccc",
    trim_ws = TRUE
  ) |>
    dplyr::mutate(
      duration = parse_duration(.data$duration),
      date = lubridate::dmy(.data$date)
    ) |>
    dplyr::mutate(dplyr::across(
      c("host", "guest"),
      ~ {
        stringr::str_replace_all(.x, "\\s*,\\s*", ";")
      }
    ))
}

#' Retrieve all episodes for The Incomparable shows
#'
#' This combines `incomparable_parse_stats()` and `incomparable_parse_archive()`
#' to retrieve full episode information including host/guest, durations
#' including seconds, podcast subcategories and topics.
#' Use sparingly to limit unnecessarily hammering the poor webserver!
#' @param incomparable_shows Dataset of shows with title and URLs as returned by
#' `incomparable_get_shows()`.
#' @inheritParams incomparable_get_shows
#'
#' @return A tibble with one row per episode.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_shows <- incomparable_get_shows()
#' incomparable <- incomparable_get_episodes(incomparable_shows)
#' }
incomparable_get_episodes <- function(incomparable_shows, cache = TRUE) {
  cli::cli_progress_bar(
    "Getting episodes",
    total = nrow(incomparable_shows),
    format = "{cli::pb_spin} {cli::pb_current}/{cli::pb_total} {show}"
  )

  episodes <- purrr::pmap(
    incomparable_shows,
    \(show, stats_url, archive_url, ...) {
      cli::cli_progress_update(set = NULL, status = show, force = TRUE)

      # Archive includes topic/category/subtitle data not present in stats.txt.
      # We drop archive's date/title/host/guest/duration in favor of stats.txt:
      # stats.txt has full HH:MM:SS duration, consistent quoting, and the
      # archive's host/guest parser is less reliable.
      archived <- incomparable_parse_archive(archive_url)

      # Some archive pages return empty (e.g. dwf as of 2021-09-29)
      if (nrow(archived) == 0) {
        cli::cli_alert_warning("Empty archive page for {show} at {archive_url}")
        return(tibble())
      }

      archived <- archived |>
        dplyr::mutate(show = show) |>
        dplyr::select(
          -dplyr::any_of(c("duration", "title", "host", "guest", "date"))
        )

      stats <- incomparable_parse_stats(stats_url) |>
        dplyr::mutate(show = show)

      stats |>
        dplyr::full_join(archived, by = c("show", "number")) |>
        dplyr::select(
          "show",
          "number",
          "title",
          "duration",
          "date",
          "year",
          "month",
          "weekday",
          "host",
          "guest",
          "category",
          "topic",
          "summary",
          "network"
        )
    }
  ) |>
    purrr::list_rbind()
  cli::cli_progress_done()

  checkmate::assert_data_frame(episodes, min.rows = 1, ncols = 14)

  if (cache) {
    cache_podcast_data(episodes, filename = "incomparable_episodes")
  }

  episodes
}
