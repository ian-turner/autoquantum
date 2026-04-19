import path from "path"
import { tool } from "@opencode-ai/plugin"
import { spawn } from "child_process"
import fs from "fs"

const MAX_OUTPUT_CHARS = 12000
const MAX_OUTPUT_LINES = 160

function logError(error: any, toolName: string) {
  const logFile = "/tmp/lean-tool-error.log"
  const message = `[${new Date().toISOString()}] ${toolName}: ${error?.stack || error}\n`
  fs.appendFileSync(logFile, message)
}

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
  return new Promise<{ command: string; exitCode: number; stdout: string; stderr: string }>((resolve, reject) => {
    const proc = spawn(command[0], command.slice(1), {
      cwd,
      stdio: ["pipe", "pipe", "pipe"],
    })

    let stdout = ""
    let stderr = ""

    proc.stdout.on("data", (data) => {
      stdout += data.toString()
    })

    proc.stderr.on("data", (data) => {
      stderr += data.toString()
    })

    proc.on("close", (exitCode) => {
      resolve({
        command: command.join(" "),
        exitCode: exitCode ?? 0,
        stdout: trimOutput(stdout),
        stderr: trimOutput(stderr),
      })
    })

    proc.on("error", (error) => {
      reject(error)
    })
  })
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
    try {
      logError("build execute called", "lean_build")
      const target = args.target?.trim() || "AutoQuantum"
      const command = target ? ["lake", "build", target] : ["lake", "build"]
      logError(`Running command: ${command.join(" ")} in ${leanRoot(context.worktree)}`, "lean_build")
      const result = await run(command, leanRoot(context.worktree))
      logError(`Command succeeded: exit ${result.exitCode}`, "lean_build")
      // Format as ToolResult string
      const output = `Command: ${result.command}\nExit code: ${result.exitCode}\n${result.stdout ? `Stdout:\n${result.stdout}\n` : ''}${result.stderr ? `Stderr:\n${result.stderr}\n` : ''}`.trim()
      return output
    } catch (error) {
      logError(error, "lean_build")
      throw error
    }
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
    try {
      logError("check_file execute called", "lean_check_file")
      const file = args.file.trim()
      if (!file.endsWith(".lean")) {
        throw new Error("file must end with .lean")
      }
      const command = ["lake", "env", "lean", file]
      logError(`Running command: ${command.join(" ")} in ${leanRoot(context.worktree)}`, "lean_check_file")
      const result = await run(command, leanRoot(context.worktree))
      logError(`Command succeeded: exit ${result.exitCode}`, "lean_check_file")
      // Format as ToolResult string
      const output = `Command: ${result.command}\nExit code: ${result.exitCode}\n${result.stdout ? `Stdout:\n${result.stdout}\n` : ''}${result.stderr ? `Stderr:\n${result.stderr}\n` : ''}`.trim()
      return output
    } catch (error) {
      logError(error, "lean_check_file")
      throw error
    }
  },
})
