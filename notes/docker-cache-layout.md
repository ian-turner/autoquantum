# Docker Cache Layout

Updated: 2026-04-22

## Current split

- `autoquantum-elan-cache` is a Docker volume mounted read-write into `cache-warmer` and read-only into `opencode`.
- `autoquantum-mathlib-cache` is a Docker volume mounted read-write into `cache-warmer` and read-only into `opencode` at `/home/opencode/.cache/lake-packages-seed`.
- `opencode` mounts a separate writable `lake-work` volume at `/workspace/autoquantum/lean/.lake/packages` and seeds it from the shared read-only package cache on first start.
- `/home/opencode/.cache` is not a shared Docker volume. The main container keeps only its own local writable runtime cache such as `~/.cache/opencode`.

## Why

The main goal is to let multiple containers share the same Lean toolchain and warmed package cache safely. That works best when one dedicated service populates the shared volumes in write mode and normal app containers consume them as read-only seeds. `lake build` still needs a writable package tree, so each runtime container gets its own writable `.lake/packages` volume layered on top of the shared warmed cache.

## Implementation detail

`cache-warmer` is the only compose service that runs `bootstrap-lean.sh`. It mounts:

```bash
/home/opencode/.elan
/workspace/autoquantum/lean/.lake/packages
```

in write mode, installs the pinned Lean toolchain, and populates the shared Lake dependency tree when the package cache volume is empty or invalid. The warmer now treats `mathlib/lakefile.lean` as the validity check and rebuilds the seed cache if that file is missing. The main `opencode` service mounts the warmed package cache read-only at `/home/opencode/.cache/lake-packages-seed`, copies it into its own writable `.lake/packages` volume on first start, runs `lake update` against that private worktree, and refuses to start if the seed cache is missing.

## Follow-up

If we later want faster startup for large writable package volumes, the next step is to replace the copy step with an overlay or reflink-based seeding strategy.
