# OpenCode Setup

This repo now includes a project-local OpenCode configuration in `opencode.json` plus supporting files under `.opencode/`.

## Goals

- Keep default session context compact.
- Keep model choice user-controlled instead of pinning the repo to a specific provider or family.
- Keep sampling behavior user-controlled instead of forcing repo-level temperature values.
- Prefer Lean-local tooling over broad web or repo search.
- Preserve proof state during session compaction.

## Layout

- `opencode.json` sets earlier compaction and a Lean proof subagent without pinning a provider, model, or temperature. OpenCode will use the model and sampling settings chosen by the user at runtime or via their own global config.
- `.opencode/tools/lean.ts` adds fixed Lean commands as custom tools: `lean_build` for `lake build` and `lean_check_file` for single-file `lake env lean` checks.
- `.opencode/bin/run-lean-lsp-mcp.sh` launches `lean-lsp-mcp` with `LEAN_PROJECT_PATH` resolved to this repo's `lean/` directory.
- `.opencode/plugins/lean-compaction.js` replaces the default compaction prompt with a proof-oriented one.
- `.opencode/prompts/lean-proof.md` gives the Lean subagent a compact, deterministic workflow.
- `.opencode/rules/project.md` is a small mirror of the most important project rules from `AGENTS.md`.

## Notes

- The config enables the community plugin `opencode-dynamic-context-pruning`. OpenCode will install npm plugins at startup, so this requires normal network/package access in the OpenCode environment.
- `.opencode/package.json` declares the `@opencode-ai/plugin` helper needed by the local custom tools. OpenCode should run `bun install` for these local dependencies at startup.
- The Lean MCP launcher disables the heaviest remote-search tools by default and biases the agent toward `lean_goal`, diagnostics, file outline, and local search first.
- The `lean-proof` subagent now has `bash` disabled so Lean builds and file checks go through the fixed tools instead of free-form shell.
