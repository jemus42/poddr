test_that("relay_get_shows returns a tibble of shows + feed URLs", {
  local_isolated_cache()
  local_clear_robotstxt_cache()
  vcr::use_cassette("relay_get_shows", re_record_interval = 30L * 86400L, {
    out <- relay_get_shows(cache = FALSE)
  })
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0)
  expect_named(out, c("show", "feed_url", "show_status"), ignore.order = TRUE)
  expect_true(all(grepl("^https://www\\.relay\\.fm", out$feed_url)))
  expect_true(all(out$show_status %in% c("Active", "Retired")))
})

test_that("relay_parse_feed returns a well-shaped tibble", {
  local_isolated_cache()
  local_clear_robotstxt_cache()
  vcr::use_cassette(
    "relay_parse_feed-connected",
    re_record_interval = 30L * 86400L,
    {
      out <- relay_parse_feed("https://www.relay.fm/connected/feed")
    }
  )
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0)
  expect_named(
    out,
    c(
      "show",
      "number",
      "title",
      "duration",
      "date",
      "year",
      "month",
      "weekday",
      "host",
      "network"
    ),
    ignore.order = TRUE
  )
  expect_s3_class(out$duration, "hms")
  expect_s3_class(out$date, "Date")
  expect_true(all(out$network == "relay.fm"))
})

test_that("relay_get_episodes works on a single-show input", {
  local_isolated_cache()
  local_clear_robotstxt_cache()
  vcr::use_cassette(
    "relay_get_episodes-one_show",
    re_record_interval = 30L * 86400L,
    {
      shows <- relay_get_shows(cache = FALSE)
      one <- shows |> dplyr::slice(1)
      out <- relay_get_episodes(one, cache = FALSE)
    }
  )
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0)
  expect_snapshot(glimpse_schema(out))
})
