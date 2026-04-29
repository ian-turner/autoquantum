# AutoQuantum OpenCode Docker image
# Lean 4.29.0 + Mathlib v4.29.0 + comparator + OpenCode CLI
# All heavy dependencies are baked in at build time.

FROM ubuntu:22.04

# Install system dependencies
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
    golang-go \
    cargo \
    ripgrep \
    gettext \
    tzdata \
    texlive-latex-base \
    texlive-pictures \
    texlive-science \
    texlive-fonts-recommended \
    latexmk \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && rm -rf /var/lib/apt/lists/*

# Install uv and Python MCP packages globally
RUN pip3 install uv \
    && uv pip install --system mcp \
    && uv pip install --system lean-lsp-mcp

# Install OpenCode CLI globally
RUN npm install -g opencode-ai

# Create non-root user matching host UID/GID (501:20)
RUN useradd -m -u 501 -g 20 -s /bin/bash opencode

# Create workspace and set ownership
RUN mkdir -p /workspace && chown opencode:20 /workspace

USER opencode
WORKDIR /home/opencode

# Install elan and the Lean toolchain
ENV PATH="/home/opencode/.elan/bin:/home/opencode/.tools/bin:$PATH"
RUN curl -sSf https://elan.lean-lang.org/elan-init.sh | sh -s -- -y --default-toolchain none && \
    elan toolchain install leanprover/lean4:v4.29.0 && \
    elan default leanprover/lean4:v4.29.0

# Copy project and resolve Lean dependencies (packages land at lean/.lake/packages)
COPY --chown=opencode:20 . /workspace/autoquantum
WORKDIR /workspace/autoquantum/lean
# Pre-clone large dependencies with --depth 1 before lake update so Lake
# doesn't do a full clone of the ~500 MB mathlib repo
RUN mkdir -p .lake/packages && \
    git clone --filter=blob:none --depth 1 --branch v4.29.0 \
        https://github.com/leanprover-community/mathlib4 \
        .lake/packages/mathlib && \
    git clone --filter=blob:none --depth 1 --branch v4.29.0 \
        https://github.com/leanprover-community/repl \
        .lake/packages/repl && \
    lake update && lake exe cache get

# Build comparator and lean4export (lean4export is a dependency of comparator)
WORKDIR /home/opencode
RUN mkdir -p .tools/bin && \
    git clone --filter=blob:none --depth 1 --branch v4.29.0 \
        https://github.com/leanprover/comparator.git .tools/src/comparator && \
    lake --dir .tools/src/comparator update && \
    lake --dir .tools/src/comparator build && \
    lake --dir .tools/src/comparator/.lake/packages/lean4export build && \
    cp .tools/src/comparator/.lake/build/bin/comparator .tools/bin/comparator && \
    cp .tools/src/comparator/.lake/packages/lean4export/.lake/build/bin/lean4export .tools/bin/lean4export

# Build landrun
RUN git clone --depth 1 https://github.com/Zouuup/landrun.git .tools/src/landrun && \
    cd .tools/src/landrun && \
    go build -o /home/opencode/.tools/bin/landrun cmd/landrun/main.go

WORKDIR /workspace/autoquantum

ENTRYPOINT ["./scripts/entrypoint.sh"]
