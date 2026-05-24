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

default_user_agent <- function() {
  paste0(
    "poddr/",
    utils::packageVersion("poddr"),
    " (+https://github.com/jemus42/poddr)"
  )
}

.onLoad <- function(libname, pkgname) {
  op <- options()
  defaults <- list(
    poddr_user_agent = default_user_agent(),
    poddr_throttle_rate = 1 / 2,
    poddr_cache_dir = tools::R_user_dir("poddr", "cache"),
    poddr_cache_max_age = 7 * 86400,
    poddr_cache_max_size = 100 * 1024^2
  )
  toset <- !(names(defaults) %in% names(op))
  if (any(toset)) {
    options(defaults[toset])
  }
  invisible()
}
