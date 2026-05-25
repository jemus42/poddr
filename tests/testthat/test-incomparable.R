test_that("parse_incomparable_archive_html parses one episode-list entry", {
  html <- rvest::read_html(
    '
    <html><body>
    <ul class="episode-list">
      <li>
        <span class="ep-num">42</span>
        <h5><a href="#">42 The Big One</a></h5>
        <div class="episode-date">August 15, 2024 at 12:00 pm</div>
        <div class="hosts"><a>Alice</a><a>Bob</a></div>
        <div class="episode-subtitle">Robots</div>
        <p>An episode about robots.</p>
      </li>
    </ul>
    </body></html>
  '
  )

  out <- parse_incomparable_archive_html(html)

  expect_equal(out$number, "42")
  expect_equal(out$title, "The Big One")
  expect_equal(out$date, as.Date("2024-08-15"))
  expect_equal(out$host, "Alice")
  expect_equal(out$guest, "Bob")
  expect_equal(out$topic, "Robots")
  expect_match(out$summary, "robots")
  expect_equal(out$network, "The Incomparable")
})

test_that("parse_incomparable_archive_html returns empty tibble on NULL input", {
  expect_equal(nrow(parse_incomparable_archive_html(NULL)), 0)
})

test_that("parse_incomparable_stats_text parses a stats.txt line", {
  text <- "001;01-08-2010;01:23:45;A title;Alice, Bob;Carol\n"
  out <- parse_incomparable_stats_text(text)

  expect_equal(out$number, "001")
  expect_equal(out$date, as.Date("2010-08-01"))
  expect_equal(as.numeric(out$duration), 3600 + 23 * 60 + 45)
  expect_equal(out$title, "A title")
  expect_equal(out$host, "Alice;Bob")
  expect_equal(out$guest, "Carol")
})

# Regression test for the latest-episode NA bug reported by the
# podcasts.jemu.name agent 2026-05-25: stats.txt updates faster than
# the archive page, so the newest episode appears in stats but not in
# archive. The full_join produces a stats-only row; year/month/weekday/
# network must be derived from the canonical date + a constant rather
# than inherited from a missing archive row.
test_that("combine_incomparable_episodes fills derived columns for episodes only in stats", {
  archived <- tibble::tibble(
    number = c("1", "2"),
    title = c("Old1", "Old2"),
    date = as.Date(c("2024-01-15", "2024-02-15")),
    year = c(2024L, 2024L),
    month = factor(c("January", "February"), ordered = TRUE),
    weekday = factor(c("Monday", "Thursday"), ordered = TRUE),
    host = c("A", "A"),
    guest = c("B", "C"),
    category = NA_character_,
    topic = c("t1", "t2"),
    summary = c("s1", "s2"),
    network = "The Incomparable"
  )
  stats <- tibble::tibble(
    number = c("1", "2", "3"),
    date = as.Date(c("2024-01-15", "2024-02-15", "2024-03-18")),
    duration = hms::hms(seconds = c(3600, 3600, 3600)),
    title = c("Old1", "Old2", "New3"),
    host = c("A", "A", "A"),
    guest = c("B", "C", "D")
  )

  out <- combine_incomparable_episodes("TestShow", stats, archived)

  expect_equal(nrow(out), 3)

  ep3 <- out[out$number == "3", ]
  expect_equal(ep3$year, 2024)
  expect_equal(as.character(ep3$month), "March")
  expect_equal(as.character(ep3$weekday), "Monday")
  expect_equal(ep3$network, "The Incomparable")
  expect_equal(ep3$title, "New3")
  expect_equal(ep3$show, "TestShow")
  # Genuinely archive-only fields stay NA for episodes the archive
  # hasn't listed yet — accurate, since we have no data for them.
  expect_true(is.na(ep3$category))
  expect_true(is.na(ep3$topic))
  expect_true(is.na(ep3$summary))
})

test_that("parse_incomparable_episode_html extracts summary from og:description", {
  html <- rvest::read_html(
    '<html><head>
    <meta property="og:description" content="An episode about robots.">
    </head><body><h2>Title here</h2></body></html>'
  )

  out <- parse_incomparable_episode_html(html)

  expect_equal(out$summary, "An episode about robots.")
  expect_true(is.na(out$topic))
})

test_that("parse_incomparable_episode_html picks up topic when present", {
  html <- rvest::read_html(
    '<html><head>
    <meta property="og:description" content="Some summary.">
    </head><body><span class="episode-subtitle">Segment Name</span></body></html>'
  )

  out <- parse_incomparable_episode_html(html)

  expect_equal(out$summary, "Some summary.")
  expect_equal(out$topic, "Segment Name")
})

test_that("parse_incomparable_episode_html returns NA tibble on NULL input", {
  out <- parse_incomparable_episode_html(NULL)
  expect_equal(nrow(out), 1)
  expect_true(is.na(out$summary))
  expect_true(is.na(out$topic))
})

test_that("fill_incomparable_archive_gap fetches per-episode pages for missing episodes", {
  archived <- tibble::tibble(
    number = c("1", "2"),
    title = c("Old1", "Old2"),
    date = as.Date(c("2024-01-15", "2024-02-15")),
    year = c(2024L, 2024L),
    month = factor(c("January", "February"), ordered = TRUE),
    weekday = factor(c("Monday", "Thursday"), ordered = TRUE),
    host = c("A", "A"),
    guest = c("B", "C"),
    category = NA_character_,
    topic = c("t1", "t2"),
    summary = c("s1", "s2"),
    network = "The Incomparable"
  )
  stats <- tibble::tibble(
    number = c("1", "2", "3"),
    date = as.Date(c("2024-01-15", "2024-02-15", "2024-03-18"))
  )

  testthat::local_mocked_bindings(
    incomparable_parse_episode = function(episode_url, cache = TRUE) {
      tibble::tibble(summary = "Episode 3 summary", topic = NA_character_)
    }
  )

  out <- fill_incomparable_archive_gap(
    archived,
    stats,
    "https://example.com/show/archive/"
  )

  expect_equal(nrow(out), 3)
  ep3 <- out[out$number == "3", ]
  expect_equal(ep3$summary, "Episode 3 summary")
  expect_true(is.na(ep3$topic))
  # Other archive-side columns stay NA on the gap row — combine() handles them
  expect_true(is.na(ep3$title))
  expect_true(is.na(ep3$category))
})

test_that("fill_incomparable_archive_gap is a no-op when archive is current", {
  archived <- tibble::tibble(
    number = c("1", "2"),
    title = c("A", "B"),
    summary = c("s1", "s2"),
    topic = c(NA_character_, NA_character_)
  )
  stats <- tibble::tibble(number = c("1", "2"))

  # Mock would error if called — verifies no fetch happens
  testthat::local_mocked_bindings(
    incomparable_parse_episode = function(...) {
      stop("Should not be called when archive is current")
    }
  )

  out <- fill_incomparable_archive_gap(
    archived,
    stats,
    "https://example.com/show/archive/"
  )

  expect_equal(out, archived)
})

test_that("combine_incomparable_episodes leaves matched episodes intact", {
  archived <- tibble::tibble(
    number = "1",
    title = "Old1",
    date = as.Date("2024-01-15"),
    year = 2024L,
    month = factor("January", ordered = TRUE),
    weekday = factor("Monday", ordered = TRUE),
    host = "Alice",
    guest = "Bob",
    category = "Some Cat",
    topic = "topical",
    summary = "summary text",
    network = "The Incomparable"
  )
  stats <- tibble::tibble(
    number = "1",
    date = as.Date("2024-01-15"),
    duration = hms::hms(seconds = 3600),
    title = "Old1",
    host = "Alice",
    guest = "Bob"
  )

  out <- combine_incomparable_episodes("S", stats, archived)

  expect_equal(nrow(out), 1)
  expect_equal(out$year, 2024)
  expect_equal(out$network, "The Incomparable")
  expect_equal(out$category, "Some Cat")
  expect_equal(out$topic, "topical")
  expect_equal(out$summary, "summary text")
})
