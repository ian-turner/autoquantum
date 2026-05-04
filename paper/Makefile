MAIN := main
BUILD_DIR := build

.PHONY: all clean

all: $(BUILD_DIR)/$(MAIN).pdf

$(BUILD_DIR)/$(MAIN).pdf: $(MAIN).tex aaai2026.sty | $(BUILD_DIR)
	@if command -v latexmk >/dev/null 2>&1; then \
		latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error \
			-outdir="$(BUILD_DIR)" "$(MAIN).tex"; \
	else \
		pdflatex -interaction=nonstopmode -halt-on-error -file-line-error \
			-output-directory="$(BUILD_DIR)" "$(MAIN).tex"; \
		pdflatex -interaction=nonstopmode -halt-on-error -file-line-error \
			-output-directory="$(BUILD_DIR)" "$(MAIN).tex"; \
	fi

$(BUILD_DIR):
	mkdir -p "$(BUILD_DIR)"

clean:
	latexmk -C -outdir="$(BUILD_DIR)" "$(MAIN).tex" 2>/dev/null || true
