#' Parse a relay.fm show feed
#'
#' @param url A show's feed URL, e.g. `"https://www.relay.fm/ungeniused/feed"`.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' relay_parse_feed(url = "https://www.relay.fm/ungeniused/feed")
#' }
relay_parse_feed <- function(url) {
  feed <- polite::bow(url) %>%
    polite::scrape(accept = "html", content = "text/html; charset=utf-8")

  show <- feed %>%
    rvest::html_node("channel") %>%
    rvest::html_node("title") %>%
    rvest::html_text()

  titles <- feed %>%
    rvest::html_nodes("item") %>%
    rvest::html_node("title") %>%
    rvest::html_text()

  number <- titles %>%
    stringr::str_extract("\\d+:") %>%
    stringr::str_replace(":", "") %>%
    as.character()

  duration <- feed %>%
    rvest::html_nodes("duration") %>%
    rvest::html_text() %>%
    as.numeric()

  pubdate <- feed %>%
    rvest::html_nodes("pubdate") %>%
    rvest::html_text() %>%
    stringr::str_replace("^.{5}", "") %>%
    lubridate::parse_date_time("%d %b %Y %H:%M:%S", tz = "GMT") %>%
    lubridate::as_date() %>%
    magrittr::extract(-1)

  people <- feed %>%
    rvest::html_nodes("author") %>%
    rvest::html_text() %>%
    stringr::str_replace_all(",? and ", ";") %>%
    stringr::str_replace_all(",\\s*", ";") %>%
    magrittr::extract(-1)

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

#' Collect all relay.fm shows
#'
#' @param url Show overview page: `"https://www.relay.fm/shows"`.
#'
#' @return A tibble with one row for each show
#' @export
#'
#' @examples
#' \dontrun{
#' relay_get_shows()
#' }
relay_get_shows <- function(url = "https://www.relay.fm/shows") {
  relay_shows <- polite::bow(url) %>%
    polite::scrape()

  shows <- relay_shows %>%
    rvest::html_nodes(".broadcast__name a") %>%
    rvest::html_text()

  feed_urls <- relay_shows %>%
    rvest::html_nodes(".broadcast__name a") %>%
    rvest::html_attr("href") %>%
    stringr::str_c("https://www.relay.fm", ., "/feed")

  retired_shows <- relay_shows %>%
    rvest::html_nodes(".subheader~ .entry .broadcast__name a") %>%
    rvest::html_text()

  tibble(
    show = shows,
    feed_url = feed_urls,
    show_status = ifelse(shows %in% retired_shows, "Retired", "Active")
  )
}

#' Collect all relay.fm shows
#'
#' @param relay_shows A tibble of shows, from `relay_get_shows()`.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' relay <- relay_get_episodes(relay_get_shows())
#' }
relay_get_episodes <- function(relay_shows) {
  pb <- progress::progress_bar$new(
    format = "Getting :show [:bar] :current/:total (:percent) ETA: :eta",
    total = nrow(relay_shows)
  )

  purrr::pmap_df(relay_shows, ~ {
    pb$tick(tokens = list(show = ..1))
    relay_parse_feed(..2)
  })
}
