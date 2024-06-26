% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/relay.R
\name{relay_get_episodes}
\alias{relay_get_episodes}
\title{Retrieve all episodes for relay.fm shows}
\usage{
relay_get_episodes(relay_shows, cache = TRUE)
}
\arguments{
\item{relay_shows}{A tibble of shows, from \code{relay_get_shows()}.}

\item{cache}{(\code{logical(1)}) Set to \code{FALSE} to disable caching.}
}
\value{
A tibble.
}
\description{
Retrieves all episodes for one or more shows passed as a tibble.
}
\examples{
\dontrun{
relay_shows <- relay_get_shows()
relay <- relay_get_episodes(relay_shows)
}
}
