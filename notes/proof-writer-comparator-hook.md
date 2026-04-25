# Proof-writer Comparator Hook

**Date**: April 25, 2026  
**Status**: Implemented

## Goal

Make comparator verification mandatory for OpenCode proof-writing sessions by running it from a session-completion hook instead of relying on the agent to call a verification tool.

## What changed

- Added a dedicated `proof-writer` agent to `opencode.json`.
- Added `.opencode/rules/agents/proof-writer.md` as the canonical editable prompt source.
- Extended `.opencode/plugins/lean-tools.js` with:
  - `lean_goal_context` for loading the trusted `Goals/<Stem>.lean` contract,
  - `verify_comparator_goal` for manual comparator runs when debugging,
  - a `chat.message` hook that records the requested goal stem for `proof-writer` sessions,
  - a mandatory `session.idle` hook that runs `python3 scripts/verify_comparator.py --goal <Stem>` after every completed `proof-writer` response.

## Invocation contract

The goal stem must be present in the `proof-writer` prompt. Supported forms:

- `goal=Comm`
- `goal: Comm`
- `goal Comm`
- `lean/Goals/Comm.lean`

If no goal can be extracted, the hook cannot run comparator and emits a visible error toast instead.

## Why this design

The earlier file-edit-triggered approach was weaker than the actual requirement. The real requirement is "run comparator when the proof-writing agent finishes generating," not "run comparator when a solution file happened to be edited." Tracking the requested goal from the prompt is the stable input that makes the hook independent of the agent's internal tool choices.

## Operational notes

- The mandatory comparator hook currently applies only to `proof-writer` sessions.
- Comparator runs after every completed `proof-writer` response, not only after a final success message.
- Toasts report pass/fail status in the OpenCode UI. Manual `verify_comparator_goal` remains available for transcript-visible debugging.
- The `proof-writer` prompt was hardened on April 25, 2026 with an explicit file-writing protocol because the earlier version was too abstract about actually editing `lean/Solutions/<Goal>.lean`. The agent is now instructed to edit or create the file directly, verify the on-disk contents before finishing, and treat write failures as blockers rather than replying with a prose-only patch description.
- The `proof-writer` agent permission was also widened to plain `edit: \"allow\"` on April 25, 2026 because the narrower scoped-edit form was leaving the agent without an exposed edit tool in practice. The file-scope restriction is currently enforced by prompt instructions rather than by OpenCode permission filtering.
- If future tooling changes the goal syntax, update both:
  - `.opencode/rules/agents/proof-writer.md`
  - `.opencode/plugins/lean-tools.js` `extractGoalStem`
