#' Retrieve all relay.fm shows
#'
#' Parses the show overview page and returns a tibble of show names
#' with corresponding feed URLs, which in turn can then be passed to
#' `relay_parse_feed()` individually.
#'
#' @inheritParams incomparable_get_shows
#' @return A tibble with one row for each show.
#' @export
#'
#' @examples
#' \dontrun{
#' relay_get_shows()
#' }
relay_get_shows <- function(cache = TRUE) {
  assert_scrapable(podcast_urls$relay$shows)

  relay_shows <- poddr_get(podcast_urls$relay$shows, as = "html", cache = cache)

  shows <- relay_shows |>
    rvest::html_nodes(".broadcast__name a") |>
    rvest::html_text()

  feed_urls <- relay_shows |>
    rvest::html_nodes(".broadcast__name a") |>
    rvest::html_attr("href")

  feed_urls <- stringr::str_c("https://www.relay.fm", feed_urls, "/feed")

  retired_shows <- relay_shows |>
    rvest::html_nodes(".subheader~ .entry .broadcast__name a") |>
    rvest::html_text()

  shows <- tibble(
    show = shows,
    feed_url = feed_urls,
    show_status = ifelse(shows %in% retired_shows, "Retired", "Active")
  )

  checkmate::assert_data_frame(shows, min.rows = 1, ncols = 3)
  shows
}

#' Parse a relay.fm show feed
#'
#' Parses a single feed and returns its content as a tibble.
#' @param url A show's feed URL, e.g. `"https://www.relay.fm/ungeniused/feed"`.
#'   Use `relay_get_shows()` to retrieve feed URLs.
#' @param cache (`logical(1)`) Toggle the httr2 HTTP cache. Default `TRUE`.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' relay_parse_feed(url = "https://www.relay.fm/ungeniused/feed")
#' }
relay_parse_feed <- function(url, cache = TRUE) {
  feed <- poddr_get(url, as = "xml", cache = cache)
  parse_relay_feed_xml(feed)
}

# Inner parser, testable offline against synthetic XML fixtures.
parse_relay_feed_xml <- function(feed) {
  show <- feed |>
    rvest::html_node("channel") |>
    rvest::html_node("title") |>
    rvest::html_text()

  titles <- feed |>
    rvest::html_nodes("item") |>
    rvest::html_node("title") |>
    rvest::html_text()

  number <- titles |>
    stringr::str_extract("\\d+:") |>
    stringr::str_replace(":", "") |>
    as.character()

  # Use local-name() XPath so the selectors work for both plain RSS
  # (synthetic test fixtures) and namespaced itunes:* elements (real feeds).
  duration <- xml2::xml_find_all(feed, ".//*[local-name()='duration']") |>
    xml2::xml_text() |>
    as.numeric()

  pubdate <- xml2::xml_find_all(feed, ".//*[local-name()='pubDate']") |>
    xml2::xml_text() |>
    stringr::str_replace("^.{5}", "") |>
    lubridate::parse_date_time("%d %b %Y %H:%M:%S", tz = "GMT") |>
    lubridate::as_date()

  people <- xml2::xml_find_all(feed, ".//*[local-name()='author']") |>
    xml2::xml_text() |>
    stringr::str_replace_all(",? and ", ";") |>
    stringr::str_replace_all(",\\s*", ";") |>
    stringr::str_replace_all("\\s+", " ")

  # The channel-level <title>, <pubdate>, and <author> elements appear
  # before per-item ones; drop the first hit when the channel emitted
  # one. Detect by length mismatch: items count vs. pubdate count.
  n_items <- length(titles)
  if (length(pubdate) == n_items + 1) {
    pubdate <- pubdate[-1]
  }
  if (length(people) == n_items + 1) {
    people <- people[-1]
  }

  tibble(
    show = show,
    number = number,
    title = stringr::str_remove(titles, "^\\d+:\\s"),
    duration = hms::hms(seconds = duration),
    date = pubdate,
    year = lubridate::year(pubdate),
    month = lubridate::month(pubdate, abbr = FALSE, label = TRUE),
    weekday = lubridate::wday(pubdate, abbr = FALSE, label = TRUE),
    host = people,
    network = "relay.fm"
  )
}

#' Retrieve all episodes for relay.fm shows
#'
#' @param relay_shows A tibble of shows, from `relay_get_shows()`.
#' @inheritParams incomparable_get_shows
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' relay_shows <- relay_get_shows()
#' relay <- relay_get_episodes(relay_shows)
#' }
relay_get_episodes <- function(relay_shows, cache = TRUE) {
  pb_id <- cli::cli_progress_bar(
    "Getting feeds",
    total = nrow(relay_shows),
    format = "{cli::pb_spin} {cli::pb_current}/{cli::pb_total} {show}",
    .auto_close = FALSE
  )

  episodes <- purrr::pmap(relay_shows, \(show, feed_url, ...) {
    cli::cli_progress_update(id = pb_id, status = show, force = TRUE)
    relay_parse_feed(feed_url, cache = cache)
  }) |>
    purrr::list_rbind()
  cli::cli_progress_done(id = pb_id)

  checkmate::assert_data_frame(episodes, min.rows = 1)
  episodes
}
