
<!-- README.md is generated from README.Rmd. Please edit that file -->

# poddr

<!-- badges: start -->

[![R build
status](https://github.com/jemus42/poddr/workflows/R-CMD-check/badge.svg)](https://github.com/jemus42/poddr/actions)
<!-- badges: end -->

The goal of poddr is to collect podcast data so I can display it at
[podcasts.jemu.name](https://podcasts.jemu.name/). It’s not intended to
be a real package for real people.

## Installation

You can install the released version of poddr from here with:

``` r
remotes::install_github("jemus42/poddr")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(dplyr)
library(poddr)

relay_shows <- relay_get_shows()
incomparable_shows <- incomparable_get_shows()

glimpse(relay_shows)
glimpse(incomparable_shows)

relay_episodes <- relay_get_episodes(relay_shows)
incomparable_episodes <- incomparable_get_episodes(incomparable_shows)
atp <- atp_get_episodes()
```
