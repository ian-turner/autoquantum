# AutoQuantum Framework Generalization Plan

**Date**: April 22, 2026  
**Status**: Phases 1–2 complete; Phases 3–5 planned  
**Goal**: Transform AutoQuantum from a single-project setup into a reusable framework for Lean 4 auto-coding, specifically optimized for quantum computing verification but extensible to other formal verification domains.

## Overview

AutoQuantum currently provides a working pipeline for automatic generation and formal verification of quantum circuits using LLMs and Lean 4. This plan outlines the steps to generalize the framework for use across multiple Lean quantum projects while maintaining the AutoQuantum identity.

## Core Components to Generalize

### 1. **Docker/Container Framework** - Configurable & Flexible

#### Current State and Remaining Limitations
- A single `scripts/entrypoint.sh` now owns container startup and runs OpenCode in `serve` mode
- `docker-compose.yml` now passes `PROJECT_ROOT`, `LEAN_PROJECT_PATH`, `LEAN_TOOLS_REPO_ROOT`, and `LEAN_TARGET`
- A dedicated `cache-warmer` service seeds shared Elan / Lake caches before the main OpenCode container starts
- Runtime Lake packages are copied from a read-only seed cache into a writable per-container worktree on startup
- Remaining limitation: the compose file and scripts still assume the project is mounted at `/workspace/autoquantum`
- Remaining limitation: Lean MCP path resolution is only partially generalized today, with `lean_lsp` using `LEAN_PROJECT_PATH` and `lean-tools` still centered on repo-root discovery via `LEAN_TOOLS_REPO_ROOT`

#### Proposed Changes

**A. Configurable Volume Mounts**
```yaml
# docker-compose.yml updates
services:
  opencode:
    volumes:
      - ${PROJECT_ROOT:-./}:/workspace/project  # Configurable project mount
      - ~/.gitconfig:/home/opencode/.gitconfig:ro
      - elan-cache:/home/opencode/.elan
      - mathlib-cache:/home/opencode/.cache/lake-packages-seed:ro
      - /workspace/project/lean/.lake/packages
    environment:
      # User project configuration (framework code can still live at /workspace/autoquantum)
      PROJECT_ROOT: /workspace/project
      LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH:-/workspace/project/lean}
      LEAN_TOOLS_REPO_ROOT: ${LEAN_TOOLS_REPO_ROOT:-/workspace/project}
```

**B. Flexible Entrypoint**
```bash
# Current direction: keep a single path-agnostic entrypoint
# scripts/entrypoint.sh
export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode serve --hostname "${OPENCODE_HOST:-0.0.0.0}" --port "${OPENCODE_PORT:-4096}"
```

**C. Preserve Cache-Warmer Architecture While Generalizing Paths**
```yaml
services:
  cache-warmer:
    entrypoint: ["./scripts/warm-cache.sh"]
  opencode:
    depends_on:
      cache-warmer:
        condition: service_completed_successfully
```

The recent cache design is worth keeping: shared Elan and seeded Lake package caches remain persistent across runs, while the runtime `.lake/packages` tree stays writable and isolated per container.

**D. Dynamic Health Check (Optional)**
```yaml
# Health check removed from default configuration (runs lake build periodically)
# Uncomment if you want container health monitoring
# healthcheck:
#   test: ["CMD", "bash", "-c", "if [ -d ${LEAN_PROJECT_PATH} ]; then cd ${LEAN_PROJECT_PATH} && lake build ${LEAN_TARGET:-AutoQuantum}; else exit 0; fi"]
```

### 2. **Multi-Agent System** — Phase 2 Implementation

#### Implemented Agents ✅

Four agents implemented:
1. **`build`** — highest-permission, general project and framework work (originally named `developer`)
2. **`plan`** — read-only, designs proof/formalization strategies before execution (added alongside `build`)
3. **`reading`** — arXiv + local PDF ingestion, theorem extraction, Lean skeleton generation
4. **`latex-writer`** — Lean-to-LaTeX transcription and PDF compilation

The remaining agents (`proof-writer`, `verifier`, `code-reviewer`) remain for a later pass.

#### Confirmed OpenCode `agent` Block Schema

Fields available per agent definition (confirmed from `https://opencode.ai/config.json`):

| Field | Purpose |
|-------|---------|
| `description` | Documentation string shown when selecting the agent |
| `prompt` | **Inlined system instructions** — agent-specific rules go here |
| `model` | Model override for this agent |
| `variant` | Model variant override |
| `temperature`, `top_p` | Sampling parameters |
| `mode` | `"primary"`, `"subagent"`, or `"all"` |
| `steps` | Max agentic iterations |
| `hidden` | Hide from agent picker |
| `disable` | Disable agent entirely |
| `color` | Theme color |
| `options` | Custom key-value config |
| `permission` | Granular tool/file permissions (see below) |

Permission categories: `read`, `edit`, `bash`, `lsp`, `glob`, `grep`, `webfetch`, `websearch`, `codesearch`, `task`, `todowrite`, `skill`, `external_directory`. Each takes `"allow"`, `"ask"`, or `"deny"`.

#### Tiered Rules Architecture

Rules are split into two layers:

**Layer 1 — Common rules (`.opencode/rules/*.md`, auto-loaded into every session):**
- `project-overview.md` — project layout, key files, build commands, how agents relate
- `lean-workflow.md` — MCP tool reference, decision tree, iterative workflow, stop conditions
- `lean-proof-patterns.md` — confirmed tensor-product, gate-placement, and circuit patterns

**Layer 2 — Agent-specific instructions (`prompt` field in `opencode.json`):**
- Each priority agent has a dedicated rules file in `.opencode/rules/agents/<name>.md`
- The full content of that file is inlined into the agent's `prompt` field — this maximizes context quality without loading all agent rules into every session
- Files in `.opencode/rules/agents/` serve as the canonical editable source; `prompt` values in `opencode.json` are kept in sync

The split means all agents share the common foundation (project layout, Lean tools) while each gets deep, targeted instructions without cluttering other agents' contexts.

#### Agent Definitions in `opencode.json`

Implemented agents (using `"agent"` key in `opencode.json`):

```json
{
  "agent": {
    "build": { ... },      // highest-permission; general project + framework work
    "plan": { ... },       // read-only; designs proof/formalization strategies before execution
    "reading": { ... },    // arXiv + local PDF ingestion, Lean skeleton generation
    "latex-writer": { ... } // Lean → LaTeX + PDF compilation via latex MCP server
  }
}
```

Note: the `developer` agent was renamed `build`; a `plan` agent (read-only) was added alongside it. `edit` for `reading` and `latex-writer` is `"ask"` to require confirmation before writing. Agent instructions live in `.opencode/rules/agents/<name>.md`; `opencode.json` `prompt` fields are kept in sync.

#### Agent Capabilities

**`build`:**
- General project engineering: framework code, infrastructure, scripts, documentation
- Lean development beyond proofs: definitions, APIs, refactors, supporting tooling
- Cross-cutting changes spanning Docker, MCP, config, notes, and Lean source
- Task delegation to specialized agents for proof, review, reading, verification, or LaTeX work

**`plan`:**
- Read-only; designs proof strategies, formalization plans, and multi-agent workflows
- Checks `notes/` for prior attempts before proposing a strategy
- Outputs structured plans to `.opencode/plans/` or inline; does not edit Lean source

**`reading`:**
- Fetch papers from arXiv; read local PDFs from `references/`
- Extract text, equations, and mathematical notation
- Identify formalizable theorems and circuit descriptions
- Generate structured notes in `notes/papers/<id>.md`
- Draft a basic Lean file skeleton (imports, declarations, theorem stubs) for the proof-writer

**`latex-writer`:**
- Transcribe Lean theorem statements and proofs into mathematical prose
- Rewrite Lean syntax into standard LaTeX notation while preserving meaning
- Produce paper-style sections, theorem environments, and appendices in `latex/`
- Trigger PDF compilation via a dedicated `latex` MCP server — no bash permissions
- Edit permissions scoped to `latex/` output directory only
- Link LaTeX explanations back to source Lean declarations for traceability

#### Agent Workflow

```
Developer → Coordinates project work → Proof Writer → Verifier
     ↓
Reading Agent
  → Fetches paper, extracts theorems
  → Creates notes/papers/<id>.md
  → Drafts Lean skeleton → Proof Writer refines
                                ↓
                         Latex Writer
                           → Reads Lean source + notes
                           → Produces .tex / PDF
                           → Code Reviewer validates
```

### 3. **Generic Lean MCP Tools**

#### Configurable Implementation
```python
# server.py - environment-based path resolution
def _lean_root() -> Path:
    if path := os.environ.get("LEAN_PROJECT_PATH"):
        return Path(path)
    return _repo_root() / "lean"  # Default fallback
```

#### Standalone Package Structure
```
lean-mcp-tools/
├── server.py           # Generic Lean tools (build, check_file, sorry_count)
├── .mcp/lean-tools/run.sh  # Launcher with PATH setup
└── README.md          # Installation/usage for any Lean project
```

### 4. **Configuration System** (Simplified)

#### Layered Configuration
```
.config/
├── opencode-base.json      # Framework defaults
├── opencode-quantum.json   # Quantum-specific settings (MCP servers, agents)
└── project.json           # Project-specific overrides
```

#### Minimal `opencode.json`
```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [".opencode/plugins/lean-tools.js"],
  "mcp": {
    "lean": {
      "type": "local",
      "command": ["bash", ".mcp/lean-tools/run.sh"],
      "enabled": true,
      "timeout": 180000
    },
    "lean_lsp": {
      "type": "local",
      "command": ["bash", "-c", "LEAN_REPL=false .mcp/run-lean-lsp-mcp.sh"],
      "enabled": true,
      "timeout": 120000
    }
  }
}
```

### 5. **Simplified Skill System** (No Super-Granular Skills)

#### Broad Skill Categories Only
```yaml
# skills/quantum-verification.yml
name: quantum-verification
description: General skills for quantum circuit verification in Lean
includes:
  - tensor-product-coordinate-patterns
  - gate-placement-strategies  
  - circuit-decomposition-methods
  - unitarity-proof-techniques
```

#### Skill Activation
- Skills loaded based on project type (detected by file patterns)
- No fine-grained pattern library (QFT, GHZ, etc. remain in `.opencode/rules/`)
- Skills provide high-level guidance, not specific implementations

## Reading Agent Implementation Details

### Required Components
1. **arXiv API Integration**: `arxiv` Python package for paper search/fetch
2. **PDF Parsing**: `pdfplumber` or `pymupdf` for text extraction
3. **Math OCR**: Required for equations and notation that do not survive normal PDF extraction
4. **Circuit Diagram Parser**: Basic image analysis for quantum circuits

### Agent Tools
- `fetch_arxiv_paper(arxiv_id)`: Get paper metadata and PDF
- `load_local_pdf(pdf_path)`: Read a local PDF from the approved research directory
- `extract_pdf_text(pdf_path)`: Parse PDF content
- `extract_math_with_ocr(pdf_path)`: Recover equations and symbols missed by text extraction
- `analyze_quantum_circuit(image_path)`: Extract circuit structure
- `find_formalizable_statements(text)`: Identify theorems for Lean
- `connect_to_lean_definitions(concepts)`: Map paper concepts to existing Lean code
- `generate_basic_lean_skeleton(concepts)`: Draft imports, definitions, and theorem placeholders from extracted concepts

### Integration with Existing Workflow
- Reading agent can be invoked via `@reading-agent` in OpenCode
- Can save extracted content to `notes/research/` for reference
- Can create `notes/papers/<paper-id>.md` with summary and formalization targets
- Can draft an initial Lean skeleton for the proof-writer when a paper contains a clear formalization target

## Implementation Roadmap

### Phase 1: Foundation & Docker ✅ Complete
1. Refactor Docker setup for configurable mounts and commands
2. Consolidate container startup behind a single `scripts/entrypoint.sh`
3. Document environment overrides directly in `docker-compose.yml` and command examples
4. Update `AGENTS.md` with new framework structure

### Phase 2: Agent System ✅ Complete
1. Define `build`, `plan`, `reading`, and `latex-writer` agents in `opencode.json` with permissions
2. Agent instructions in `.opencode/rules/agents/<name>.md`; `prompt` fields in `opencode.json` kept in sync
3. `latex` MCP server added to container (TeX Live + dedicated run.sh)
4. Agent switching via `@<name>` syntax

### Phase 3: Generic MCP Tools (planned)
1. Refactor `server.py` and MCP tools for project-agnostic operation
2. Create standalone `lean-mcp-tools` package
3. Update all path references to use configurable variables
4. Test with different Lean project structures

### Phase 4: Configuration & Simplified Skills (planned)
1. Implement layered configuration system
2. Create broad skill definitions (no fine-grained patterns)
3. Integrate reading agent with research workflow
4. Update documentation for new framework

### Phase 5: Polish & Integration (planned)
1. Comprehensive testing across different use cases
2. Performance optimization for large projects
3. Documentation updates and examples
4. Remove legacy compatibility assumptions and document the migration break clearly

## Key Benefits

1. **Reusability**: Use same framework across multiple Lean quantum projects
2. **Flexibility**: Configurable for different project structures and requirements
3. **Security**: Fine-grained permissions control for different agent types
4. **Maintainability**: Centralized configuration and shared tooling
5. **Research Integration**: Seamless paper → formalization workflow
6. **Documentation Output**: Lean developments can be turned into publication-ready LaTeX artifacts
7. **Extensibility**: Plugin system for project-specific needs

## Resolved Decisions

1. **Reading Agent Scope**: Restrict the reading agent to arXiv plus local PDFs from `references/`.
2. **Agent Permissions**: Reading-agent web access is `allow` (needed for arXiv fetch), not restricted to a domain allowlist — rely on agent instructions to scope behavior.
3. **PDF Processing**: Include math OCR as part of the planned reading-agent toolchain.
4. **Integration Depth**: The reading agent should be able to draft a basic Lean skeleton in addition to summaries.
5. **Latex Writer Scope**: The latex writer owns `.tex` generation. PDF compilation goes through a dedicated `latex` MCP server — the agent has no bash permissions. Edit permissions are scoped to the `latex/` output directory.
6. **Developer Agent Role**: Add a highest-permission developer agent for direct code work, framework engineering, and broader Lean development beyond proof-writing-only tasks.
7. **Backward Compatibility**: Compatibility can be broken during the transition; the framework should optimize for the new architecture rather than preserving the old layout.
8. **Priority Agent Order**: Implement `developer`, `reading`, and `latex-writer` first. `proof-writer`, `verifier`, and `code-reviewer` follow in a later pass.
9. **Tiered Rules Architecture**: Common rules in `.opencode/rules/*.md` (auto-loaded to all sessions); agent-specific rules in `.opencode/rules/agents/<name>.md`, inlined into each agent's `prompt` field in `opencode.json`. The files are the editable source; `prompt` values are kept in sync.
10. **Inline Agent Instructions**: Agent `prompt` fields should contain the full text of the corresponding rules file to maximize per-agent context quality without polluting other agents' sessions.

## Status Updates

- **April 22, 2026**: Plan created after analysis of current setup and research into Lean 4 auto-coding patterns
- **April 22, 2026**: Phase 1 implementation started:
  - Dockerfile updated to install gettext for envsubst
  - `opencode.json` created as canonical configuration (no model field)
  - `scripts/entrypoint.sh` now owns the shared startup flow and launches `opencode serve`
  - `docker-compose.yml` updated with Docker environment variables for `PROJECT_ROOT`, `LEAN_PROJECT_PATH`, `LEAN_TOOLS_REPO_ROOT`, and `LEAN_TARGET`
  - Added `cache-warmer` service plus seeded-cache startup flow for writable runtime Lake packages
  - Runtime configuration documented through compose defaults and environment-variable overrides instead of a checked-in `.env.template`
  - `.gitignore` updated to include `opencode.json` (now tracked)
  - `lean_lsp` launcher now respects `LEAN_PROJECT_PATH`; `lean-tools` launcher uses `LEAN_TOOLS_REPO_ROOT` and still needs a final project-agnostic pass
- Phase 1 remaining gaps: `/workspace/autoquantum` is still hardcoded in `docker-compose.yml`, `scripts/entrypoint.sh`, and previously in `.claude/settings.json` (host paths now fixed in settings)
- **April 23, 2026**: Phase 2 planning complete:
  - OpenCode `agent` block schema confirmed; permission categories confirmed
  - Tiered rules architecture decided: common rules auto-loaded from `.opencode/rules/`; agent-specific rules inlined into `prompt` field from `.opencode/rules/agents/<name>.md`
  - Priority agents decided: `build` (formerly `developer`), `plan`, `reading`, `latex-writer`
- **April 23–24, 2026**: Phase 2 implemented:
  - All four agents (`build`, `plan`, `reading`, `latex-writer`) wired into `opencode.json`
  - `latex` MCP server added (`.mcp/latex-tools/`); TeX Live installed in container
  - Agent instructions written in `.opencode/rules/agents/`
  - `latex-out/` designated as latex-writer's output directory (gitignored)

---

*This plan represents the evolution of AutoQuantum from a single-project tool to a reusable framework for Lean 4 auto-coding in quantum computing verification.*
