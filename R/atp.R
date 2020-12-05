#' Parse a single ATP page
#'
#' @param page Scraped page.
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
  rvest::html_nodes(page, "article") %>%
    purrr::map_dfr(~ {
      # browser()
      meta <- rvest::html_node(.x, ".metadata") %>%
        rvest::html_text() %>%
        stringr::str_trim()

      date <- meta %>%
        stringr::str_extract("^.*(?=\\\n)") %>%
        lubridate::mdy()

      duration <- meta %>%
        stringr::str_extract("\\d{2}:\\d{2}:\\d{2}") %>%
        hms::as_hms()

      number <- .x %>%
        rvest::html_nodes("h2 a") %>%
        rvest::html_text() %>%
        stringr::str_extract("^\\d+")

      title <- .x %>%
        rvest::html_nodes("h2 a") %>%
        rvest::html_text() %>%
        stringr::str_remove("^\\d+:\\s")

      link_text <- rvest::html_nodes(.x, "li a") %>%
        rvest::html_text()

      link_url <- rvest::html_nodes(.x, "li a") %>%
        rvest::html_attr("href")

      tibble(
        number = number,
        title = title,
        duration = duration,
        date = date,
        year = lubridate::year(date),
        month = lubridate::month(date, abbr = FALSE, label = TRUE),
        weekday = lubridate::wday(date, abbr = FALSE, label = TRUE),
        links = list(
          tibble(
            link_text = link_text,
            link_url = link_url
          )
        ),
        n_links = purrr::map_int(links, nrow)
      )
    })
}

#' Retrieve ATP episodes
#'
#' @param page_limit Number of pages to scrape, from newest to oldest episode.
#' Page 1 contains the 5 most recent episodes, and subsequent pages contain 50
#' episodes per page. As of December 2020, there are 10 pages total.
#' Pass `NULL` (default) to get all pages.
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
atp_get_episodes <- function(page_limit = NULL) {

  if (is.null(page_limit)) page_limit <- Inf

  # Get the first page and scrape it
  session <- polite::bow(url = "https://atp.fm")

  atp_pages <- list("1" = polite::scrape(session))
  next_page_num <- 2

  # Early return for first page only
  if (page_limit == 1) {
    atp_parse_page(atp_pages[[1]])
  }

  # Find out how many pages there will be in total
  # purely for progress bar cosmetics.
  latest_ep_num <- atp_pages[[1]] %>%
    rvest::html_nodes("h2 a") %>%
    rvest::html_text() %>%
    stringr::str_extract("^\\d+") %>%
    as.numeric() %>%
    max()

  # First page has 5 episodes, 50 episodes per page afterwards
  total_pages <- ceiling((latest_ep_num - 5) / 50) + 1

  pb <- progress::progress_bar$new(
    format = "Getting pages [:bar] :current/:total (:percent) ETA: :eta",
    total = total_pages
  )
  pb$tick()

  # Iteratively get the next page until the limit is reached
  # (or of there's no next page to retrieve)
  while (next_page_num <= page_limit) {
    pb$tick()

    atp_pages[[next_page_num]] <- polite::scrape(
      session,
      query = list(page = next_page_num)
    )

    # Find the next page number
    next_page_num <- atp_pages[[next_page_num]] %>%
      rvest::html_nodes("#pagination a+ a") %>%
      rvest::html_attr("href") %>%
      stringr::str_extract("\\d+$") %>%
      as.numeric()

    # Break the loop if there's no next page
    if (length(next_page_num) == 0) break
  }

  # Now parse all the pages and return
  pb <- progress::progress_bar$new(
    format = "Parsing pages [:bar] :current/:total (:percent) ETA: :eta",
    total = length(atp_pages)
  )

  purrr::map_dfr(atp_pages, ~ {
    pb$tick()
    atp_parse_page(.x)
  })
}