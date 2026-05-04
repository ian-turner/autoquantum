.PHONY: all clean

all: build/main.pdf

build/main.pdf: main.tex refs.bib aaai2026.sty aaai2026.bst | build
	latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
		-outdir="build" "main.tex"

build:
	mkdir -p "build"

clean:
	latexmk -C -outdir="build" "main.tex" 2>/dev/null || true
