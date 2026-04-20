# AutoQuantum OpenCode Docker image
# Lean 4.29.0 + Mathlib v4.29.0 + OpenCode CLI + MCP servers
# Built for reproducible, sandboxed quantum circuit verification.

FROM ubuntu:22.04

# Install system dependencies as root
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    cargo \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager) and Python mcp package globally
RUN pip3 install uv \
    && uv pip install --system mcp \
    && uv pip install --system lean-lsp-mcp

# Install OpenCode CLI globally
RUN npm install -g opencode-ai

# Create non‑root user matching host UID/GID (501:20)
RUN useradd -m -u 501 -g 20 -s /bin/bash opencode

# Create workspace directory and set ownership
RUN mkdir -p /workspace && chown opencode:20 /workspace

# Copy entrypoint script while still root
COPY entrypoint.sh /home/opencode/entrypoint.sh
RUN chown opencode:20 /home/opencode/entrypoint.sh && chmod +x /home/opencode/entrypoint.sh

# Switch to non‑root user for elan installation
USER opencode
WORKDIR /home/opencode

# Install elan (Lean toolchain manager) for the opencode user
RUN curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y \
    && . ~/.profile \
    && elan toolchain install leanprover/lean4:v4.29.0 \
    && elan default leanprover/lean4:v4.29.0

RUN mkdir -p ~/.cache/opencode

# Set up environment (ensure elan is in PATH)
RUN echo '. ~/.profile' >> ~/.bashrc

WORKDIR /workspace

ENTRYPOINT ["/home/opencode/entrypoint.sh"]