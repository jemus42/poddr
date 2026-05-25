test_that("poddr_get returns an xml_document for as = 'html'", {
  local_isolated_cache()
  vcr::use_cassette("poddr_get-html", re_record_interval = 30L * 86400L, {
    out <- poddr_get(
      "https://www.theincomparable.com/shows/",
      as = "html"
    )
  })
  expect_s3_class(out, "xml_document")
})

test_that("poddr_get returns a character body for as = 'text'", {
  local_isolated_cache()
  vcr::use_cassette("poddr_get-text", re_record_interval = 30L * 86400L, {
    out <- poddr_get(
      "https://www.theincomparable.com/salvage/stats.txt",
      as = "text"
    )
  })
  expect_type(out, "character")
  expect_gt(nchar(out), 0)
})

test_that("poddr_get validates `as`", {
  expect_error(
    poddr_get("https://example.com", as = "json"),
    class = "rlang_error"
  )
})
