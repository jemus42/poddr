#' Retrieve all relay.fm shows
#'
#' Parses the show overview page and returns a tibble of show names
#' with corresponding feed URLs, which in turn can then be passed to
#' `relay_parse_feed()` individually.
#'
#' @inheritParams incomparable_get_shows
#' @return A tibble with one row for each show
#' @export
#'
#' @examples
#' \dontrun{
#' relay_get_shows()
#' }
relay_get_shows <- function(cache = TRUE) {
  url <- podcast_urls$relay$shows

  relay_shows <- polite::bow(url) |>
    polite::scrape()

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

  shows = tibble(
    show = shows,
    feed_url = feed_urls,
    show_status = ifelse(shows %in% retired_shows, "Retired", "Active")
  )

  checkmate::assert_data_frame(shows, min.rows = 1, ncols = 3)

  if (cache) {
    cache_podcast_data(shows, filename = "relay_episodes")
  }

  shows
}

#' Parse a relay.fm show feed
#'
#' Parses a single feed and returns its content as a tibble.
#' @param url A show's feed URL, e.g. `"https://www.relay.fm/ungeniused/feed"`.
#'   Use `relay_get_shows()` to retrieve feed URLs.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' relay_parse_feed(url = "https://www.relay.fm/ungeniused/feed")
#' }
relay_parse_feed <- function(url) {
  feed <- polite::bow(url) |>
    polite::scrape(accept = "html", content = "text/html; charset=utf-8")

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

  duration <- feed |>
    rvest::html_nodes("duration") |>
    rvest::html_text() |>
    as.numeric()

  pubdate <- feed |>
    rvest::html_nodes("pubdate") |>
    rvest::html_text() |>
    stringr::str_replace("^.{5}", "") |>
    lubridate::parse_date_time("%d %b %Y %H:%M:%S", tz = "GMT") |>
    lubridate::as_date()
  pubdate <- pubdate[-1]

  people <- feed |>
    rvest::html_nodes("author") |>
    rvest::html_text() |>
    stringr::str_replace_all(",? and ", ";") |>
    stringr::str_replace_all(",\\s*", ";") |>
    stringr::str_replace_all("\\s+", " ")
  people <- people[-1]

  tibble(
    show = show,
    number = number,
    title = stringr::str_remove(titles, "^\\d+:\\s"),
    duration = hms::hms(seconds = duration),
    date = pubdate,
    year = lubridate::year(date),
    month = lubridate::month(date, abbr = FALSE, label = TRUE),
    weekday = lubridate::wday(date, abbr = FALSE, label = TRUE),
    host = people,
    network = "relay.fm"
  )
}

#' Retrieve all episodes for relay.fm shows
#'
#' Retrieves all episodes for one or more shows passed as a tibble.
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
  pb <- progress::progress_bar$new(
    format = "Getting :show :current/:total (:percent) ETA: :eta [:bar]",
    total = nrow(relay_shows)
  )

  episodes = purrr::pmap_df(relay_shows, ~ {
    pb$tick(tokens = list(show = ..1))
    relay_parse_feed(..2)
  })

  checkmate::assert_data_frame(episodes, min.rows = 1)

  if (cache) {
    cache_podcast_data(episodes, filename = "relay_episodes")
  }

  episodes
}
