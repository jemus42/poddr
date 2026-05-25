test_that("assert_scrapable returns TRUE invisibly when allowed", {
  local_mocked_bindings(
    paths_allowed = function(...) TRUE,
    .package = "robotstxt"
  )
  expect_invisible(
    out <- assert_scrapable("https://www.theincomparable.com/shows/")
  )
  expect_true(out)
})

test_that("assert_scrapable errors with cli class when disallowed", {
  local_mocked_bindings(
    paths_allowed = function(...) FALSE,
    .package = "robotstxt"
  )
  expect_error(
    assert_scrapable("https://example.com/private"),
    class = "rlang_error"
  )
})
