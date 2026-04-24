# AutoQuantum OpenCode Docker image
# Lean 4.29.0 + Mathlib v4.29.0 + OpenCode CLI + MCP servers
# Built for reproducible, sandboxed quantum circuit verification.

FROM ubuntu:22.04

# Install system dependencies as root
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bash \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    cargo \
    ripgrep \
    gettext \
    tzdata \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
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

# Copy the entire autoquantum framework into the container
COPY --chown=opencode:20 . /workspace/autoquantum

# Switch to non-root user for home-directory setup. Lean itself is installed
# by the dedicated cache warmer service into mounted volumes at runtime.
USER opencode
WORKDIR /home/opencode

RUN mkdir -p ~/.cache/opencode

# Keep interactive shells aligned with elan's PATH updates once bootstrap runs.
RUN echo '. ~/.profile' >> ~/.bashrc

WORKDIR /workspace

USER root

ENTRYPOINT ["/workspace/autoquantum/entrypoint.sh"]
