# Paper

## Overview

The paper scaffold lives in `paper/`. Current title: "Agentic Engineering for Automating Quantum Algorithm Design".

- `paper/main.tex` — derived from the AAAI 2026 anonymous submission template; the fixed `DO NOT CHANGE` preamble lines are preserved.
- `paper/Makefile` — writes LaTeX build artifacts into `paper/build/`; run `make -C paper`.
- `paper/aaai2026.sty` — copied from the anonymous-submission author kit under `tmp/AuthorKit26/AnonymousSubmission/LaTeX/`.
- `paper/` is excluded from the Docker image build context (via `.dockerignore`) but is visible through the normal bind mount.

Keep the draft short until the core architecture and example contribution are clear.

## Build

The Makefile uses `latexmk`; there is no manual `pdflatex`/`bibtex` fallback. The entrypoint is `main.tex` → `build/main.pdf`. Avoid introducing variables for the main document or build directory unless multiple build targets are needed.

## Bibliography

`main.tex` loads `natbib`; `aaai2026.sty` sets `\bibliographystyle{aaai2026}`. The document ends with `\bibliography{refs}`. The local `paper/aaai2026.bst` was copied from the author kit so BibTeX can resolve the style name during local builds.

Add references to `paper/refs.bib` and cite with `\citep{key}` or `\citet{key}`. The Makefile lists `refs.bib` as a dependency and delegates the full LaTeX/BibTeX cycle to `latexmk`.
