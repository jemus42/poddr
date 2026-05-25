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
