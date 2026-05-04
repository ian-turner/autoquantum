# Paper Build

The LaTeX paper build in `paper/Makefile` intentionally keeps the entrypoint
literal: `main.tex` builds to `build/main.pdf`.

Avoid reintroducing variables for the main document or build directory unless the
paper grows multiple build targets.

The Makefile assumes `latexmk` is installed and does not carry a manual
`pdflatex`/`bibtex` fallback.
