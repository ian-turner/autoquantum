# Docker Cache Layout

Updated: 2026-04-25

## Current split

- `autoquantum-elan-cache` is a Docker volume mounted read-write into `cache-warmer` and read-only into `opencode`.
- `autoquantum-mathlib-cache` is a Docker volume mounted read-write into `cache-warmer` and read-only into `opencode` at `/home/opencode/.cache/lake-packages-seed`.
- `autoquantum-comparator-cache` is a Docker volume mounted read-write into `cache-warmer` and read-only into `opencode` at `/home/opencode/.cache/autoquantum-tools`.
- `opencode` mounts an anonymous writable volume at `/workspace/autoquantum/lean/.lake/packages` and seeds it from the shared read-only package cache on first start.
- `/home/opencode/.cache/opencode` is still local to the main container; only the explicit cache subpaths above are shared.

## Why

The main goal is to let multiple containers share the same Lean toolchain, warmed package cache, and comparator runtime safely. That works best when one dedicated service populates the shared volumes in write mode and normal app containers consume them as read-only seeds. `lake build` still needs a writable package tree, so each runtime container gets its own writable `.lake/packages` volume layered on top of the shared warmed cache without sharing mutable state with other containers.

## Implementation detail

`cache-warmer` is the compose service that pre-populates the shared caches with `scripts/bootstrap-lean.sh`. It mounts:

```bash
/home/opencode/.elan
/workspace/autoquantum/lean/.lake/packages
/home/opencode/.cache/autoquantum-tools
```

in write mode. Warmup installs the pinned Lean toolchain, populates the shared Lake dependency tree when the package cache volume is empty or invalid, and builds the comparator toolchain into `/home/opencode/.cache/autoquantum-tools/bin`. The warmer still treats `mathlib/lakefile.lean` as the validity check for the package cache and rebuilds that seed cache if the file is missing. The main `opencode` service mounts the warmed package cache read-only at `/home/opencode/.cache/lake-packages-seed`, copies it into its own anonymous writable `.lake/packages` volume on first start, mounts the comparator cache read-only at the same path, and prepends the cached `bin/` directory to `PATH` before launching OpenCode. If the shared Lean cache is missing, `scripts/entrypoint.sh` still falls back to `scripts/bootstrap-lean.sh` and populates the runtime Lean cache directly when the relevant mounts are writable.

## Follow-up

If we later want faster startup for large writable package volumes, the next step is to replace the copy step with an overlay or reflink-based seeding strategy.
