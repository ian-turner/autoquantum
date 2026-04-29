import { tool } from "@opencode-ai/plugin";
import { existsSync, readFileSync } from "fs";
import { join, isAbsolute } from "path";

export const LeanToolsPlugin = async ({ directory, client, $ }) => {
  const leanRoot = join(directory, "lean");
  const proofWriterGoals = new Map();
  const proofWriterSessions = new Set();
  const activeComparatorSessions = new Set();

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

  function stemToTheorem(stem) {
    const firstPass = stem.replace(/(.)([A-Z][a-z]+)/g, "$1_$2");
    const secondPass = firstPass.replace(/([a-z0-9])([A-Z])/g, "$1_$2");
    return `${secondPass.toLowerCase()}_goal`;
  }

  function goalPaths(stem) {
    return {
      goalFile: join(leanRoot, "Goals", `${stem}.lean`),
      solutionFile: join(leanRoot, "Solutions", `${stem}.lean`),
    };
  }

  function extractGoalStem(text) {
    if (!text) return null;
    const patterns = [
      /(?:^|\b)goal\s*[:=]\s*([A-Za-z0-9_]+)\b/i,
      /(?:^|\b)goal\s+([A-Za-z0-9_]+)\b/i,
      /lean\/Goals\/([A-Za-z0-9_]+)\.lean\b/,
      /Goals\.([A-Za-z0-9_]+)\b/,
      /lean\/Solutions\/([A-Za-z0-9_]+)\.lean\b/,
      /Solutions\.([A-Za-z0-9_]+)\b/,
    ];
    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match) return match[1];
    }
    return null;
  }

  async function runComparatorGoal(stem) {
    const command = $`python3 scripts/verify_comparator.py --goal ${stem}`
      .cwd(directory)
      .quiet()
      .nothrow();
    const completed = await command;
    const stdout = completed.stdout.toString("utf8").trim();
    const stderr = completed.stderr.toString("utf8").trim();
    const transcript = [stdout, stderr].filter(Boolean).join("\n");
    return {
      ok: completed.exitCode === 0,
      exitCode: completed.exitCode,
      transcript:
        transcript ||
        `scripts/verify_comparator.py exited with status ${completed.exitCode}`,
    };
  }

  async function verifyProofWriterSession(sessionID) {
    if (activeComparatorSessions.has(sessionID)) return;
    if (!proofWriterSessions.has(sessionID)) return;

    const stem = proofWriterGoals.get(sessionID);
    activeComparatorSessions.add(sessionID);
    try {
      if (!stem) {
        await client.tui.showToast({
          directory,
          title: "Comparator skipped",
          message: "Could not identify the goal stem from the prompt — mention a file name or goal name (e.g. 'prove the goal in NC_Ex4_2.lean').",
          variant: "error",
          duration: 8000,
        });
        return;
      }

      const result = await runComparatorGoal(stem);
      await client.tui.showToast({
        directory,
        title: result.ok ? "Comparator passed" : "Comparator failed",
        message: `${stem}: ${result.transcript.split("\n")[0]}`,
        variant: result.ok ? "success" : "error",
        duration: 8000,
      });
    } finally {
      activeComparatorSessions.delete(sessionID);
    }
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

      // ── lean_goal_context ────────────────────────────────────────────────
      // Reads a comparator goal pair and returns the exact theorem/module
      // contract that a proof-writing agent should satisfy.
      lean_goal_context: tool({
        description:
          "Load the trusted comparator goal contract for a goal stem in " +
          "`lean/Goals/<Stem>.lean` and show the matching `Solutions` target.",
        args: {
          goal: tool.schema
            .string()
            .describe("Goal stem, for example `Comm` or `HPlusCorrect`"),
        },
        async execute({ goal }) {
          const { goalFile, solutionFile } = goalPaths(goal);
          if (!existsSync(goalFile)) {
            return `Goal file not found: ${goalFile}`;
          }

          const theoremName = stemToTheorem(goal);
          const goalSource = readFileSync(goalFile, "utf8").trim();
          const solutionExists = existsSync(solutionFile);
          const solutionSource = solutionExists
            ? readFileSync(solutionFile, "utf8").trim()
            : "-- file does not exist yet";

          return [
            `Goal stem: ${goal}`,
            `Theorem name: ${theoremName}`,
            `Challenge module: Goals.${goal}`,
            `Solution module: Solutions.${goal}`,
            `Goal file: ${goalFile}`,
            `Solution file: ${solutionFile}`,
            "",
            "Trusted goal source:",
            "```lean",
            goalSource,
            "```",
            "",
            solutionExists ? "Current solution source:" : "Current solution source: missing",
            "```lean",
            solutionSource,
            "```",
            "",
            "Do not edit `lean/Goals/*`. Keep the solution theorem statement aligned",
            "with the trusted goal, and do not import the corresponding `Goals.*` module.",
          ].join("\n");
        },
      }),

      // ── verify_comparator_goal ───────────────────────────────────────────
      // Runs the comparator verification script for one goal stem so the
      // result appears directly in the chat transcript.
      verify_comparator_goal: tool({
        description:
          "Run `scripts/verify_comparator.py --goal <Stem>` for a single " +
          "comparator goal and return the full transcript.",
        args: {
          goal: tool.schema
            .string()
            .describe("Goal stem, for example `Comm` or `HPlusCorrect`"),
        },
        async execute({ goal }, context) {
          context.metadata({
            title: `Comparator ${goal}`,
            metadata: { goal },
          });
          const result = await runComparatorGoal(goal);
          return {
            output: [
              `Comparator goal: ${goal}`,
              `Exit code: ${result.exitCode}`,
              "",
              result.transcript,
            ].join("\n"),
            metadata: {
              goal,
              exitCode: result.exitCode,
              ok: result.ok,
            },
          };
        },
      }),
    },

    "chat.message": async (input, output) => {
      if (input.agent && input.agent !== "prove") {
        proofWriterSessions.delete(input.sessionID);
        return;
      }
      if (input.agent !== "prove") return;
      proofWriterSessions.add(input.sessionID);
      const promptText = output.parts
        .filter((part) => part.type === "text")
        .map((part) => part.text)
        .join("\n");
      const goalStem = extractGoalStem(promptText);
      if (goalStem) {
        proofWriterGoals.set(input.sessionID, goalStem);
      }
    },

    event: async ({ event }) => {
      if (event.type !== "session.idle") return;
      await verifyProofWriterSession(event.properties.sessionID);
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
        const touchedLeanFile = JSON.stringify(input.args ?? "").includes(".lean");
        if (!touchedLeanFile) return;

        output.output +=
          "\n\n⚠️  Lean file modified — call `lean_lsp_lean_diagnostic_messages` " +
          "with the absolute file path NOW before writing any more tactics.";
      } catch {
        // Silent: never let a hook crash the tool call
      }
    },
  };
};

export default LeanToolsPlugin;
