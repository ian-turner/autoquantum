import path from "path"
import { tool } from "@opencode-ai/plugin"

const MAX_OUTPUT_CHARS = 12000
const MAX_OUTPUT_LINES = 160

function trimOutput(text: string): string {
  const normalized = text.trim()
  if (!normalized) return ""

  const lines = normalized.split("\n")
  const sliced =
    lines.length > MAX_OUTPUT_LINES ? lines.slice(-MAX_OUTPUT_LINES) : lines
  let result = sliced.join("\n")

  if (result.length > MAX_OUTPUT_CHARS) {
    result = result.slice(result.length - MAX_OUTPUT_CHARS)
  }

  if (result !== normalized) {
    return `[output truncated]\n${result}`
  }

  return result
}

async function run(command: string[], cwd: string) {
  const proc = Bun.spawn(command, {
    cwd,
    stdout: "pipe",
    stderr: "pipe",
  })

  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ])

  return {
    command: command.join(" "),
    exitCode,
    stdout: trimOutput(stdout),
    stderr: trimOutput(stderr),
  }
}

function leanRoot(worktree: string): string {
  return path.join(worktree, "lean")
}

export const build = tool({
  description:
    "Run a fixed Lean build command in the repo's lean/ project. Use this instead of ad-hoc bash for Lean builds.",
  args: {
    target: tool.schema
      .string()
      .optional()
      .describe('Optional Lake target. Defaults to "AutoQuantum".'),
  },
  async execute(args, context) {
    const target = args.target?.trim() || "AutoQuantum"
    const command = target ? ["lake", "build", target] : ["lake", "build"]
    return run(command, leanRoot(context.worktree))
  },
})

export const check_file = tool({
  description:
    "Typecheck a single Lean file in the repo's lean/ project with lake env lean. Use repo-relative paths like AutoQuantum/Gate.lean.",
  args: {
    file: tool.schema
      .string()
      .describe(
        'Path relative to the lean/ directory, for example "AutoQuantum/Gate.lean".'
      ),
  },
  async execute(args, context) {
    const file = args.file.trim()
    if (!file.endsWith(".lean")) {
      throw new Error("file must end with .lean")
    }

    return run(["lake", "env", "lean", file], leanRoot(context.worktree))
  },
})
