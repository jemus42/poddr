#' Converting HH:MM:SS or MM:SS to `hms`
#'
#' @param x A duration
#'
#' @return A numeric of durations in `hms::hms()`.
#' @export
#' @note Only needed to parse durations in The Incomparable `stats.txt` files.
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
#' label_n(tibble::tibble(x = 1:10, y = 1:10), brackets = TRUE)
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

#' Gather episode datasets by people
#'
#' @param episodes A tbl containing `host` and `guest` columns, with names
#' separated by `;`.
#' @param people_cols FOr The Incomparable, use the default `c("host", "guest")`,
#' for relay.fm, there's only a `"host"` column.
#'
#' @return A tibble with new columns `"role"` and `"person"`, one row per person.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable <- incomparable_get_episodes(incomparable_get_shows())
#' incomparable_wide <- gather_people(incomparable)
#' }
gather_people <- function(episodes, people_cols = c("host", "guest")) {
  episodes %>%
    tidyr::pivot_longer(
      cols = people_cols,
      names_to = "role", values_to = "person"
    ) %>%
    tidyr::separate_rows(.data$person, sep = ";") %>%
    # hms gets converted to durations for some reason
    dplyr::mutate(dplyr::across(dplyr::any_of("duration"), hms::as_hms))
}


#
globalVariables(c(".", "guest", "host"))
