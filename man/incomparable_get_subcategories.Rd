% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/incomparable.R
\name{incomparable_get_subcategories}
\alias{incomparable_get_subcategories}
\title{Extract subcategory index for given show}
\usage{
incomparable_get_subcategories(
  archive_url = "https://www.theincomparable.com/gameshow/archive/"
)
}
\arguments{
\item{archive_url}{E.g.
\code{"https://www.theincomparable.com/theincomparable/archive/"}.}
}
\value{
A tibble with subcategory links \code{link} and category name \code{category}
}
\description{
Not actively used in other functions but could come in handy.
}
\examples{
\dontrun{
incomparable_get_subcategories("https://www.theincomparable.com/gameshow/archive/")
}
}
