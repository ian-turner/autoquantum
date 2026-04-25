# LaTeX Writer Edit Permission Fix

Date: April 25, 2026

## Problem

The `latex-writer` agent could claim that no edit/write tool was available even though `opencode.json`
contained scoped edit permissions for `latex-out/**`.

## Cause

In this OpenCode setup, narrow scoped `edit` permission objects can prevent the edit tool from being
exposed to the agent at all. The repo had already hit the same issue with `proof-writer`.

## Fix

- Changed `latex-writer` in `opencode.json` from scoped edit permissions to plain:
  ```json
  "edit": "allow"
  ```
- Kept the directory restriction in the agent prompt instead:
  - only write under `latex-out/`
  - report write failures explicitly
  - do not stop at prose; edit the files directly

## Guidance

For agents that must reliably create or modify files, prefer plain `edit: "allow"` and enforce
write-scope through prompt instructions unless OpenCode's scoped edit behavior becomes reliable.

