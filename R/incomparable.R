#' Retrieve all The Incomparable shows
#'
#' @param cache (`logical(1)`) Toggle the httr2 HTTP cache. Default `TRUE`.
#' @return A tibble with columns `show`, `stats_url`, `archive_url`, `status`.
#' @export
#' @examples
#' \dontrun{
#' incomparable_get_shows()
#' }
incomparable_get_shows <- function(cache = TRUE) {
  assert_scrapable(podcast_urls$incomparable$shows)
  base_url <- podcast_urls$incomparable$base
  show_index <- poddr_get(
    podcast_urls$incomparable$shows,
    as = "html",
    cache = cache
  )

  shows_active <- extract_incomparable_shows(
    show_index,
    "#recent",
    "active",
    base_url
  )
  shows_retired <- extract_incomparable_shows(
    show_index,
    "#retired",
    "retired",
    base_url
  )

  shows <- dplyr::bind_rows(shows_active, shows_retired)
  checkmate::assert_data_frame(shows, min.rows = 15, ncols = 4)
  shows
}

extract_incomparable_shows <- function(show_index, css_root, status, base_url) {
  names <- show_index |>
    rvest::html_nodes(paste0(css_root, " h5 a")) |>
    rvest::html_text()
  partials <- show_index |>
    rvest::html_nodes(paste0(css_root, " h5 a")) |>
    rvest::html_attr("href") |>
    stringr::str_replace_all("\\/", "")

  tibble(
    show = names,
    stats_url = glue::glue("{base_url}/{partials}/stats.txt"),
    archive_url = glue::glue("{base_url}/{partials}/archive/"),
    status = status
  )
}

#' Parse a show's archive page on The Incomparable website
#'
#' @param archive_url E.g. `"https://www.theincomparable.com/theincomparable/archive/"`.
#' @inheritParams incomparable_get_shows
#' @return A tibble.
#' @export
#' @examples
#' \dontrun{
#' incomparable_parse_archive("https://www.theincomparable.com/gameshow/archive/")
#' }
incomparable_parse_archive <- function(archive_url, cache = TRUE) {
  archive_parsed <- poddr_get(archive_url, as = "html", cache = cache)
  parse_incomparable_archive_html(archive_parsed)
}

parse_incomparable_archive_html <- function(archive_parsed) {
  # NULL guard preserves the contract that callers can iterate over
  # archive_url lists tolerantly when the upstream returns 500.
  if (is.null(archive_parsed)) {
    return(tibble())
  }

  entries <- archive_parsed |>
    rvest::html_nodes(css = ".episode-list li")

  subcat_header <- archive_parsed |>
    rvest::html_nodes("h6") |>
    rvest::html_text()
  has_categories <- identical(subcat_header, "Subcategories")

  purrr::map(entries, \(x) {
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
#' @inheritParams incomparable_parse_archive
#' @return A tibble with subcategory links and category names.
#' @export
#' @examples
#' \dontrun{
#' incomparable_get_subcategories("https://www.theincomparable.com/gameshow/archive/")
#' }
incomparable_get_subcategories <- function(
  archive_url = "https://www.theincomparable.com/gameshow/archive/",
  cache = TRUE
) {
  show_index <- poddr_get(archive_url, as = "html", cache = cache)

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
#' @param stats_url URL to the `stats.txt`.
#' @inheritParams incomparable_get_shows
#' @return A tibble.
#' @export
#' @examples
#' \dontrun{
#' incomparable_parse_stats("https://www.theincomparable.com/salvage/stats.txt")
#' }
incomparable_parse_stats <- function(stats_url, cache = TRUE) {
  body <- poddr_get(stats_url, as = "text", cache = cache)
  parse_incomparable_stats_text(body)
}

parse_incomparable_stats_text <- function(text) {
  readr::read_delim(
    I(text),
    delim = ";",
    quote = "",
    col_names = c("number", "date", "duration", "title", "host", "guest"),
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
#' @param incomparable_shows Dataset of shows as returned by `incomparable_get_shows()`.
#' @inheritParams incomparable_get_shows
#' @return A tibble.
#' @export
#' @examples
#' \dontrun{
#' shows <- incomparable_get_shows()
#' incomparable_get_episodes(shows)
#' }
incomparable_get_episodes <- function(incomparable_shows, cache = TRUE) {
  pb_id <- cli::cli_progress_bar(
    "Getting episodes",
    total = nrow(incomparable_shows),
    format = "{cli::pb_spin} {cli::pb_current}/{cli::pb_total} {show}",
    .auto_close = FALSE
  )

  episodes <- purrr::pmap(
    incomparable_shows,
    \(show, stats_url, archive_url, ...) {
      cli::cli_progress_update(id = pb_id, status = show, force = TRUE)

      archived <- incomparable_parse_archive(archive_url, cache = cache)

      if (nrow(archived) == 0) {
        cli::cli_alert_warning("Empty archive page for {show} at {archive_url}")
        return(tibble())
      }

      archived <- archived |>
        dplyr::mutate(show = show) |>
        dplyr::select(
          -dplyr::any_of(c("duration", "title", "host", "guest", "date"))
        )

      stats <- incomparable_parse_stats(stats_url, cache = cache) |>
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
  cli::cli_progress_done(id = pb_id)

  checkmate::assert_data_frame(episodes, min.rows = 1, ncols = 14)
  episodes
}
