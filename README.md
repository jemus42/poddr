
<!-- README.md is generated from README.Rmd. Please edit that file -->

# poddr

<!-- badges: start -->

[![R-CMD-check](https://github.com/jemus42/poddr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jemus42/poddr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of poddr is to scrape episode metadata from The Incomparable,
relay.fm, and ATP and feed it to
[podcasts.jemu.name](https://podcasts.jemu.name/). It’s a personal
project — not aimed at a wider audience — but the code is open in case
anyone wants to peek under the hood.

## Installation

``` r
pak::pak("jemus42/poddr")
```

## How it works

Each podcast source has a small family of functions: one to list the
shows, one to fetch episodes for a given show (or show list), and a few
parsers exposed for direct use. All network requests go through a single
internal helper that handles per-host throttling, retries on transient
failures, and on-disk HTTP caching, so repeated calls and scheduled runs
don’t hammer upstream servers.

``` r
library(dplyr, warn.conflicts = FALSE)
library(poddr)
```

### The Incomparable

``` r
incomparable_shows <- incomparable_get_shows()
#>  www.theincomparable.com
incomparable_shows
#> # A tibble: 58 × 4
#>    show                                   stats_url           archive_url status
#>    <chr>                                  <glue>              <glue>      <chr> 
#>  1 A Complicated Profession               https://www.theinc… https://ww… active
#>  2 Agents of SMOOCH                       https://www.theinc… https://ww… active
#>  3 Biff!                                  https://www.theinc… https://ww… active
#>  4 Defocused                              https://www.theinc… https://ww… active
#>  5 Doctor Who Flashcast                   https://www.theinc… https://ww… active
#>  6 Dragonmount: The Wheel of Time Podcast https://www.theinc… https://ww… active
#>  7 Free the Squee                         https://www.theinc… https://ww… active
#>  8 Game Show                              https://www.theinc… https://ww… active
#>  9 Incomparable Radio Theater             https://www.theinc… https://ww… active
#> 10 Lazy Doctor Who                        https://www.theinc… https://ww… active
#> # ℹ 48 more rows

incomparable_get_episodes(
  incomparable_shows |> filter(show == "Unjustly Maligned")
)
#> # A tibble: 87 × 14
#>    show         number title duration date        year month weekday host  guest
#>    <chr>        <chr>  <chr> <time>   <date>     <dbl> <ord> <ord>   <chr> <chr>
#>  1 Unjustly Ma… 87     "\"L… 01:10:56 2017-09-25  2017 Sept… Monday  Tony… Anto…
#>  2 Unjustly Ma… 86     "\"R… 01:04:46 2017-09-12  2017 Sept… Tuesday Anto… Andy…
#>  3 Unjustly Ma… 85     "\"S… 01:07:47 2017-08-28  2017 Augu… Monday  Anto… Eddy…
#>  4 Unjustly Ma… 84     "\"T… 01:13:53 2017-08-14  2017 Augu… Monday  Anto… Jess…
#>  5 Unjustly Ma… 83     "\"P… 01:00:03 2017-07-31  2017 July  Monday  Anto… Marc…
#>  6 Unjustly Ma… 82     "\"P… 01:10:57 2017-07-17  2017 July  Monday  Anto… Ed B…
#>  7 Unjustly Ma… 81     "\"T… 01:10:42 2017-07-03  2017 July  Monday  Anto… Kell…
#>  8 Unjustly Ma… 80     "\"N… 01:24:24 2017-06-19  2017 June  Monday  Anto… Matt…
#>  9 Unjustly Ma… 79     "\"S… 01:15:33 2017-06-05  2017 June  Monday  Anto… Pete…
#> 10 Unjustly Ma… 78     "\"E… 01:16:40 2017-05-22  2017 May   Monday  Anto… Rich…
#> # ℹ 77 more rows
#> # ℹ 4 more variables: category <chr>, topic <chr>, summary <chr>, network <chr>
```

### relay.fm

``` r
relay_shows <- relay_get_shows()
#>  www.relay.fm
relay_shows
#> # A tibble: 48 × 3
#>    show            feed_url                             show_status
#>    <chr>           <chr>                                <chr>      
#>  1 Analog(ue)      https://www.relay.fm/analogue/feed   Active     
#>  2 BONANZA         https://www.relay.fm/bonanza/feed    Active     
#>  3 B-Sides         https://www.relay.fm/b-sides/feed    Active     
#>  4 Clockwise       https://www.relay.fm/clockwise/feed  Active     
#>  5 Conduit         https://www.relay.fm/conduit/feed    Active     
#>  6 Connected       https://www.relay.fm/connected/feed  Active     
#>  7 Cortex          https://www.relay.fm/cortex/feed     Active     
#>  8 Departures      https://www.relay.fm/departures/feed Active     
#>  9 Focused         https://www.relay.fm/focused/feed    Active     
#> 10 Mac Power Users https://www.relay.fm/mpu/feed        Active     
#> # ℹ 38 more rows

relay_get_episodes(relay_shows |> filter(show == "Connected"))
#> # A tibble: 604 × 10
#>    show      number title  duration date        year month weekday host  network
#>    <chr>     <chr>  <chr>  <time>   <date>     <dbl> <ord> <ord>   <chr> <chr>  
#>  1 Connected 604    The F… 01:17:56 2026-05-21  2026 May   Thursd… Fede… relay.…
#>  2 Connected 603    Ungra… 01:05:52 2026-05-14  2026 May   Thursd… Fede… relay.…
#>  3 Connected 602    Compu… 01:23:46 2026-05-07  2026 May   Thursd… Fede… relay.…
#>  4 Connected 601    I Lov… 01:49:35 2026-04-30  2026 April Thursd… Fede… relay.…
#>  5 Connected 600    Tommy… 01:33:13 2026-04-23  2026 April Thursd… Fede… relay.…
#>  6 Connected 599    Then … 01:27:33 2026-04-16  2026 April Thursd… Fede… relay.…
#>  7 Connected 598    8TB o… 01:37:30 2026-04-09  2026 April Thursd… Fede… relay.…
#>  8 Connected 597    S-Tie… 01:01:52 2026-04-02  2026 April Thursd… Fede… relay.…
#>  9 Connected 596    Somet… 01:03:23 2026-03-26  2026 March Thursd… Fede… relay.…
#> 10 Connected 595    Feder… 01:06:44 2026-03-19  2026 March Thursd… Fede… relay.…
#> # ℹ 594 more rows
```

### ATP

``` r
atp <- atp_get_episodes(page_limit = 1)
#> atp.fm
#> Warning in request_handler_handler(request = request, handler = on_not_found, :
#> Event: on_not_found
#> Warning in request_handler_handler(request = request, handler =
#> on_file_type_mismatch, : Event: on_file_type_mismatch
#> Warning in request_handler_handler(request = request, handler =
#> on_suspect_content, : Event: on_suspect_content
#> 
atp |>
  tidyr::unnest(links) |>
  select(number, title, link_text, link_url, link_type)
#> # A tibble: 166 × 5
#>    number title            link_text                          link_url link_type
#>    <chr>  <chr>            <chr>                              <chr>    <chr>    
#>  1 692    A Thinking Hitch ATP Member                         https:/… Shownotes
#>  2 692    A Thinking Hitch ATP Movie Club: Her                https:/… Shownotes
#>  3 692    A Thinking Hitch Real Madrid: The Weight of Greatn… https:/… Shownotes
#>  4 692    A Thinking Hitch tcsh                               https:/… Shownotes
#>  5 692    A Thinking Hitch John’s Terminal settings Window t… https:/… Shownotes
#>  6 692    A Thinking Hitch John’s Terminal settings Tab tab   https:/… Shownotes
#>  7 692    A Thinking Hitch Escape sequence extended tooltip   https:/… Shownotes
#>  8 692    A Thinking Hitch .cshrc                             https:/… Shownotes
#>  9 692    A Thinking Hitch Starship                           https:/… Shownotes
#> 10 692    A Thinking Hitch KornShell                          https:/… Shownotes
#> # ℹ 156 more rows
```

### Caching what you fetched

The orchestrators return tibbles and don’t touch disk. If you want
RDS/CSV files written to a directory, call `cache_podcast_data()`
explicitly:

``` r
atp |> cache_podcast_data(dir = "data_cache", filename = "atp", csv = TRUE)
```

`update_cached_data()` is a convenience that fetches everything and
writes everything; it’s what the scheduled GitHub Action uses.

### Per-person view

``` r
relay_get_episodes(relay_shows |> filter(show == "Connected")) |>
  gather_people() |>
  select(show, number, person, role)
#> # A tibble: 1,800 × 4
#>    show      number person           role 
#>    <chr>     <chr>  <chr>            <chr>
#>  1 Connected 604    Federico Viticci host 
#>  2 Connected 604    Stephen Hackett  host 
#>  3 Connected 604    Myke Hurley      host 
#>  4 Connected 603    Federico Viticci host 
#>  5 Connected 603    Stephen Hackett  host 
#>  6 Connected 603    Myke Hurley      host 
#>  7 Connected 602    Federico Viticci host 
#>  8 Connected 602    Stephen Hackett  host 
#>  9 Connected 602    Myke Hurley      host 
#> 10 Connected 601    Federico Viticci host 
#> # ℹ 1,790 more rows
```
