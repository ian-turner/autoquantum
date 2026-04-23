# AutoQuantum Framework Generalization Plan

**Date**: April 22, 2026  
**Status**: Planning phase  
**Goal**: Transform AutoQuantum from a single-project setup into a reusable framework for Lean 4 auto-coding, specifically optimized for quantum computing verification but extensible to other formal verification domains.

## Overview

AutoQuantum currently provides a working pipeline for automatic generation and formal verification of quantum circuits using LLMs and Lean 4. This plan outlines the steps to generalize the framework for use across multiple Lean quantum projects while maintaining the AutoQuantum identity.

## Core Components to Generalize

### 1. **Docker/Container Framework** - Configurable & Flexible

#### Current State and Remaining Limitations
- Separate `serve.sh` and `web.sh` entrypoints now exist and are used directly by Docker
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
# Current direction: keep dedicated scripts and make them path-agnostic
# serve.sh
export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode serve --hostname "${OPENCODE_HOST:-0.0.0.0}" --port "${OPENCODE_PORT:-4096}"

# web.sh
export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode web --hostname "${OPENCODE_HOST:-0.0.0.0}" --port "${OPENCODE_PORT:-4096}"
```

**C. Preserve Cache-Warmer Architecture While Generalizing Paths**
```yaml
services:
  cache-warmer:
    entrypoint: ["./warm-cache.sh"]
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

### 2. **Multi-Agent System with Permissions** (Includes Reading Agent)

#### Agent Definitions in `opencode.json`

```json
{
  "command": {
    "developer": {
      "description": "Highest-permission agent for direct project development, framework work, and general Lean engineering beyond proof writing",
      "permission": {
        "bash": "allow",
        "read": "allow",
        "edit": "allow",
        "task": "allow",
        "webfetch": "ask"
      }
    },
    "proof-writer": {
      "description": "Specialized in writing and verifying Lean proofs",
      "permission": {
        "bash": "allow",
        "read": "allow",
        "edit": { ".lean": "allow", "*": "ask" },
        "task": "deny",
        "webfetch": "ask"
      }
    },
    "code-reviewer": {
      "description": "Review code and proofs (read-only)",
      "permission": {
        "read": "allow",
        "edit": "deny",
        "bash": "deny",
        "webfetch": "ask"
      }
    },
    "reading-agent": {
      "description": "Read and analyze arXiv papers and research literature",
      "permission": {
        "read": "allow",
        "edit": { "*.lean": "allow", "notes/papers/*.md": "allow", "notes/research/*.md": "allow", "*": "ask" },
        "webfetch": "allow",  # Restricted in practice to arXiv plus approved PDF sources
        "bash": "deny",
        "task": "allow"  # Can delegate to explore agents
      }
    },
    "verifier": {
      "description": "Check Lean files, validate proof obligations, and confirm claimed results",
      "permission": {
        "read": "allow",
        "edit": "deny",
        "bash": "allow",
        "webfetch": "ask"
      }
    },
    "latex-writer": {
      "description": "Translate Lean definitions and proofs into LaTeX documents and PDF-ready sources",
      "permission": {
        "read": "allow",
        "edit": { "*.tex": "allow", "*.bib": "allow", "*": "ask" },
        "bash": "allow",
        "webfetch": "ask"
      }
    }
  }
}
```

#### Reading Agent Capabilities
- **Restricted source access**: Fetch papers from arXiv and read local PDFs from an approved directory only
- **PDF parsing**: Extract text, figures, mathematical notation
- **Math OCR**: Recover equations and notation that are not captured well by plain PDF text extraction
- **Summary generation**: Create concise summaries of papers
- **Theorem extraction**: Identify formalizable statements
- **Circuit diagram analysis**: Parse quantum circuit diagrams
- **Research context**: Connect papers to existing Lean formalizations
- **Lean skeleton generation**: Produce a basic Lean file skeleton with imports, declarations, and theorem stubs for the proof-writer to refine

#### Latex Writer Capabilities
- **Proof transcription**: Convert Lean theorem statements and proofs into mathematical prose
- **Notation alignment**: Rewrite Lean syntax into standard LaTeX notation while preserving meaning
- **Document assembly**: Produce paper-style sections, theorem environments, and appendices
- **PDF builds**: Generate `.tex` and bibliography inputs, then compile them with `pdflatex` / `latexmk`
- **Formalization traceability**: Link LaTeX explanations back to source Lean declarations

#### Developer Agent Capabilities
- **General project engineering**: Work directly on framework code, infrastructure, scripts, and documentation
- **Lean development beyond proofs**: Implement definitions, APIs, refactors, and supporting tooling for Lean projects
- **Cross-cutting changes**: Coordinate edits that span Docker, MCP tooling, config, notes, and source code
- **Task delegation**: Hand specialized proof, review, reading, verification, or LaTeX work to narrower agents when useful

#### Agent Workflow Integration
```
Developer → Coordinates project work → Proof Writer → Verifier
     ↓                  ↓
Reading Agent     Direct code / infra changes
     ↓
Extracts theorem/circuit → Lean skeleton / notes
                                     ↓
                              Latex Writer → PDF-ready writeup
                                             ↓
                                      Code Reviewer validates
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
├── run.sh             # Launcher with PATH setup
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
      "command": ["bash", "-c", "LEAN_LOOGLE_LOCAL=false LEAN_REPL=false .mcp/run-lean-lsp-mcp.sh"],
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

### Phase 1: Foundation & Docker (Week 1-2)
1. Refactor Docker setup for configurable mounts and commands
2. Implement separate entrypoint scripts (serve.sh, web.sh) for different OpenCode modes
3. Document environment overrides directly in `docker-compose.yml` and command examples
4. Update `AGENTS.md` with new framework structure

### Phase 2: Agent System with Reading Agent (Week 3-4)
1. Define all agents in `opencode.json` with permissions
2. Add the high-permission developer agent for framework and general project work
3. Implement reading agent with restricted arXiv/local-PDF access plus math OCR
4. Add verifier workflows for proof checking and result validation
5. Add latex-writer workflows for Lean-to-LaTeX document generation and PDF compilation
6. Create agent switching mechanism (`@agent` syntax)
7. Test permission boundaries and agent workflows

### Phase 3: Generic MCP Tools (Week 5-6)
1. Refactor `server.py` and MCP tools for project-agnostic operation
2. Create standalone `lean-mcp-tools` package
3. Update all path references to use configurable variables
4. Test with different Lean project structures

### Phase 4: Configuration & Simplified Skills (Week 7-8)
1. Implement layered configuration system
2. Create broad skill definitions (no fine-grained patterns)
3. Integrate reading agent with research workflow
4. Update documentation for new framework

### Phase 5: Polish & Integration (Week 9-10)
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

1. **Reading Agent Scope**: Restrict the reading agent to arXiv plus local PDFs from an approved directory.
2. **Agent Permissions**: Reading-agent web access should be limited to arXiv and approved PDF retrieval paths rather than broad web access.
3. **PDF Processing**: Include math OCR as part of the planned reading-agent toolchain.
4. **Integration Depth**: The reading agent should be able to draft a basic Lean skeleton in addition to summaries.
5. **Latex Writer Scope**: The latex writer should own both `.tex` generation and PDF compilation.
6. **Developer Agent Role**: Add a highest-permission developer agent for direct code work, framework engineering, and broader Lean development beyond proof-writing-only tasks.
7. **Backward Compatibility**: Compatibility can be broken during the transition; the framework should optimize for the new architecture rather than preserving the old layout.

## Status Updates

- **April 22, 2026**: Plan created after analysis of current setup and research into Lean 4 auto-coding patterns
- **April 22, 2026**: Phase 1 implementation started:
  - Dockerfile updated to install gettext for envsubst
  - `opencode.json` created as canonical configuration (no model field)
  - `serve.sh` and `web.sh` split into dedicated entrypoints
  - `docker-compose.yml` updated with Docker environment variables for `PROJECT_ROOT`, `LEAN_PROJECT_PATH`, `LEAN_TOOLS_REPO_ROOT`, and `LEAN_TARGET`
  - Added `cache-warmer` service plus seeded-cache startup flow for writable runtime Lake packages
  - Runtime configuration documented through compose defaults and environment-variable overrides instead of a checked-in `.env.template`
  - `.gitignore` updated to include `opencode.json` (now tracked)
  - `lean_lsp` launcher now respects `LEAN_PROJECT_PATH`; `lean-tools` launcher uses `LEAN_TOOLS_REPO_ROOT` and still needs a final project-agnostic pass
- Next step: Test Docker configuration and refine as needed

---

*This plan represents the evolution of AutoQuantum from a single-project tool to a reusable framework for Lean 4 auto-coding in quantum computing verification.*
