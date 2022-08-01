# poddr 0.2.2

*  [Incomparable] Add safety check in case an archive page returns `500` and is not parseable.
*  [Incomparable] Slightly improve date parsing from archive pages. 

# poddr 0.2.1

* [Incomparable] Fix missing subcategory handling for the mothership, game show and some others.

# poddr 0.2.0

* [Incomparable] Update for the new [Incomparable website](https://www.theincomparable.com/) in June 2022.  
  * Some information like sub-categories for the mothership (Book Club, Old Movie Club etc.) are not yet recovered though.

# poddr 0.1.1

* [Incomparable] Fix bug where empty show archive pages broke the whole episode gathering.
  * Yields message such as `Empty archive page for Doctor Who Flashcast at https://www.theincomparable.com/dwf/archive/`

# poddr 0.1.0

* Add `pkgdown` site.
* Pass R CMD check.
* Add functions to get episodes from The Incomparable, relay.fm and ATP.
* Added a `NEWS.md` file to track changes to the package.
