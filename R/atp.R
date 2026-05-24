#' Retrieve ATP episodes
#'
#' @param page_limit Number of pages to scrape, from newest to oldest episode.
#' Page 1 contains the 5 most recent episodes, and subsequent pages contain 50
#' episodes per page. As of December 2020, there are 10 pages total.
#' Pass `NULL` (default) to get all pages.
#' @inheritParams incomparable_get_shows
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' # Only the first page with the newest 5 episodes
#' atp_new <- atp_get_episodes(page_limit = 1)
#'
#' # The latest and then 50 more
#' atp_latest <- atp_get_episodes(page_limit = 2)
#'
#' # Get all episodes (use wisely)
#' atp_full <- atp_get_episodes()
#' }
atp_get_episodes <- function(page_limit = NULL, cache = TRUE) {
  if (is.null(page_limit)) {
    page_limit <- Inf
  }
  # Get the first page and scrape it
  session <- polite::bow(url = podcast_urls$atp$base)

  atp_pages <- list("1" = polite::scrape(session))
  next_page_num <- 2

  # Early return for first page only
  if (page_limit == 1) {
    return(atp_parse_page(atp_pages[[1]]))
  }

  # Find out how many pages there will be in total
  # purely for progress bar cosmetics.
  latest_ep_num <- atp_pages[[1]] |>
    rvest::html_nodes("h2 a") |>
    rvest::html_text() |>
    stringr::str_extract("^\\d+") |>
    as.integer() |>
    max(na.rm = TRUE)

  checkmate::assert_int(latest_ep_num)

  # First page has 5 episodes, 50 episodes per page afterwards
  # Undercounts due to unnumbered member episodes, off by at least 1
  # as of 2024-05-25, so adding 1.
  total_pages <- ceiling((latest_ep_num - 5) / 50) + 1 + 1

  cli::cli_progress_bar("Getting pages", total = total_pages)
  cli::cli_progress_update()

  # Iteratively get the next page until the limit is reached
  # (or if there's no next page to retrieve)
  while (next_page_num <= page_limit) {
    cli::cli_progress_update()

    atp_pages[[next_page_num]] <- polite::scrape(
      session,
      query = list(page = next_page_num)
    )

    # Find the next page number
    next_page_num <- atp_pages[[next_page_num]] |>
      rvest::html_nodes("#pagination a+ a") |>
      rvest::html_attr("href") |>
      stringr::str_extract("\\d+$") |>
      as.numeric()

    # Break the loop if there's no next page
    if (length(next_page_num) == 0) break
  }
  cli::cli_progress_done()

  # Now parse all the pages and return
  cli::cli_progress_bar("Parsing pages", total = length(atp_pages))

  episodes <- purrr::map(atp_pages, \(x) {
    cli::cli_progress_update()
    atp_parse_page(x)
  }) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      network = "ATP",
      show = "ATP"
    )
  cli::cli_progress_done()

  checkmate::assert_data_frame(episodes, min.rows = 1)
  oldest_episode <- as.integer(episodes$number[length(episodes$number)])

  if (!oldest_episode == 1L) {
    cli::cli_warn(
      "Oldest episode in dataset is not 1 but {oldest_episode}, it's time to adjust the offset maybe?"
    )
  }
  if (cache) {
    cache_podcast_data(episodes, filename = "atp", csv = FALSE)
  }

  episodes
}

#' Parse a single ATP page
#'
#' @param page Scraped page object, e.g. from `polite::scrape()`.
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' session <- polite::bow(url = "https://atp.fm")
#' page <- polite::scrape(session, query = list(page = 1))
#' atp_parse_page(page)
#' }
atp_parse_page <- function(page) {
  rvest::html_nodes(page, "article") |>
    purrr::map(\(x) {
      # Members-only post: skip, no parseable data
      is_memberpost <- !is.na(rvest::html_node(x, ".membersonlypromo"))
      if (is_memberpost) {
        return(tibble())
      }

      meta <- rvest::html_node(x, ".metadata") |>
        rvest::html_text() |>
        stringr::str_trim()

      date <- meta |>
        stringr::str_extract("^.*(?=\\\n)") |>
        lubridate::mdy()

      duration <- meta |>
        stringr::str_extract("\\d{2}:\\d{2}:\\d{2}") |>
        hms::as_hms()

      number <- x |>
        rvest::html_nodes("h2 a") |>
        rvest::html_text() |>
        stringr::str_extract("^\\d+")

      title <- x |>
        rvest::html_nodes("h2 a") |>
        rvest::html_text() |>
        stringr::str_remove("^\\d+:\\s")

      # Sponsor links are in the second <ul>
      links_sponsor <- x |>
        rvest::html_nodes("ul~ ul li") |>
        rvest::html_nodes("a")

      links_sponsor <- tibble(
        link_text = rvest::html_text(links_sponsor),
        link_url = rvest::html_attr(links_sponsor, "href"),
        link_type = "Sponsor"
      )

      # Regular shownotes links are in the first <ul>
      # (avoids links in paragraphs and sponsor section)
      links_regular <- x |>
        rvest::html_node("ul") |>
        rvest::html_nodes("li a")

      links_regular <- tibble(
        link_text = rvest::html_text(links_regular),
        link_url = rvest::html_attr(links_regular, "href"),
        link_type = "Shownotes"
      )

      all_links <- list(dplyr::bind_rows(links_regular, links_sponsor))

      tibble(
        number = number,
        title = title,
        duration = duration,
        date = date,
        year = lubridate::year(date),
        month = lubridate::month(date, abbr = FALSE, label = TRUE),
        weekday = lubridate::wday(date, abbr = FALSE, label = TRUE),
        links = all_links,
        n_links = purrr::map_int(all_links, nrow)
      )
    }) |>
    purrr::list_rbind()
}
