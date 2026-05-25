test_that("cache_podcast_data writes RDS to the supplied dir", {
  tmp <- withr::local_tempdir()
  data <- tibble::tibble(a = 1:3, b = letters[1:3])

  cache_podcast_data(data, dir = tmp, filename = "demo", csv = FALSE)

  expect_true(file.exists(file.path(tmp, "demo.rds")))
  expect_equal(readRDS(file.path(tmp, "demo.rds")), data)
})

test_that("cache_podcast_data also writes CSV when csv = TRUE", {
  tmp <- withr::local_tempdir()
  data <- tibble::tibble(a = 1:3, b = letters[1:3])

  cache_podcast_data(data, dir = tmp, filename = "demo", csv = TRUE)

  expect_true(file.exists(file.path(tmp, "demo.csv")))
})

test_that("cache_podcast_data returns NULL on empty input", {
  tmp <- withr::local_tempdir()
  expect_null(
    cache_podcast_data(tibble::tibble(), dir = tmp, filename = "demo")
  )
  expect_false(file.exists(file.path(tmp, "demo.rds")))
})

test_that("cache_podcast_data default dir uses here::here()", {
  # The default formal should be the unevaluated call here::here("data_cache"),
  # not the literal string "data_cache". This pins the working-directory
  # independence change.
  expect_equal(
    formals(cache_podcast_data)$dir,
    quote(here::here("data_cache"))
  )
})

test_that("update_cached_data default dir uses here::here()", {
  expect_equal(
    formals(update_cached_data)$dir,
    quote(here::here("data_cache"))
  )
})
