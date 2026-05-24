test_that("parse_duration handles HH:MM:SS and MM:SS", {
  expect_equal(as.numeric(parse_duration("01:02:03")), 3723)
  expect_equal(as.numeric(parse_duration("32:12")), 1932)
})

test_that("parse_duration is vectorised", {
  out <- parse_duration(c("00:30", "01:00:00"))
  expect_equal(as.numeric(out), c(30, 3600))
})

test_that("parse_duration errors on bad input", {
  expect_snapshot(parse_duration("nope"), error = TRUE)
})

test_that("label_n works on data and scalars", {
  expect_equal(label_n(100), "N = 100")
  expect_equal(label_n(100, brackets = TRUE), "(N = 100)")
  expect_equal(label_n(tibble::tibble(x = 1:10)), "N = 10")
})

test_that("label_n rejects unsupported input", {
  expect_snapshot(label_n("a"), error = TRUE)
  expect_snapshot(label_n(1:3), error = TRUE)
})

test_that("gather_people splits semicolon-separated names and trims whitespace", {
  episodes <- tibble::tibble(
    show = "S",
    number = "1",
    host = "Alice ; Bob",
    guest = "Carol"
  )
  out <- gather_people(episodes)
  expect_setequal(out$person, c("Alice", "Bob", "Carol"))
  expect_setequal(out$role, c("host", "guest"))
  expect_equal(nrow(out), 3)
})

test_that("gather_people works without guest column (relay shape)", {
  episodes <- tibble::tibble(show = "S", number = "1", host = "Alice;Bob")
  out <- gather_people(episodes)
  expect_setequal(out$person, c("Alice", "Bob"))
  expect_true(all(out$role == "host"))
})

test_that("gather_people drops NA people", {
  episodes <- tibble::tibble(
    show = "S",
    number = "1",
    host = "Alice",
    guest = NA_character_
  )
  out <- gather_people(episodes)
  expect_equal(out$person, "Alice")
})
