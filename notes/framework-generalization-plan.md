# AutoQuantum Framework Generalization Plan

**Date**: April 22, 2026  
**Status**: Planning phase  
**Goal**: Transform AutoQuantum from a single-project setup into a reusable framework for Lean 4 auto-coding, specifically optimized for quantum computing verification but extensible to other formal verification domains.

## Overview

AutoQuantum currently provides a working pipeline for automatic generation and formal verification of quantum circuits using LLMs and Lean 4. This plan outlines the steps to generalize the framework for use across multiple Lean quantum projects while maintaining the AutoQuantum identity.

## Core Components to Generalize

### 1. **Docker/Container Framework** - Configurable & Flexible

#### Current Limitations
- Fixed mount path: `/workspace/autoquantum`
- Always runs `opencode serve`
- Hardcoded project name in health check
- Fixed environment variables (`LEAN_PROJECT_PATH`, `LEAN_TOOLS_REPO_ROOT`)

#### Proposed Changes

**A. Configurable Volume Mounts**
```yaml
# docker-compose.yml updates
services:
  opencode:
    volumes:
      - ${PROJECT_ROOT:-./}:/workspace/project  # Configurable mount
      - ~/.gitconfig:/home/opencode/.gitconfig:ro
      - elan-cache:/home/opencode/.elan
      - mathlib-cache:/home/opencode/.cache/lean
    environment:
      # User project configuration (framework lives at /workspace/autoquantum)
      PROJECT_ROOT: /workspace/project
      LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH:-/workspace/project/lean}
      LEAN_TOOLS_REPO_ROOT: ${LEAN_TOOLS_REPO_ROOT:-/workspace/project}
```

**B. Flexible Entrypoint**
```bash
# entrypoint.sh - support multiple commands
if [ "$1" = "serve" ]; then
  exec opencode serve --hostname "${OPENCODE_HOST:-0.0.0.0}" --port "${OPENCODE_PORT:-4096}"
elif [ "$1" = "web" ]; then
  exec opencode web --hostname "${OPENCODE_HOST:-0.0.0.0}" --port "${OPENCODE_PORT:-4096}"
elif [ "$1" = "shell" ]; then
  exec /bin/bash
else
  # Default to serve if no arguments
  exec opencode serve --hostname "${OPENCODE_HOST:-0.0.0.0}" --port "${OPENCODE_PORT:-4096}"
fi
```

**C. Dynamic Health Check**
```yaml
healthcheck:
  test: ["CMD", "bash", "-c", "if [ -d ${LEAN_PROJECT_PATH} ]; then cd ${LEAN_PROJECT_PATH} && lake build ${LEAN_TARGET:-AutoQuantum}; else exit 0; fi"]
```

### 2. **Multi-Agent System with Permissions** (Includes Reading Agent)

#### Agent Definitions in `opencode.json`

```json
{
  "command": {
    "proof-writer": {
      "description": "Specialized in writing and verifying Lean proofs",
      "model": "deepseek/deepseek-reasoner",
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
      "model": "anthropic/claude-3-5-sonnet",
      "permission": {
        "read": "allow",
        "edit": "deny",
        "bash": "deny",
        "webfetch": "ask"
      }
    },
    "reading-agent": {
      "description": "Read and analyze arXiv papers and research literature",
      "model": "anthropic/claude-3-5-sonnet",  # Good for comprehension
      "permission": {
        "read": "allow",
        "edit": "deny",  # Read-only by default
        "webfetch": "allow",  # Full web access
        "bash": "deny",
        "task": "allow"  # Can delegate to explore agents
      }
    },
    "test-generator": {
      "description": "Generate tests and examples",
      "model": "openai/gpt-4o",
      "permission": {
        "read": "allow",
        "edit": { "*Test.lean": "allow", "*": "ask" },
        "bash": "ask",
        "webfetch": "ask"
      }
    }
  }
}
```

#### Reading Agent Capabilities
- **arXiv integration**: Fetch papers via arXiv API or direct PDF URLs
- **PDF parsing**: Extract text, figures, mathematical notation
- **Summary generation**: Create concise summaries of papers
- **Theorem extraction**: Identify formalizable statements
- **Circuit diagram analysis**: Parse quantum circuit diagrams
- **Research context**: Connect papers to existing Lean formalizations

#### Agent Workflow Integration
```
Reading Agent → Extracts theorem/circuit → Proof Writer → Verifies in Lean
      ↓
  Summarizes paper → Documents in notes/ → Code Reviewer validates
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
  "extends": [".config/opencode-base.json", ".config/opencode-quantum.json"],
  "model": "deepseek/deepseek-reasoner",
  "mcp": {
    // Project-specific MCP servers
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
3. **Math OCR**: Optional - for handwritten equations in PDFs
4. **Circuit Diagram Parser**: Basic image analysis for quantum circuits

### Agent Tools
- `fetch_arxiv_paper(arxiv_id)`: Get paper metadata and PDF
- `extract_pdf_text(pdf_path)`: Parse PDF content
- `analyze_quantum_circuit(image_path)`: Extract circuit structure
- `find_formalizable_statements(text)`: Identify theorems for Lean
- `connect_to_lean_definitions(concepts)`: Map paper concepts to existing Lean code

### Integration with Existing Workflow
- Reading agent can be invoked via `@reading-agent` in OpenCode
- Can save extracted content to `notes/research/` for reference
- Can create `notes/papers/<paper-id>.md` with summary and formalization targets

## Implementation Roadmap

### Phase 1: Foundation & Docker (Week 1-2)
1. Refactor Docker setup for configurable mounts and commands
2. Implement flexible entrypoint supporting multiple `opencode` commands
3. Create environment variable system with `.env.template`
4. Update `AGENTS.md` with new framework structure

### Phase 2: Agent System with Reading Agent (Week 3-4)
1. Define all agents in `opencode.json` with permissions
2. Implement reading agent with basic arXiv/PDF capabilities
3. Create agent switching mechanism (`@agent` syntax)
4. Test permission boundaries and agent workflows

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
4. Backward compatibility verification

## Key Benefits

1. **Reusability**: Use same framework across multiple Lean quantum projects
2. **Flexibility**: Configurable for different project structures and requirements
3. **Security**: Fine-grained permissions control for different agent types
4. **Maintainability**: Centralized configuration and shared tooling
5. **Research Integration**: Seamless paper → formalization workflow
6. **Extensibility**: Plugin system for project-specific needs

## Open Questions

1. **Reading Agent Scope**: Should it only handle arXiv, or also other research sources (PDFs from URLs, local PDFs, other preprint servers)?
2. **Agent Permissions**: How much web access should reading agent have? Full access or restricted domains?
3. **PDF Processing**: Do we need advanced math OCR, or is basic text extraction sufficient?
4. **Integration Depth**: Should reading agent directly create Lean skeleton code, or just provide summaries for proof-writer?
5. **Backward Compatibility**: Should we maintain a compatibility mode for existing AutoQuantum projects during transition?

## Status Updates

- **April 22, 2026**: Plan created after analysis of current setup and research into Lean 4 auto-coding patterns
- **April 22, 2026**: Phase 1 implementation started:
  - Dockerfile updated to install gettext for envsubst
  - `opencode.json.template` created with `${MODEL}` placeholder
  - Entrypoint script updated to generate `opencode.json` and support multiple commands
  - `docker-compose.yml` updated with configurable environment variables
  - `.env.template` created for runtime configuration
  - `.gitignore` updated to exclude generated `opencode.json`
  - MCP server scripts updated to respect `LEAN_PROJECT_PATH` environment variable
- Next step: Test Docker configuration and refine as needed

---

*This plan represents the evolution of AutoQuantum from a single-project tool to a reusable framework for Lean 4 auto-coding in quantum computing verification.*