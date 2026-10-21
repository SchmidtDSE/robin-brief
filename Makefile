# One source (content/brief.md) → PDF via Typst, and the GitHub Pages site in docs/.
#   make          build both
#   make draft    PDF with the internal-review box and DRAFT marker
#   make watch    rebuild on save (needs `brew install watchexec`)
#   make serve    preview the site at http://localhost:8000

SRC     := content/brief.md
FILTER  := filters/robin.lua
PANDOC  := pandoc $(SRC) -f markdown --lua-filter $(FILTER)
TYPST   := typst compile --root . --font-path fonts
FIGS    := $(wildcard figures/*.svg figures/appendix/*)

.PHONY: all pdf draft site watch serve clean

all: pdf site

pdf: robin-brief.pdf

build/brief.typ: $(SRC) $(FILTER) templates/brief.typ
	@mkdir -p build
	$(PANDOC) -t typst --template templates/brief.typ $(PANDOC_ARGS) -o $@

robin-brief.pdf: build/brief.typ typst/theme.typ $(FIGS) $(wildcard fonts/*)
	$(TYPST) build/brief.typ $@

draft:
	$(MAKE) -B pdf PANDOC_ARGS="-M draft=true"

site: pdf
	mkdir -p docs/figures build/web
	for j in content/hotspots/*.json; do \
		n=$$(basename $$j .json); \
		python3 scripts/web_svg.py $$(ls figures/$$n.svg figures/appendix/$$n.svg 2>/dev/null | head -1) $$j build/web/$$n.svg; \
	done
	$(PANDOC) -t html5 --template templates/index.html --section-divs --syntax-highlighting=none \
		-M css-version=$$(shasum templates/style.css | cut -c1-8) -o docs/index.html
	cp templates/style.css docs/style.css
	cp figures/*.png figures/appendix/*.png docs/figures/
	for f in figures/appendix/*.svg; do \
		png=docs/figures/$$(basename $$f .svg).png; \
		[ -f figures/appendix/$$(basename $$f .svg).png ] || rsvg-convert -w 2000 -b white $$f -o $$png; \
	done
	cp robin-brief.pdf docs/robin-brief.pdf
	touch docs/.nojekyll

watch:
	watchexec -w content -w filters -w templates -w typst -w figures -- make all

serve:
	python3 -m http.server -d docs 8000

clean:
	rm -rf build robin-brief.pdf docs
