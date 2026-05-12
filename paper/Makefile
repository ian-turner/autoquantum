.PHONY: all paper ext-abstract clean

all: build/paper.pdf build/ext-abstract.pdf

paper: build/paper.pdf

ext-abstract: build/ext-abstract.pdf

build/paper.pdf: paper.tex refs.bib aaai2026.sty aaai2026.bst | build
	latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
		-outdir="build" "paper.tex"

build/ext-abstract.pdf: ext-abstract.tex refs.bib aaai2026.sty aaai2026.bst | build
	latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
		-outdir="build" "ext-abstract.tex"

build:
	mkdir -p "build"

clean:
	latexmk -C -outdir="build" "paper.tex" 2>/dev/null || true
	latexmk -C -outdir="build" "ext-abstract.tex" 2>/dev/null || true
