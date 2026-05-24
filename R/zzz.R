podcast_urls <- list(
  incomparable = list(
    base = "https://www.theincomparable.com",
    shows = "https://www.theincomparable.com/shows/"
  ),
  relay = list(
    base = "https://www.relay.fm/",
    shows = "https://www.relay.fm/shows"
  ),
  atp = list(
    base = "https://atp.fm"
  )
)

# Rate-limited readr::read_delim wrapper. Built in .onLoad so the memoise
# cache is fresh per session; polite::politely enforces robots.txt + delay.
polite_read_delim <- NULL

.onLoad <- function(libname, pkgname) {
  polite_read_delim <<- polite::politely(readr::read_delim, verbose = FALSE)
}
