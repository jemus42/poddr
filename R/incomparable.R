#' Retrieve all The Incomparable shows
#'
#' Parses the show overview page and returns a tibble of show names
#' with corresponding URLs, which in turn can then be passed to
#' `incomparable_parse_archive()` and `incomparable_parse_stats()` individually.
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
    rvest::html_nodes("h3 a") %>%
    rvest::html_text()

  show_partials <- show_index %>%
    rvest::html_nodes("h3 a") %>%
    rvest::html_attr("href") %>%
    stringr::str_replace_all("\\/", "")

  tibble(
    show = shows,
    # partial = show_partials,
    stats_url = glue::glue("{base_url}/{show_partials}/stats.txt"),
    archive_url = glue::glue("{base_url}/{show_partials}/archive/")
  )
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
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' archive_url <- "https://www.theincomparable.com/salvage/archive/"
#' incomparable_parse_archive(archive_url)
#' }
incomparable_parse_archive <- function(archive_url) {
  archive_parsed <- polite::bow(archive_url) %>%
    polite::scrape()

  # One element per entry, iterate over this to ensure
  # each episode and respective elements can be matched correctly
  # for things like topics and categories where not every episode
  # has such an element
  entries <- archive_parsed %>%
    rvest::html_nodes(css = "#entry")

  purrr::map_dfr(entries, ~ {
    epnums <- .x %>%
      rvest::html_nodes(css = ".episode-number") %>%
      rvest::html_text() %>%
      as.character()

    # Comic book club test case
    # if (epnums == "526") browser()
    # Non-categorized test case
    # if (epnums == "541") browser()

    summaries <- .x %>%
      rvest::html_nodes(css = ".episode-description") %>%
      rvest::html_text() %>%
      stringr::str_replace_all("^(\\W)*", "") %>%
      stringr::str_replace_all("\\W*$", "")

    titles <- .x %>%
      rvest::html_nodes(css = ".entry-title a") %>%
      rvest::html_text()

    postdate <- .x %>%
      rvest::html_nodes(".postdate:nth-child(1)") %>%
      rvest::html_text()

    date <- postdate[[1]] %>%
      stringr::str_trim(side = "both") %>%
      stringr::str_extract("^.*\\n") %>%
      stringr::str_trim(side = "both") %>%
      lubridate::mdy()

    # Handling of duration is wonky and WIP
    # also there are no seconds as of 2020-12-02
    duration <- postdate[[2]]

    duration <- list(
      hours = stringr::str_extract(duration, pattern = "\\d+(?=(\\shours))"),
      minutes = stringr::str_extract(duration, pattern = "\\d+(?=(\\sminutes))"),
      seconds = stringr::str_extract(duration, pattern = "\\d+(?=(\\sseconds))")
    )

    duration <- purrr::map(duration, ~ {
      if (is.na(.x)) {
        return(0)
      }
      as.numeric(.x)
    })

    duration <- hms::hms(
      seconds = duration$seconds,
      minutes = duration$minutes,
      hours = duration$hours
    )

    host <- .x %>%
      rvest::html_nodes(".postdate+ a") %>%
      rvest::html_text()

    guest <- .x %>%
      rvest::html_nodes("a+ a") %>%
      rvest::html_text() %>%
      paste(collapse = ";")

    categories <- .x %>%
      rvest::html_nodes(".subcast img") %>%
      rvest::html_attr("alt")

    if (identical(categories, character(0))) {
      categories <- NA_character_
    }

    topics <- .x %>%
      rvest::html_nodes(".postdate+ .postdate") %>%
      rvest::html_text() %>%
      stringr::str_extract("\\u2022.*") %>%
      stringr::str_replace_all("\\u2022", "") %>%
      stringr::str_trim("both")

    if (identical(topics, character(0))) {
      topics <- NA_character_
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
#' stats_url <- "https://www.theincomparable.com/salvage/stats.txt"
#' incomparable_parse_stats(stats_url)
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
  ) %>%
    dplyr::mutate(
      duration = parse_duration(.data$duration),
      date = lubridate::dmy(.data$date)#,
      #host = stringr::str_replace_all(.data$host, ",\\s*", ";"),
      #guest = stringr::str_replace_all(.data$guest, ",\\s*", ";")
    ) %>%
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

  incomparable_episodes <- purrr::pmap_dfr(incomparable_shows, ~ {
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

    archived <- archived %>%
      dplyr::mutate(show = ..1) %>%
      dplyr::select(-dplyr::any_of(c("duration", "title", "host", "guest", "date")))

    stats <- incomparable_parse_stats(..2) %>%
      dplyr::mutate(show = ..1)

    stats %>%
      dplyr::full_join(
        archived,
        by = c("show", "number")
      ) %>%
      dplyr::select(
        "show", "number", "title", "duration", "date", "year", "month",
        "weekday", "host", "guest", "category", "topic", "summary", "network"
      )
  })
}
