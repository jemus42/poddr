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
  feed <- read_html(url)

  show <- feed %>%
    html_node("channel") %>%
    html_node("title") %>%
    html_text()

  titles <- feed %>%
    html_nodes("item") %>%
    html_node("title") %>%
    html_text()

  number <- titles %>%
    stringr::str_extract("\\d+:") %>%
    stringr::str_replace(":", "") %>%
    as.numeric()

  durations <- feed %>%
    html_nodes("duration") %>%
    html_text() %>%
    as.numeric() %>%
    magrittr::divide_by(60) # in minutes

  pubdate <- feed %>%
    html_nodes("pubdate") %>%
    html_text() %>%
    stringr::str_replace("^.{5}", "") %>%
    lubridate::parse_date_time("%d %b %Y %H:%M:%S", tz = "GMT") %>%
    lubridate::as_date() %>%
    magrittr::extract(-1)

  people <- feed %>%
    html_nodes("author") %>%
    html_text() %>%
    stringr::str_replace_all(" and ", ", ") %>%
    magrittr::extract(-1)

  tibble(
    number = number,
    show = show,
    title = titles,
    duration = durations,
    date = pubdate,
    year = lubridate::year(date),
    month = lubridate::month(date, abbr = FALSE, label = TRUE),
    weekday = lubridate::wday(date, label = TRUE, abbr = FALSE),
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
  relay_shows <- read_html(url)

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
#' relay <- relay_get_episodes(relay__get_shows(url = "https://www.relay.fm/shows"))
#' }
relay_get_episodes <- function(relay_shows) {

  relay <- purrr::map_df(relay_shows$feed_url, relay_parse_feed)

  # relay <- relay_shows %>%
  #   dplyr::left_join(relay, by = "show")

  relay
}
