
<!-- README.md is generated from README.Rmd. Please edit that file -->

# poddr

<!-- badges: start -->

[![R-CMD-check](https://github.com/jemus42/poddr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jemus42/poddr/actions/workflows/R-CMD-check.yaml)
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

Here’s the bulk of what’s inside the tin:

``` r
library(dplyr, warn.conflicts = FALSE)
library(poddr)
```

### The Incomparable

The basic workflow is simple:

1.  Get a list of all the shows on the network, including the relevant
    URLs for further parsing.
2.  Get all the episodes of the shows selected. To not bother the
    webserver too much, I’m limiting the selection to a single show.

``` r
incomparable_shows <- incomparable_get_shows()
incomparable_shows
#> # A tibble: 55 × 4
#>    show                                   stats_url               archi…¹ status
#>    <chr>                                  <glue>                  <glue>  <chr> 
#>  1 A Complicated Profession               https://www.theincompa… https:… active
#>  2 Agents of SMOOCH                       https://www.theincompa… https:… active
#>  3 Beginner's Puck                        https://www.theincompa… https:… active
#>  4 Biff!                                  https://www.theincompa… https:… active
#>  5 Defocused                              https://www.theincompa… https:… active
#>  6 Doctor Who Flashcast                   https://www.theincompa… https:… active
#>  7 Dragonmount: The Wheel of Time Podcast https://www.theincompa… https:… active
#>  8 Football is Life                       https://www.theincompa… https:… active
#>  9 Game Show                              https://www.theincompa… https:… active
#> 10 I Want My M(CU)TV                      https://www.theincompa… https:… active
#> # … with 45 more rows, and abbreviated variable name ¹​archive_url

incomparable_episodes <- incomparable_shows |>
  filter(show == "Unjustly Maligned") |>
  incomparable_get_episodes()

incomparable_episodes
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
#> # … with 77 more rows, and 4 more variables: category <chr>, topic <chr>,
#> #   summary <chr>, network <chr>
```

### Relay.fm

Same procedure as before, also with one show.

``` r
relay_shows <- relay_get_shows()
relay_shows
#> # A tibble: 49 × 3
#>    show       feed_url                             show_status
#>    <chr>      <chr>                                <chr>      
#>  1 Analog(ue) https://www.relay.fm/analogue/feed   Active     
#>  2 Automators https://www.relay.fm/automators/feed Active     
#>  3 BONANZA    https://www.relay.fm/bonanza/feed    Active     
#>  4 B-Sides    https://www.relay.fm/b-sides/feed    Active     
#>  5 Clockwise  https://www.relay.fm/clockwise/feed  Active     
#>  6 Conduit    https://www.relay.fm/conduit/feed    Active     
#>  7 Connected  https://www.relay.fm/connected/feed  Active     
#>  8 Cortex     https://www.relay.fm/cortex/feed     Active     
#>  9 Departures https://www.relay.fm/departures/feed Active     
#> 10 Downstream https://www.relay.fm/downstream/feed Active     
#> # … with 39 more rows

relay_episodes <- relay_shows |>
  filter(show == "Connected") |>
  relay_get_episodes()

relay_episodes
#> # A tibble: 429 × 10
#>    show      number title  duration date        year month weekday host  network
#>    <chr>     <chr>  <chr>  <time>   <date>     <dbl> <ord> <ord>   <chr> <chr>  
#>  1 Connected 429    Lucy'… 00:58:56 2022-12-21  2022 Dece… Wednes… Jaso… relay.…
#>  2 Connected 428    Timer… 01:27:25 2022-12-15  2022 Dece… Thursd… Fede… relay.…
#>  3 Connected 427    Thera… 01:01:37 2022-12-07  2022 Dece… Wednes… Fede… relay.…
#>  4 Connected 426    Just … 01:23:18 2022-11-30  2022 Nove… Wednes… Fede… relay.…
#>  5 Connected 425    Inden… 00:56:00 2022-11-23  2022 Nove… Wednes… Fede… relay.…
#>  6 Connected 424    The C… 01:28:02 2022-11-16  2022 Nove… Wednes… Fede… relay.…
#>  7 Connected 423    I Kno… 01:39:22 2022-11-09  2022 Nove… Wednes… Fede… relay.…
#>  8 Connected 422    Rearr… 01:19:41 2022-11-02  2022 Nove… Wednes… Fede… relay.…
#>  9 Connected 421    The S… 01:32:51 2022-10-26  2022 Octo… Wednes… Fede… relay.…
#> 10 Connected 420    2 Reg… 01:30:49 2022-10-19  2022 Octo… Wednes… Fede… relay.…
#> # … with 419 more rows
```

### ATP

Since there’s only one show, there’s no reason to select one
specifically, obviously. However, the website doesn’t show a list of
*all* episodes on one page, so we’ll have to either parse all pages
(there’s currently 10 total as of December 2020), or select a limit,
like `1`, to only get episodes from the first page. The first page shows
the 5 most recent episodes, and subsequent pages show 50 episodes each.

``` r
atp <- atp_get_episodes(page_limit = 1)
atp
#> # A tibble: 5 × 9
#>   number title          duration date        year month weekday links    n_links
#>   <chr>  <chr>          <time>   <date>     <dbl> <ord> <ord>   <list>     <int>
#> 1 514    My Immense So… 01:45:25 2022-12-22  2022 Dece… Thursd… <tibble>      26
#> 2 513    Scribble on t… 02:09:32 2022-12-15  2022 Dece… Thursd… <tibble>      30
#> 3 512    Owned With a P 01:56:33 2022-12-08  2022 Dece… Thursd… <tibble>      24
#> 4 511    Moving to Ant… 01:50:29 2022-12-01  2022 Dece… Thursd… <tibble>      29
#> 5 510    It's Occupied… 02:09:12 2022-11-22  2022 Nove… Tuesday <tibble>      45

# Looking at the links
atp |>
  tidyr::unnest(links) |>
  select(number, title, link_text, link_url, link_type)
#> # A tibble: 154 × 5
#>    number title               link_text                          link_…¹ link_…²
#>    <chr>  <chr>               <chr>                              <chr>   <chr>  
#>  1 514    My Immense Softness x2 and k56flex                     https:… Showno…
#>  2 514    My Immense Softness Superbad                           https:… Showno…
#>  3 514    My Immense Softness DIVX                               https:… Showno…
#>  4 514    My Immense Softness Colima                             https:… Showno…
#>  5 514    My Immense Softness Apple is considering dropping the… https:… Showno…
#>  6 514    My Immense Softness Blink                              https:… Showno…
#>  7 514    My Immense Softness Gecko                              https:… Showno…
#>  8 514    My Immense Softness SR-71                              https:… Showno…
#>  9 514    My Immense Softness Trident II D5                      https:… Showno…
#> 10 514    My Immense Softness Inertial Navigation System         https:… Showno…
#> # … with 144 more rows, and abbreviated variable names ¹​link_url, ²​link_type
```

### For all the nice people

The regular episode data contains one row per episode, with associated
people in a single cell with names separated by `;`. In some cases we’re
interested in per-person data, for example the total number of
appearances of a person on The Incomparable mothership, so we’ll longify
the data with a helper function that performs the
`tidyr::pivot_longer()` and `tidyr::separate_rows()` steps consistently.

Note that relay.fm data only includes “hosts”, as there’s no separate
guest information, so the host/guest distinction is redundant in that
case.

``` r
incomparable_episodes |>
  gather_people() |>
  select(show, number, person, role)
#> # A tibble: 176 × 4
#>    show              number person            role 
#>    <chr>             <chr>  <chr>             <chr>
#>  1 Unjustly Maligned 87     Tony Sindelar     host 
#>  2 Unjustly Maligned 87     Antony Johnston   guest
#>  3 Unjustly Maligned 86     Antony Johnston   host 
#>  4 Unjustly Maligned 86     Andy Ihnatko      guest
#>  5 Unjustly Maligned 85     Antony Johnston   host 
#>  6 Unjustly Maligned 85     Eddy Webb         guest
#>  7 Unjustly Maligned 84     Antony Johnston   host 
#>  8 Unjustly Maligned 84     Jessica Sliwinski guest
#>  9 Unjustly Maligned 83     Antony Johnston   host 
#> 10 Unjustly Maligned 83     Marcos Huerta     guest
#> # … with 166 more rows

relay_episodes |>
  gather_people() |>
  select(show, number, person, role)
#> # A tibble: 1,285 × 4
#>    show      number person           role 
#>    <chr>     <chr>  <chr>            <chr>
#>  1 Connected 429    Jason Snell      host 
#>  2 Connected 428    Federico Viticci host 
#>  3 Connected 428    Stephen Hackett  host 
#>  4 Connected 428    Myke Hurley      host 
#>  5 Connected 427    Federico Viticci host 
#>  6 Connected 427    Stephen Hackett  host 
#>  7 Connected 427    Myke Hurley      host 
#>  8 Connected 426    Federico Viticci host 
#>  9 Connected 426    Stephen Hackett  host 
#> 10 Connected 426    Myke Hurley      host 
#> # … with 1,275 more rows
```
