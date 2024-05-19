#' Retrieve all The Incomparable shows
#'
#' Parses the show overview page and returns a tibble of show names
#' with corresponding URLs, which in turn can then be passed to
#' `incomparable_parse_archive()` and `incomparable_parse_stats()` individually.
#'
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
incomparable_get_shows <- function() {
  base_url <- "https://www.theincomparable.com"
  show_index <- polite::bow(glue::glue("{base_url}/shows")) |>
    polite::scrape()

  shows <- show_index |>
    rvest::html_nodes("#recent h5 a") |>
    rvest::html_text()

  show_partials <- show_index |>
    rvest::html_nodes("#recent h5 a") |>
    rvest::html_attr("href") |>
    stringr::str_replace_all("\\/", "")

  shows_active <- tibble::tibble(
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

  shows_retired <- tibble::tibble(
    show = shows,
    # partial = show_partials,
    stats_url = glue::glue("{base_url}/{show_partials}/stats.txt"),
    archive_url = glue::glue("{base_url}/{show_partials}/archive/"),
    status = "retired"
  )

  dplyr::bind_rows(shows_active, shows_retired)
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
  if (is.null(archive_parsed)) return(tibble::tibble())

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

  # Iterate over list entries and return per-episode tbl to keep things together
  purrr::map_dfr(entries, ~ {
    # Treat episode numbers as character in case of letter suffixes
    epnums <- .x |>
      rvest::html_nodes(css = ".ep-num") |>
      rvest::html_text() |>
      as.character()

    # Multiple paragraphs will result in multiple elements, hence the concatenation
    summaries <- .x |>
      rvest::html_nodes(css = "p") |>
      rvest::html_text() |>
      stringr::str_c(collapse = "")

    titles <- .x |>
      rvest::html_nodes(css = "h5 a") |>
      rvest::html_text() |>
      stringr::str_remove_all("^\\d+\\w?[\\n\\s\\t]*")

    date <- .x |>
      rvest::html_nodes(".episode-date") |>
      rvest::html_text() |>
      stringr::str_extract("^[A-Za-z0-9\\s,]+?,\\s+\\d{4}") |>
      lubridate::mdy()

    host <- .x |>
      rvest::html_nodes(".hosts a:nth-child(1)") |>
      rvest::html_text()

    guest <- .x |>
      rvest::html_nodes("a+ a") |>
      rvest::html_text() |>
      paste(collapse = ";")

    # Only try to wrangle subcategory from image alt text if there are subcategories listed
    categories <- NA_character_
    if (has_categories) {
      categories <- .x |>
        rvest::html_nodes("img") |>
        rvest::html_attr("alt") |>
        stringr::str_remove_all("(^.*\\s-\\s)|(\\scover\\sart)")
    }

    topics <- .x |>
      rvest::html_nodes(".episode-subtitle") |>
      rvest::html_text()

    if (identical(topics, character(0))) {
      topics <- NA_character_
    }

    tibble::tibble(
      number = epnums,
      title = titles,
      #duration = duration,
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
incomparable_get_subcategories <- function(archive_url = "https://www.theincomparable.com/gameshow/archive/") {
  show_index <- polite::bow(archive_url) |>
    polite::scrape()

  show_index |>
    rvest::html_nodes("#recent aside a") |>
    purrr::map_dfr(~{

      link <- .x |> rvest::html_attr("href")
      link <- paste0("https://www.theincomparable.com", link)

      tibble::tibble(
        link = link,
        category = .x |> rvest::html_text()
      )
    })
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
  readr::read_delim(
    stats_url,
    delim = ";", quote = "",
    col_names = c(
      "number", "date", "duration", "title", "host", "guest"
    ),
    col_types = "cccccc",
    trim_ws = TRUE
  ) |>
    dplyr::mutate(
      duration = parse_duration(.data$duration),
      date = lubridate::dmy(.data$date)
    ) |>
    dplyr::mutate(dplyr::across(c("host", "guest"), ~ {
      stringr::str_replace_all(.x, "\\s*,\\s*", ";")
    }))
}

#' Retrieve all episodes for The Incomparable shows
#'
#' This combines `incomparable_parse_stats()` and `incomparable_parse_archive()`
#' to retrieve full episode information including host/guest, durations
#' including seconds, podcast subcategories and topics.
#' Use sparingly to limit unnecessarily hammering the poor webserver!
#' @param incomparable_shows Dataset of shows with title and URLs as returned by
#' `incomparable_get_shows()`.
#'
#' @return A tibble with one row per episode.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_shows <- incomparable_get_shows()
#' incomparable <- incomparable_get_episodes(incomparable_shows)
#' }
incomparable_get_episodes <- function(incomparable_shows) {
  pb <- progress::progress_bar$new(
    format = "Getting :show :current/:total (:percent) ETA: :eta [:bar]",
    total = nrow(incomparable_shows)
  )

  purrr::pmap_dfr(incomparable_shows, ~ {
    pb$tick(tokens = list(show = ..1))

    # Get the archive info, but drop duration (only HH:MM), and the
    # slightly wonky host/guest info. Also, date is off, compared to
    # stats.txt info, so not sure what to prefer
    # Also drop title because it uses different quotes than stats.txt,
    # which makes joining with stats.txt data weirder.
    archived <- incomparable_parse_archive(..3)

    # Return early/empty for broken archives, e.g. dwf
    # "https://www.theincomparable.com/dwf/archive/"
    # As of 2021-09-29
    if (nrow(archived) == 0) {
      message("\nEmpty archive page for ", ..1, " at ", ..3, "\n")
      return(tibble())
    }

    archived <- archived |>
      dplyr::mutate(show = ..1) |>
      dplyr::select(-dplyr::any_of(c("duration", "title", "host", "guest", "date")))

    stats <- incomparable_parse_stats(..2) |>
      dplyr::mutate(show = ..1)

    stats |>
      dplyr::full_join(
        archived,
        by = c("show", "number")
      ) |>
      dplyr::select(
        "show", "number", "title", "duration", "date", "year", "month",
        "weekday", "host", "guest",
        "category",
        "topic", "summary", "network"
      )
  })
}
