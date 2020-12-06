
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
#> # A tibble: 45 x 3
#>    show          stats_url                       archive_url                    
#>    <chr>         <glue>                          <glue>                         
#>  1 A Legitimate… https://www.theincomparable.co… https://www.theincomparable.co…
#>  2 Afoot         https://www.theincomparable.co… https://www.theincomparable.co…
#>  3 Agents of SM… https://www.theincomparable.co… https://www.theincomparable.co…
#>  4 Batman Unive… https://www.theincomparable.co… https://www.theincomparable.co…
#>  5 Bear Left (R… https://www.theincomparable.co… https://www.theincomparable.co…
#>  6 Beginner's P… https://www.theincomparable.co… https://www.theincomparable.co…
#>  7 Biff!         https://www.theincomparable.co… https://www.theincomparable.co…
#>  8 Bonus Track   https://www.theincomparable.co… https://www.theincomparable.co…
#>  9 Cartoon Cast  https://www.theincomparable.co… https://www.theincomparable.co…
#> 10 Chick Flick … https://www.theincomparable.co… https://www.theincomparable.co…
#> # … with 35 more rows

incomparable_episodes <- incomparable_shows %>%
  filter(show == "Unjustly Maligned") %>%
  incomparable_get_episodes()

incomparable_episodes
#> # A tibble: 87 x 14
#>    show  number title duration date        year month weekday host  guest
#>    <chr> <chr>  <chr> <time>   <date>     <dbl> <ord> <ord>   <chr> <chr>
#>  1 Unju… 87     "\"L… 01:10:56 2017-09-25  2017 Sept… Monday  Tony… Anto…
#>  2 Unju… 86     "\"R… 01:04:46 2017-09-12  2017 Sept… Tuesday Anto… Andy…
#>  3 Unju… 85     "\"S… 01:07:47 2017-08-28  2017 Augu… Monday  Anto… Eddy…
#>  4 Unju… 84     "\"T… 01:13:53 2017-08-14  2017 Augu… Monday  Anto… Jess…
#>  5 Unju… 83     "\"P… 01:00:03 2017-07-31  2017 July  Monday  Anto… Marc…
#>  6 Unju… 82     "\"P… 01:10:57 2017-07-17  2017 July  Monday  Anto… Ed B…
#>  7 Unju… 81     "\"T… 01:10:42 2017-07-03  2017 July  Monday  Anto… Kell…
#>  8 Unju… 80     "\"N… 01:24:24 2017-06-19  2017 June  Monday  Anto… Matt…
#>  9 Unju… 79     "\"S… 01:15:33 2017-06-05  2017 June  Monday  Anto… Pete…
#> 10 Unju… 78     "\"E… 01:16:40 2017-05-22  2017 May   Monday  Anto… Rich…
#> # … with 77 more rows, and 4 more variables: category <lgl>, topic <chr>,
#> #   summary <chr>, network <chr>
```

### Relay.fm

Same procedure as before, also with one show.

``` r
relay_shows <- relay_get_shows()
relay_shows
#> # A tibble: 46 x 3
#>    show             feed_url                             show_status
#>    <chr>            <chr>                                <chr>      
#>  1 20 Macs for 2020 https://www.relay.fm/20macs/feed     Active     
#>  2 Adapt            https://www.relay.fm/adapt/feed      Active     
#>  3 Analog(ue)       https://www.relay.fm/analogue/feed   Active     
#>  4 Automators       https://www.relay.fm/automators/feed Active     
#>  5 BONANZA          https://www.relay.fm/bonanza/feed    Active     
#>  6 B-Sides          https://www.relay.fm/b-sides/feed    Active     
#>  7 Clockwise        https://www.relay.fm/clockwise/feed  Active     
#>  8 Connected        https://www.relay.fm/connected/feed  Active     
#>  9 Cortex           https://www.relay.fm/cortex/feed     Active     
#> 10 Departures       https://www.relay.fm/departures/feed Active     
#> # … with 36 more rows

relay_episodes <- relay_shows %>%
  filter(show == "Connected") %>%
  relay_get_episodes()

relay_episodes
#> # A tibble: 323 x 10
#>    show   number title   duration date        year month weekday host    network
#>    <chr>  <chr>  <chr>   <time>   <date>     <dbl> <ord> <ord>   <chr>   <chr>  
#>  1 Conne… 323    Artisa… 01:43:44 2020-12-02  2020 Dece… Wednes… Federi… relay.…
#>  2 Conne… 322    ismh@h… 01:39:06 2020-11-25  2020 Nove… Wednes… Federi… relay.…
#>  3 Conne… 321    Friend… 02:11:32 2020-11-19  2020 Nove… Thursd… Federi… relay.…
#>  4 Conne… 320    Actual… 01:24:25 2020-11-11  2020 Nove… Wednes… Federi… relay.…
#>  5 Conne… 319    The Ri… 01:53:41 2020-11-04  2020 Nove… Wednes… Federi… relay.…
#>  6 Conne… 318    Come O… 01:49:35 2020-10-28  2020 Octo… Wednes… Federi… relay.…
#>  7 Conne… 317    Captai… 01:31:28 2020-10-21  2020 Octo… Wednes… Federi… relay.…
#>  8 Conne… 316    I Over… 01:48:38 2020-10-14  2020 Octo… Wednes… Federi… relay.…
#>  9 Conne… 315    The Ri… 01:35:32 2020-10-07  2020 Octo… Wednes… Federi… relay.…
#> 10 Conne… 314    The Je… 01:30:59 2020-09-30  2020 Sept… Wednes… Federi… relay.…
#> # … with 313 more rows
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
#> # A tibble: 5 x 9
#>   number title         duration date        year month  weekday links    n_links
#>   <chr>  <chr>         <time>   <date>     <dbl> <ord>  <ord>   <list>     <int>
#> 1 407    It Isn't a B… 01:49:53 2020-12-03  2020 Decem… Thursd… <tibble…      24
#> 2 406    A Bomb on Yo… 02:36:18 2020-11-25  2020 Novem… Wednes… <tibble…      32
#> 3 405    The Benevole… 01:57:06 2020-11-18  2020 Novem… Wednes… <tibble…      28
#> 4 404    With Four Ha… 02:43:45 2020-11-11  2020 Novem… Wednes… <tibble…      30
#> 5 403    A VCR for th… 02:05:10 2020-11-05  2020 Novem… Thursd… <tibble…      33

# Looking at the links
atp %>%
  tidyr::unnest(links) %>%
  select(number, title, link_text, link_url, link_type)
#> # A tibble: 147 x 5
#>    number title       link_text            link_url                    link_type
#>    <chr>  <chr>       <chr>                <chr>                       <chr>    
#>  1 407    It Isn't a… here                 https://www.icloud.com/set… Shownotes
#>  2 407    It Isn't a… Ryan Fegley          https://twitter.com/ryanfe… Shownotes
#>  3 407    It Isn't a… probably just uses … https://machinelearning.ap… Shownotes
#>  4 407    It Isn't a… @hishnash            https://twitter.com/hishna… Shownotes
#>  5 407    It Isn't a… Die size spreadsheet https://docs.google.com/sp… Shownotes
#>  6 407    It Isn't a… Cerebras             https://www.cerebras.net/   Shownotes
#>  7 407    It Isn't a… Memory interface ba… https://en.wikipedia.org/w… Shownotes
#>  8 407    It Isn't a… TMSC Achieves Break… https://www.techpowerup.co… Shownotes
#>  9 407    It Isn't a… What is “risk produ… https://news.ycombinator.c… Shownotes
#> 10 407    It Isn't a… virtualizes ARM Win… https://the8-bit.com/devel… Shownotes
#> # … with 137 more rows
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
incomparable_episodes %>%
  gather_people() %>%
  select(show, number, person, role)
#> # A tibble: 176 x 4
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

relay_episodes %>%
  gather_people() %>%
  select(show, number, person, role)
#> # A tibble: 969 x 4
#>    show      number person           role 
#>    <chr>     <chr>  <chr>            <chr>
#>  1 Connected 323    Federico Viticci host 
#>  2 Connected 323    Myke Hurley      host 
#>  3 Connected 323    Stephen Hackett  host 
#>  4 Connected 322    Federico Viticci host 
#>  5 Connected 322    Myke Hurley      host 
#>  6 Connected 322    Stephen Hackett  host 
#>  7 Connected 321    Federico Viticci host 
#>  8 Connected 321    Myke Hurley      host 
#>  9 Connected 321    Stephen Hackett  host 
#> 10 Connected 320    Federico Viticci host 
#> # … with 959 more rows
```
