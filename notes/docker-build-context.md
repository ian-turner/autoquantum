# Docker Build Context

The Docker build context excludes `notes/`, local reference PDFs, `paper/`, and `tmp/` via `.dockerignore`, so research notes and paper artifacts are not copied by the Dockerfile's project-wide `COPY . /workspace/autoquantum` step.

The Docker image bakes Lean 4.29.0, Mathlib v4.29.0, comparator, `lean4export`, and `landrun` at build time. There is no separate Compose cache-warmer service in the current setup.

At runtime, Compose bind-mounts the repository and overlays `/workspace/autoquantum/lean/.lake` with an anonymous volume. That keeps the baked Lake package tree visible inside the container without depending on the host's `lean/.lake`.
