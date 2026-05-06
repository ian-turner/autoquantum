# Paper Bibliography Setup

The `paper/` LaTeX source uses the AAAI 2026 style's built-in BibTeX path:
`main.tex` loads `natbib`, `aaai2026.sty` sets `\bibliographystyle{aaai2026}`,
and the document ends with `\bibliography{refs}`. The local `paper/aaai2026.bst`
was copied from `tmp/AuthorKit26/AnonymousSubmission/LaTeX/aaai2026.bst` so
BibTeX can resolve that style name during local builds.

References should be added to `paper/refs.bib` and cited with standard natbib
commands such as `\citep{key}` or `\citet{key}`. The `paper/Makefile`
includes `refs.bib` as a dependency and delegates the full LaTeX/BibTeX cycle
to `latexmk`; there is no manual `pdflatex`/`bibtex` fallback path.
