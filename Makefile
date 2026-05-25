.PHONY: format doc check test coverage build install site release clean

format:
	air format .

doc:
	Rscript -e 'devtools::document()'

check: doc
	Rscript -e 'devtools::check()'

test:
	Rscript -e 'devtools::test()'

coverage:
	Rscript -e 'covr::report()'

build: doc
	Rscript -e 'devtools::build()'

install: doc
	Rscript -e 'devtools::install()'

site: doc
	Rscript -e 'pkgdown::build_site()'

release: check
	Rscript -e 'devtools::release()'

clean:
	rm -rf docs/index.html docs/reference docs/articles docs/news docs/authors.html docs/404.html docs/sitemap.xml docs/pkgdown.yml docs/search.json
