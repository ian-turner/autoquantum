# Comparator Cache Warmup Fix

Updated: 2026-04-25

## Symptom

`docker compose up` failed during the `cache-warmer` phase after comparator warmup was added. The relevant log line was:

```text
failed to pin comparator's lean4export dependency
```

The main `opencode` service remained in `Created` state because it depends on `cache-warmer` completing successfully.

## Root cause

`scripts/setup_comparator.sh` originally tried to pin comparator's `lean4export` dependency with a regex that assumed this exact adjacency in `comparator/lakefile.toml`:

```toml
name = "lean4export"
rev = "..."
```

The actual file at comparator `v4.29.0` includes an intervening `scope = "leanprover"` line inside the `[[require]]` block, so the regex no longer matched and the script exited.

## Fix

- Replaced the brittle regex with block-aware line rewriting that finds the `[[require]]` block whose `name` is `lean4export` and updates its `rev`.
- Made cached tool source checkouts reproducible by running `git reset --hard HEAD` and `git clean -fdx` before reusing an existing checkout in the shared comparator cache.

## Validation

- `bash -n scripts/setup_comparator.sh`
- `docker compose build`
- `docker compose up --force-recreate cache-warmer`
- `docker compose up -d`

After the fix:

- `cache-warmer` exits with code 0
- comparator, `lean4export`, and `landrun` are installed under `/home/opencode/.cache/autoquantum-tools/bin`
- `opencode` starts successfully and serves on port `4096`

## Extra note

The log line `error: unknown executable cache` from `lake exe cache get` is currently benign in this flow because the setup script already tolerates it with `|| true`. It was not the cause of the Compose failure.
