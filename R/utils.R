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
  seconds <- vapply(x, \(.x) {
    if (stringr::str_count(.x, ":") == 2) {
      xx <- as.numeric(unlist(stringr::str_split(.x, ":")))
      xx[1] * 3600 + xx[2] * 60 + xx[3]
    } else if (stringr::str_count(.x, ":") == 1) {
      xx <- as.numeric(unlist(stringr::str_split(.x, ":")))
      xx[1] * 60 + xx[2]
    } else {
      stop("Unexpected input format ", .x)
    }
  }, numeric(1))

  hms::hms(seconds = seconds)
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
#' A thin wrapper around `tidyr::pivot_longer()` and `tidyr::separate_rows()`.
#'
#' @param episodes A tibble containing `host` and `guest` columns, with names
#' separated by `;`.
#'
#' @return A tibble with new columns `"role"` and `"person"`, one row per person.
#' @export
#'
#' @examples
#' \dontrun{
#' incomparable <- incomparable_get_episodes(incomparable_get_shows())
#' incomparable_wide <- gather_people(incomparable)
#' }
gather_people <- function(episodes) {

  # Get people cols, as relay doesn't have guests
  people_cols <- names(episodes)[names(episodes) %in% c("host", "guest")]

  episodes |>
    tidyr::pivot_longer(
      cols = people_cols,
      names_to = "role", values_to = "person"
    ) |>
    tidyr::separate_rows(.data$person, sep = ";") |>
    # Just in case of superfluous whitespaces
    dplyr::mutate(person = stringr::str_trim(.data$person, side = "both")) |>
    # hms gets converted to durations for some reason
    dplyr::mutate(dplyr::across(dplyr::any_of("duration"), hms::as_hms)) |>
    dplyr::filter(!is.na(.data$person))
}
