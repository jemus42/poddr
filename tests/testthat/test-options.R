test_that(".onLoad sets package option defaults", {
  expect_match(getOption("poddr_user_agent"), "^poddr/")
  expect_equal(getOption("poddr_throttle_rate"), 1 / 2)
  expect_equal(getOption("poddr_cache_max_age"), 7 * 86400)
  expect_equal(getOption("poddr_cache_max_size"), 100 * 1024^2)
  expect_match(
    getOption("poddr_cache_dir"),
    "poddr",
    fixed = TRUE
  )
})

test_that("default_user_agent reports package version and URL", {
  ua <- default_user_agent()
  expect_match(ua, paste0("poddr/", utils::packageVersion("poddr")))
  expect_match(ua, "github.com/jemus42/poddr", fixed = TRUE)
})
