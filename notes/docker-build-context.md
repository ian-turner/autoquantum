# Docker Build Context

The Docker build context excludes `notes/` via `.dockerignore`, so the research wiki is not copied by the Dockerfile's project-wide `COPY . /workspace/autoquantum` step.

The `prove` OpenCode agent also starts from `lean_goal_context` directly and no longer has a required preflight read of `notes/home.md`.
