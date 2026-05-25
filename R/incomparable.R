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

#' Parse a single Incomparable episode page
#'
#' Recovers `summary` (and `topic` when present) for episodes that
#' aren't on the archive page yet. The archive page is re-rendered on
#' a slower cadence than `stats.txt` updates, so the newest episode of
#' an active show is typically missing from the archive for hours to
#' weeks. `incomparable_get_episodes()` calls this automatically for
#' any episode in `stats.txt` that the archive doesn't list.
#'
#' @param episode_url The per-episode URL,
#'   e.g. `"https://www.theincomparable.com/sophomorelit/190/"`.
#' @inheritParams incomparable_get_shows
#'
#' @return A one-row tibble with columns `summary` and `topic` (either
#'   may be `NA_character_` if the page doesn't expose them).
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable_parse_episode("https://www.theincomparable.com/sophomorelit/190/")
#' }
incomparable_parse_episode <- function(episode_url, cache = TRUE) {
  parsed <- poddr_get(episode_url, as = "html", cache = cache)
  parse_incomparable_episode_html(parsed)
}

parse_incomparable_episode_html <- function(episode_parsed) {
  if (is.null(episode_parsed)) {
    return(tibble(summary = NA_character_, topic = NA_character_))
  }

  summary <- episode_parsed |>
    rvest::html_nodes("meta[property='og:description']") |>
    rvest::html_attr("content")
  summary <- if (length(summary) == 0) NA_character_ else summary[1]

  # Individual episode pages rarely carry a populated .episode-subtitle
  # (the archive page does), but cheap to check.
  topic <- episode_parsed |>
    rvest::html_nodes(".episode-subtitle") |>
    rvest::html_text() |>
    stringr::str_trim()
  topic <- topic[nzchar(topic)]
  topic <- if (length(topic) == 0) NA_character_ else topic[1]

  tibble(summary = summary, topic = topic)
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

# For each episode that appears in stats.txt but not on the archive
# page, fetch the per-episode page and merge its summary (+ topic when
# present) into the archived tibble. No-op when archive is current.
# The episode URL is the archive URL with `archive/` swapped for the
# episode number.
fill_incomparable_archive_gap <- function(
  archived,
  stats,
  archive_url,
  cache = TRUE
) {
  gap_numbers <- setdiff(stats$number, archived$number)
  if (length(gap_numbers) == 0) {
    return(archived)
  }

  show_base_url <- sub("archive/?$", "", archive_url)

  gap_rows <- purrr::map(gap_numbers, \(n) {
    ep_url <- paste0(show_base_url, n, "/")
    fields <- incomparable_parse_episode(ep_url, cache = cache)
    tibble(number = n, summary = fields$summary, topic = fields$topic)
  }) |>
    purrr::list_rbind()

  dplyr::bind_rows(archived, gap_rows)
}

# Join stats and archive tibbles for one show. Date-derived columns
# (year/month/weekday) and the constant `network` are recomputed AFTER
# the join from the canonical stats.date, so they stay populated even
# when the archive page lags behind stats.txt (e.g. the day a new
# episode lands and the archive hasn't been re-rendered yet) or when
# the join key mismatches (e.g. historical sub-indexed numbers like
# `123a`). `category`, `topic`, `summary` still come from the archive
# row — they're genuinely unrecoverable when archive lacks the entry.
combine_incomparable_episodes <- function(show, stats, archived) {
  archived <- archived |>
    dplyr::mutate(show = show) |>
    dplyr::select(
      -dplyr::any_of(c(
        "duration",
        "title",
        "host",
        "guest",
        "date",
        "year",
        "month",
        "weekday",
        "network"
      ))
    )

  stats <- stats |>
    dplyr::mutate(show = show)

  stats |>
    dplyr::full_join(archived, by = c("show", "number")) |>
    dplyr::mutate(
      year = lubridate::year(.data$date),
      month = lubridate::month(.data$date, abbr = FALSE, label = TRUE),
      weekday = lubridate::wday(.data$date, abbr = FALSE, label = TRUE),
      network = "The Incomparable"
    ) |>
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

      stats <- incomparable_parse_stats(stats_url, cache = cache)
      archived <- fill_incomparable_archive_gap(
        archived,
        stats,
        archive_url,
        cache = cache
      )
      combine_incomparable_episodes(show, stats, archived)
    }
  ) |>
    purrr::list_rbind()
  cli::cli_progress_done(id = pb_id)

  checkmate::assert_data_frame(episodes, min.rows = 1, ncols = 14)
  episodes
}
