test_that("atp_get_episodes(page_limit = 1) is correct", {
  local_isolated_cache()
  local_clear_robotstxt_cache()

  tmp <- withr::local_tempdir()
  withr::local_dir(tmp)

  vcr::use_cassette(
    "atp_get_episodes-page1",
    re_record_interval = 30L * 86400L,
    {
      out <- atp_get_episodes(page_limit = 1, cache = FALSE)
    }
  )

  # Shape
  expect_s3_class(out, "tbl_df")
  expect_gt(nrow(out), 0)
  expect_named(
    out,
    c(
      "number",
      "title",
      "duration",
      "date",
      "year",
      "month",
      "weekday",
      "links",
      "n_links",
      "network",
      "show"
    ),
    ignore.order = TRUE
  )
  expect_s3_class(out$date, "Date")
  expect_s3_class(out$duration, "hms")

  # Static fields
  expect_true(all(out$network == "ATP"))
  expect_true(all(out$show == "ATP"))

  # No load-bearing NAs
  expect_false(any(is.na(out$date)))
  expect_false(any(is.na(out$number)))

  # No disk side effect
  expect_false(dir.exists(file.path(tmp, "data_cache")))

  # Schema snapshot (survives re-records — only captures names + classes)
  expect_snapshot(glimpse_schema(out))
})
