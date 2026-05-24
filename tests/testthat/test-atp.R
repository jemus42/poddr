test_that("atp_parse_page parses a minimal article", {
  html <- paste(
    "<html><body>",
    "<article>",
    "<div class='metadata'>December 12, 2024\n01:02:03</div>",
    "<h2><a href='#'>123: Episode Title</a></h2>",
    "<ul><li><a href='https://example.com'>Note link</a></li></ul>",
    "<ul><li><a href='https://sponsor.example'>Sponsor link</a></li></ul>",
    "</article>",
    "</body></html>",
    sep = ""
  )
  page <- rvest::read_html(html)
  out <- atp_parse_page(page)

  expect_equal(out$number, "123")
  expect_equal(out$title, "Episode Title")
  expect_equal(as.character(out$duration), "01:02:03")
  expect_equal(out$date, as.Date("2024-12-12"))
  expect_equal(out$n_links, 2L)
})

test_that("atp_parse_page skips members-only posts", {
  html <- paste(
    "<html><body>",
    "<article>",
    "<div class='membersonlypromo'>members</div>",
    "</article>",
    "</body></html>",
    sep = ""
  )
  page <- rvest::read_html(html)
  out <- atp_parse_page(page)
  expect_equal(nrow(out), 0)
})
