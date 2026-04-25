# Bash Shell Recursion Fix

Updated: 2026-04-25

## Symptom

Running `docker compose exec opencode bash` caused a segmentation fault, while `sh` still worked.

## Root cause

The image build appended this line to `/home/opencode/.bashrc`:

```bash
. ~/.profile
```

Ubuntu's default `/home/opencode/.profile` already sources `.bashrc` when Bash starts as a login shell, so interactive Bash ended up in a recursive startup loop:

```text
.bashrc -> .profile -> .bashrc -> ...
```

That eventually crashed the shell.

## Fix

Do not source `.profile` from `.bashrc`. Instead, source `~/.elan/env` directly from `.bashrc` so interactive shells still pick up the Lean toolchain path without creating a recursion cycle.

## Operational note

After this fix, rebuild the image before testing:

```bash
docker compose build
docker compose up -d
```
