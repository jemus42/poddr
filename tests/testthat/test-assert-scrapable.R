test_that("assert_scrapable returns TRUE invisibly when allowed", {
  # robotstxt fetches robots.txt; allow caching via withr-controlled tempdir
  withr::local_options(robotstxt_cache_dir = withr::local_tempdir())
  expect_invisible(
    out <- assert_scrapable("https://www.theincomparable.com/shows/")
  )
  expect_true(out)
})

test_that("assert_scrapable errors with cli class when disallowed", {
  # Force a denial by stubbing robotstxt::paths_allowed
  local_mocked_bindings(
    paths_allowed = function(...) FALSE,
    .package = "robotstxt"
  )
  expect_error(
    assert_scrapable("https://example.com/private"),
    class = "rlang_error"
  )
})
