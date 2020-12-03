#' Converting HH:MM:SS or MM:SS to `hms`
#'
#' @param x A duration
#'
#' @return A numeric of durations in `hms::hms()`.
#' @export
#'
#' @examples
#' parse_duration("32:12")
#' parse_duration("32:12:04")
parse_duration <- function(x) {
  purrr::map_dbl(x, ~ {
    if (stringr::str_count(.x, ":") == 2) {
      xx <- as.numeric(unlist(stringr::str_split(.x, ":")))
      hms::hms(
        seconds = xx[3],
        minutes = xx[2],
        hours = xx[1]
      )
    } else if (stringr::str_count(.x, ":") == 1) {
      xx <- as.numeric(unlist(stringr::str_split(.x, ":")))
      hms::hms(
        seconds = xx[2],
        minutes = xx[1]
      )
    } else {
      stop("Unexpected input format ", .x)
    }
  }) %>%
    hms::hms(seconds = .)
}

#' Convenience function to display N
#'
#' @param x Data or singular value.
#' @param brackets Set `TRUE` to enclose result in `( )`.
#'
#' @return A character of length 1.
#' @export
#'
#' @examples
#' label_n(100)
#' label_n(tibble(x = 1:10, y = 1:10), brackets = TRUE)
label_n <- function(x, brackets = FALSE) {
  if (is.data.frame(x)) {
    n <- nrow(x)
  } else if (is.numeric(x) & length(x) == 1) {
    n <- x
  } else {
    stop("'x' must be a data.frame or a numeric vector of length 1")
  }
  ret <- paste0("N = ", n)
  if (brackets) {
    ret <- paste0("(", ret, ")")
  }
  ret
}
