test_that("incomparable_get_shows returns the show index", {
  local_isolated_cache()
  local_clear_robotstxt_cache()
  vcr::use_cassette(
    "incomparable_get_shows",
    re_record_interval = 30L * 86400L,
    {
      out <- incomparable_get_shows(cache = FALSE)
    }
  )
  expect_s3_class(out, "tbl_df")
  expect_gte(nrow(out), 15)
  expect_named(
    out,
    c("show", "stats_url", "archive_url", "status"),
    ignore.order = TRUE
  )
  expect_true(all(out$status %in% c("active", "retired")))
})

test_that("incomparable_parse_archive returns a tibble", {
  local_isolated_cache()
  local_clear_robotstxt_cache()
  vcr::use_cassette(
    "incomparable_parse_archive-gameshow",
    re_record_interval = 30L * 86400L,
    {
      out <- incomparable_parse_archive(
        "https://www.theincomparable.com/gameshow/archive/"
      )
    }
  )
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0)
  expect_true(all(out$network == "The Incomparable"))
})

test_that("incomparable_parse_stats returns parsed durations", {
  local_isolated_cache()
  local_clear_robotstxt_cache()
  vcr::use_cassette(
    "incomparable_parse_stats-salvage",
    re_record_interval = 30L * 86400L,
    {
      out <- incomparable_parse_stats(
        "https://www.theincomparable.com/salvage/stats.txt"
      )
    }
  )
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0)
  expect_s3_class(out$duration, "hms")
  expect_s3_class(out$date, "Date")
})

test_that("incomparable_get_episodes works on a single-show input", {
  local_isolated_cache()
  local_clear_robotstxt_cache()
  vcr::use_cassette(
    "incomparable_get_episodes-one_show",
    re_record_interval = 30L * 86400L,
    {
      shows <- incomparable_get_shows(cache = FALSE)
      one <- shows |> dplyr::filter(.data$show == "Unjustly Maligned")
      out <- incomparable_get_episodes(one, cache = FALSE)
    }
  )
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0)
  # Derived columns and the network constant must be populated for every
  # row — even if a future re-record catches a stats/archive lag (see
  # combine_incomparable_episodes()). For Unjustly Maligned specifically
  # the show is retired so no lag is possible, but the assertions are
  # cheap and document the contract.
  expect_false(any(is.na(out$year)))
  expect_false(any(is.na(out$month)))
  expect_false(any(is.na(out$weekday)))
  expect_false(any(is.na(out$network)))
  expect_true(all(out$network == "The Incomparable"))
  expect_snapshot(glimpse_schema(out))
})
