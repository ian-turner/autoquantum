import { tool } from "@opencode-ai/plugin";
import { existsSync, readFileSync } from "fs";
import { join, isAbsolute } from "path";

export const LeanToolsPlugin = async ({ directory }) => {
  const leanRoot = join(directory, "lean");

  function resolveLeanPath(file) {
    if (isAbsolute(file)) return file;
    // Prefer lean/ subdirectory (most Lean source files live here)
    const fromLean = join(leanRoot, file);
    if (existsSync(fromLean)) return fromLean;
    // Fall back to project root
    const fromRoot = join(directory, file);
    if (existsSync(fromRoot)) return fromRoot;
    // Default assumption: relative to lean/
    return fromLean;
  }

  return {
    tool: {
      // ── lean_proof_step ───────────────────────────────────────────────────
      // Resolves a Lean file path to absolute form and formats the exact
      // parameter object for lean_lsp_lean_multi_attempt. Use this whenever
      // you are unsure of the correct absolute path format for LSP calls.
      lean_proof_step: tool({
        description:
          "Resolve a Lean file path to its absolute form and return the exact " +
          "arguments to pass to lean_lsp_lean_multi_attempt. Use this before " +
          "calling lean_lsp_lean_multi_attempt or lean_lsp_lean_goal when " +
          "unsure of the correct absolute file path.",
        args: {
          file: tool.schema
            .string()
            .describe(
              "Lean file path in any format: relative to project root, " +
              "relative to lean/, or absolute. Examples: " +
              "'AutoQuantum/Algorithms/HPlus.lean', " +
              "'lean/AutoQuantum/Algorithms/HPlus.lean', " +
              "'/workspace/autoquantum/lean/AutoQuantum/Algorithms/HPlus.lean'"
            ),
          line: tool.schema
            .number()
            .int()
            .positive()
            .describe("1-based line number of the tactic position (the line with sorry or the last tactic written)"),
          tactics: tool.schema
            .array(tool.schema.string())
            .describe("Tactic strings to test (1–8 candidates)"),
        },
        async execute({ file, line, tactics }) {
          const absPath = resolveLeanPath(file);
          const exists = existsSync(absPath);
          const lines = [
            `Resolved path: ${absPath}${exists ? "" : "  ⚠️  FILE NOT FOUND — check spelling"}`,
            "",
            "Call lean_lsp_lean_multi_attempt with these exact arguments:",
            `  file_path : "${absPath}"`,
            `  start_line: ${line}`,
            `  start_column: 0`,
            `  tactics   : ${JSON.stringify(tactics)}`,
            "",
            "After reviewing the results, call lean_lsp_lean_goal at the same",
            "position to see the full goal state for the winning tactic.",
          ];
          return lines.join("\n");
        },
      }),

      // ── lean_find_sorry ───────────────────────────────────────────────────
      // Scans a Lean file for `sorry` occurrences and returns each one with
      // 3 lines of surrounding context so you know exactly which goals remain.
      lean_find_sorry: tool({
        description:
          "Find all `sorry` positions in a Lean file with surrounding context. " +
          "Use this at the start of a session to understand which goals still " +
          "need to be proved before reading the whole file.",
        args: {
          file: tool.schema
            .string()
            .describe("Lean file path (any format — will be resolved automatically)"),
        },
        async execute({ file }) {
          const absPath = resolveLeanPath(file);
          if (!existsSync(absPath)) {
            return `File not found: ${absPath}`;
          }
          const src = readFileSync(absPath, "utf8");
          const lines = src.split("\n");
          const hits = [];
          lines.forEach((line, i) => {
            // Match `sorry` as a word (not inside a comment that's already a note)
            if (/\bsorry\b/.test(line)) {
              const lineNum = i + 1;
              const start = Math.max(0, i - 3);
              const end = Math.min(lines.length - 1, i + 1);
              const ctx = lines
                .slice(start, end + 1)
                .map((l, j) => {
                  const n = start + j + 1;
                  const marker = n === lineNum ? ">>>" : "   ";
                  return `${marker} ${String(n).padStart(4)} | ${l}`;
                })
                .join("\n");
              hits.push(`sorry at line ${lineNum}:\n${ctx}`);
            }
          });
          if (hits.length === 0) return `No \`sorry\` found in ${absPath}`;
          return (
            `Found ${hits.length} sorry(s) in ${absPath}:\n\n` +
            hits.join("\n\n" + "─".repeat(60) + "\n\n")
          );
        },
      }),
    },

    // ── post-edit diagnostic reminder ─────────────────────────────────────
    // After any Edit or Write to a .lean file, append a reminder to run
    // lean_lsp_lean_diagnostic_messages before writing more code.
    "tool.execute.after": async (input, output) => {
      const editToolNames = ["edit_file", "write_file", "Edit", "Write", "patch_file", "str_replace_editor"];
      const isEdit = editToolNames.some(
        (t) => input.tool === t || input.tool.toLowerCase() === t.toLowerCase()
      );
      if (!isEdit) return;

      // Only trigger for .lean files — check the output payload for a path
      try {
        const payload = JSON.stringify(output ?? "");
        if (!payload.includes(".lean")) return;

        const reminder =
          "\n\n⚠️  Lean file modified — call `lean_lsp_lean_diagnostic_messages` " +
          "with the absolute file path NOW before writing any more tactics.";

        // Try common result-field names used by different OpenCode versions
        if (output && typeof output === "object") {
          for (const key of ["result", "content", "output", "text", "message"]) {
            if (typeof output[key] === "string") {
              output[key] += reminder;
              return;
            }
          }
        }
      } catch {
        // Silent: never let a hook crash the tool call
      }
    },
  };
};

export default LeanToolsPlugin;
