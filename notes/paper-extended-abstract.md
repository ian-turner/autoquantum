# Paper Extended Abstract

Initial paper scaffold lives in `paper/`.

- `paper/main.tex` is derived from the AAAI 2026 anonymous submission LaTeX template, with the fixed `DO NOT CHANGE` preamble lines preserved.
- `paper/Makefile` writes LaTeX build artifacts into `paper/build/`; run `make -C paper`.
- `paper/aaai2026.sty` was copied from the anonymous-submission LaTeX author kit under `tmp/AuthorKit26/AnonymousSubmission/LaTeX/`.
- `paper/` is excluded from Docker image build context, but remains visible through the normal development bind mount.
- Current paper title: "Agentic Engineering for Automating Quantum Algorithm Design".
- The draft should stay short until the core architecture and example contribution are clear.
