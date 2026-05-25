test_that("atp_get_episodes(page_limit = 1) returns a well-shaped tibble", {
  local_isolated_cache()
  # Clear robotstxt in-memory cache so its robots.txt fetch is recorded
  # in every cassette independently (not skipped due to session-level caching).
  withr::defer(rm(
    list = ls(robotstxt:::rt_cache),
    envir = robotstxt:::rt_cache
  ))
  rm(list = ls(robotstxt:::rt_cache), envir = robotstxt:::rt_cache)

  vcr::use_cassette(
    "atp_get_episodes-page1",
    re_record_interval = 30L * 86400L,
    {
      out <- atp_get_episodes(page_limit = 1, cache = FALSE)
    }
  )

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
  expect_true(all(out$network == "ATP"))
  expect_true(all(out$show == "ATP"))
  expect_false(any(is.na(out$date)))
  expect_false(any(is.na(out$number)))
})

test_that("atp_get_episodes(page_limit = 1) writes no disk artifact", {
  local_isolated_cache()
  rm(list = ls(robotstxt:::rt_cache), envir = robotstxt:::rt_cache)

  tmp <- withr::local_tempdir()
  withr::local_dir(tmp)
  vcr::use_cassette(
    "atp_get_episodes-page1-nodisk",
    re_record_interval = 30L * 86400L,
    {
      atp_get_episodes(page_limit = 1, cache = FALSE)
    }
  )
  expect_false(dir.exists(file.path(tmp, "data_cache")))
})

test_that("atp_get_episodes schema snapshot is stable", {
  local_isolated_cache()
  rm(list = ls(robotstxt:::rt_cache), envir = robotstxt:::rt_cache)

  vcr::use_cassette(
    "atp_get_episodes-page1-schema",
    re_record_interval = 30L * 86400L,
    {
      out <- atp_get_episodes(page_limit = 1, cache = FALSE)
    }
  )
  expect_snapshot(glimpse_schema(out))
})
