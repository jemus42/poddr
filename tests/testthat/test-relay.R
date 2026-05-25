test_that("parse_relay_feed_xml extracts titles, durations, dates, hosts", {
  xml <- xml2::read_xml(
    '
    <rss>
      <channel>
        <title>Connected</title>
        <item>
          <title>500: Look at That Camera Shake</title>
          <duration>3725</duration>
          <pubDate>Wed, 04 Dec 2024 12:00:00 GMT</pubDate>
          <author>Federico Viticci, Stephen Hackett and Myke Hurley</author>
        </item>
        <item>
          <title>499: Earlier Episode</title>
          <duration>3600</duration>
          <pubDate>Wed, 27 Nov 2024 12:00:00 GMT</pubDate>
          <author>Federico Viticci</author>
        </item>
      </channel>
    </rss>
  '
  )

  out <- parse_relay_feed_xml(xml)

  expect_s3_class(out, "tbl_df")
  expect_equal(out$show[1], "Connected")
  expect_equal(out$number, c("500", "499"))
  expect_equal(out$title, c("Look at That Camera Shake", "Earlier Episode"))
  expect_s3_class(out$duration, "hms")
  expect_equal(as.numeric(out$duration), c(3725, 3600))
  expect_s3_class(out$date, "Date")
  expect_equal(out$host[1], "Federico Viticci;Stephen Hackett;Myke Hurley")
  expect_equal(out$host[2], "Federico Viticci")
  expect_true(all(out$network == "relay.fm"))
})
