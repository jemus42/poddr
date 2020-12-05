
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
library(dplyr, warn.conflicts = FALSE)
library(poddr)
```

### The Incomparable

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
  filter(show %in% c("Unjustly Maligned", "A Legitimate Salvage")) %>%
  incomparable_get_episodes()

incomparable_episodes
#> # A tibble: 116 x 14
#>    show  number title duration date        year month weekday host  guest
#>    <chr> <chr>  <chr> <time>   <date>     <dbl> <ord> <ord>   <chr> <chr>
#>  1 A Le… 28     “Cib… 51'12"   2020-05-13  2020 May   Wednes… Chip… Warr…
#>  2 A Le… 27     “Sae… 32'13"   2020-04-27  2020 April Monday  Chip… Warr…
#>  3 A Le… 26     “The… 44'32"   2020-04-14  2020 April Tuesday Chip… Warr…
#>  4 A Le… 25     “A S… 35'48"   2020-03-18  2020 March Wednes… Kayt… Warr…
#>  5 A Le… 24     “Dis… 31'56"   2020-03-02  2020 March Monday  Chip… Warr…
#>  6 A Le… 23     “Opp… 41'49"   2020-02-10  2020 Febr… Monday  Jen … Warr…
#>  7 A Le… 22     “Ret… 32'16"   2020-01-23  2020 Janu… Thursd… Chip… Warr…
#>  8 A Le… 21     “Sub… 27'13"   2020-01-18  2020 Janu… Saturd… Chip… Warr…
#>  9 A Le… 20     “Jet… 45'26"   2020-01-02  2020 Janu… Thursd… Jen … Kayt…
#> 10 A Le… 19     “New… 40'27"   2019-12-22  2019 Dece… Sunday  Chip… Warr…
#> # … with 106 more rows, and 4 more variables: category <lgl>, topic <chr>,
#> #   summary <chr>, network <chr>
```

### Relay.fm

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
  filter(show %in% c("The Prompt", "Connected")) %>%
  relay_get_episodes()

relay_episodes
#> # A tibble: 380 x 10
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
#> # … with 370 more rows
```

### ATP

Only get the first page (5 episodes)

``` r
atp <- atp_get_episodes(page_limit = 1)
atp
#> # A tibble: 5 x 9
#>   number title         duration date        year month  weekday links    n_links
#>   <chr>  <chr>         <time>   <date>     <dbl> <ord>  <ord>   <list>     <int>
#> 1 407    It Isn't a B… 01:49:53 2020-12-03  2020 Decem… Thursd… <tibble…      24
#> 2 406    A Bomb on Yo… 02:36:18 2020-11-25  2020 Novem… Wednes… <tibble…      33
#> 3 405    The Benevole… 01:57:06 2020-11-18  2020 Novem… Wednes… <tibble…      29
#> 4 404    With Four Ha… 02:43:45 2020-11-11  2020 Novem… Wednes… <tibble…      31
#> 5 403    A VCR for th… 02:05:10 2020-11-05  2020 Novem… Thursd… <tibble…      38
```

### For all the nice people

``` r
incomparable_episodes %>%
  gather_people() %>%
  select(show, number, person, role)
#> # A tibble: 276 x 4
#>    show                 number person        role 
#>    <chr>                <chr>  <chr>         <chr>
#>  1 A Legitimate Salvage 28     Chip Sudderth host 
#>  2 A Legitimate Salvage 28     Warren Frey   guest
#>  3 A Legitimate Salvage 28     Kayti Burt    guest
#>  4 A Legitimate Salvage 28     Jen Burt      guest
#>  5 A Legitimate Salvage 27     Chip Sudderth host 
#>  6 A Legitimate Salvage 27     Warren Frey   guest
#>  7 A Legitimate Salvage 27     Kayti Burt    guest
#>  8 A Legitimate Salvage 27     Jen Burt      guest
#>  9 A Legitimate Salvage 26     Chip Sudderth host 
#> 10 A Legitimate Salvage 26     Warren Frey   guest
#> # … with 266 more rows

relay_episodes %>%
  gather_people(people_cols = "host") %>%
  select(show, number, person)
#> # A tibble: 1,140 x 3
#>    show      number person          
#>    <chr>     <chr>  <chr>           
#>  1 Connected 323    Federico Viticci
#>  2 Connected 323    Myke Hurley     
#>  3 Connected 323    Stephen Hackett 
#>  4 Connected 322    Federico Viticci
#>  5 Connected 322    Myke Hurley     
#>  6 Connected 322    Stephen Hackett 
#>  7 Connected 321    Federico Viticci
#>  8 Connected 321    Myke Hurley     
#>  9 Connected 321    Stephen Hackett 
#> 10 Connected 320    Federico Viticci
#> # … with 1,130 more rows
```