#' Retrieve ATP episodes
#'
#' @param page_limit Number of pages to scrape, from newest to oldest episode.
#' Page 1 contains the 5 most recent episodes, and subsequent pages contain 50
#' episodes per page. Pass `NULL` (default) to get all pages.
#' @param cache (`logical(1)`) Toggle the httr2 HTTP cache. Default `TRUE`.
#' Disk writes are not performed by this function; call
#' [cache_podcast_data()] explicitly if you want RDS/CSV artefacts.
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' atp_new <- atp_get_episodes(page_limit = 1)
#' atp_full <- atp_get_episodes()
#' }
atp_get_episodes <- function(page_limit = NULL, cache = TRUE) {
  assert_scrapable(podcast_urls$atp$base)

  if (is.null(page_limit)) {
    page_limit <- Inf
  }

  atp_pages <- list(
    "1" = poddr_get(podcast_urls$atp$base, as = "html", cache = cache)
  )
  next_page_num <- 2

  if (page_limit == 1) {
    return(
      atp_parse_page(atp_pages[[1]]) |>
        dplyr::mutate(network = "ATP", show = "ATP")
    )
  }

  latest_ep_num <- atp_pages[[1]] |>
    rvest::html_nodes("h2 a") |>
    rvest::html_text() |>
    stringr::str_extract("^\\d+") |>
    as.integer() |>
    max(na.rm = TRUE)

  checkmate::assert_int(latest_ep_num)

  # First page has 5 episodes, 50 per page after.
  # Undercounts due to unnumbered member episodes (+1 fudge).
  total_pages <- ceiling((latest_ep_num - 5) / 50) + 1 + 1

  cli::cli_progress_bar("Getting pages", total = total_pages)
  cli::cli_progress_update()

  while (next_page_num <= page_limit) {
    cli::cli_progress_update()

    atp_pages[[next_page_num]] <- poddr_get(
      podcast_urls$atp$base,
      as = "html",
      query = list(page = next_page_num),
      cache = cache
    )

    next_page_num <- atp_pages[[next_page_num]] |>
      rvest::html_nodes("#pagination a+ a") |>
      rvest::html_attr("href") |>
      stringr::str_extract("\\d+$") |>
      as.numeric()

    if (length(next_page_num) == 0) break
  }
  cli::cli_progress_done()

  # purrr's own .progress arg avoids the cli env-scoping bug that fires
  # when cli_progress_update() is called from inside a purrr::map lambda.
  episodes <- purrr::map(
    atp_pages,
    atp_parse_page,
    .progress = "Parsing pages"
  ) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      network = "ATP",
      show = "ATP"
    )

  checkmate::assert_data_frame(episodes, min.rows = 1)
  oldest_episode <- as.integer(episodes$number[length(episodes$number)])

  if (!oldest_episode == 1L) {
    cli::cli_warn(
      "Oldest episode in dataset is not 1 but {oldest_episode}, it's time to adjust the offset maybe?"
    )
  }

  episodes
}

#' Parse a single ATP page
#'
#' @param page Scraped page object (`xml_document`).
#'
#' @return A tibble.
#' @export
#'
#' @examples
#' \dontrun{
#' html <- poddr:::poddr_get("https://atp.fm", as = "html", query = list(page = 1))
#' atp_parse_page(html)
#' }
atp_parse_page <- function(page) {
  rvest::html_nodes(page, "article") |>
    purrr::map(\(x) {
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

      links_sponsor <- x |>
        rvest::html_nodes("ul~ ul li") |>
        rvest::html_nodes("a")

      links_sponsor <- tibble(
        link_text = rvest::html_text(links_sponsor),
        link_url = rvest::html_attr(links_sponsor, "href"),
        link_type = "Sponsor"
      )

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
