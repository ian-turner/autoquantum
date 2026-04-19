export const LeanCompactionPlugin = async () => {
  return {
    "experimental.session.compacting": async (_input, output) => {
      output.prompt = `
You are generating a compact continuation prompt for an OpenCode session in a Lean 4 verification project.

Preserve only information that is still operationally relevant:
- Current task and status
- Active Lean file and theorem/definition names
- Current proof state, blockers, diagnostics, or failing commands
- Concrete next steps
- Files currently being edited

Omit:
- Repeated search output
- Old tool logs that are no longer actionable
- Narrative discussion
- Any detail already superseded by later edits or diagnostics

Keep the result short, structured, and optimized for resuming theorem proving work with minimal tokens.
`.trim()
    }
  }
}
