# Docker Cache Layout

Updated: 2026-04-22

## Current split

- `autoquantum-elan-cache` is a Docker volume mounted read-write into `cache-warmer` and read-only into `opencode`.
- `autoquantum-mathlib-cache` is a Docker volume mounted read-write into `cache-warmer` and read-only into `opencode`.
- `/home/opencode/.cache` is not a shared Docker volume. The main container keeps only its own local writable runtime cache such as `~/.cache/opencode`.

## Why

The main goal is to let multiple containers share the same Lean toolchain and Lake package cache safely. That works best when one dedicated service populates the shared volumes in write mode and all normal app containers consume them in read-only mode. Keeping the image itself minimal also avoids shipping multi-gigabyte cache layers.

## Implementation detail

`cache-warmer` is the only compose service that runs `bootstrap-lean.sh`. It mounts:

```bash
/home/opencode/.elan
/workspace/autoquantum/lean/.lake/packages
```

in write mode, installs the pinned Lean toolchain, and populates the Lake dependency tree when the package cache volume is empty. The main `opencode` service mounts those same volumes read-only and refuses to start if they are missing.

## Follow-up

If we later want finer-grained cache refresh behavior, the next step is to split `bootstrap-lean.sh` into explicit phases such as `warm-toolchain` and `warm-packages` rather than a single combined bootstrap path.
