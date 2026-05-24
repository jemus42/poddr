poddr_get <- function(
  url,
  as = c("html", "xml", "text"),
  query = NULL,
  cache = TRUE
) {
  as <- rlang::arg_match(as)

  req <- httr2::request(url) |>
    httr2::req_user_agent(
      getOption("poddr_user_agent", default_user_agent())
    ) |>
    httr2::req_throttle(
      rate = getOption("poddr_throttle_rate", 1 / 2),
      realm = httr2::url_parse(url)$hostname
    ) |>
    httr2::req_retry(
      max_tries = 3,
      is_transient = \(resp) {
        httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504)
      }
    )

  if (!is.null(query)) {
    req <- httr2::req_url_query(req, !!!query)
  }

  if (isTRUE(cache)) {
    req <- httr2::req_cache(
      req,
      path = getOption("poddr_cache_dir", tools::R_user_dir("poddr", "cache")),
      max_age = getOption("poddr_cache_max_age", 7 * 86400),
      max_size = getOption("poddr_cache_max_size", 100 * 1024^2)
    )
  }

  resp <- httr2::req_perform(req)
  body <- httr2::resp_body_string(resp)

  if (httr2::resp_status(resp) == 204 || identical(body, "")) {
    return(switch(as, html = NULL, xml = NULL, text = ""))
  }

  switch(
    as,
    html = rvest::read_html(body),
    xml = xml2::read_xml(body),
    text = body
  )
}
