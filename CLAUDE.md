# Team Management Project - Claude Code Instructions

## Research vs Implementation

When asked to **'research'**, **'analyze'**, or **'explore'** something:
- ONLY gather information and report findings
- Do NOT design solutions, create implementation plans, or write code
- Wait for explicit approval before proceeding to implementation

**Example prompts that require research only:**
- "Research existing retry patterns in the codebase"
- "Analyze how authentication is currently handled"
- "Explore the project structure"

After research is complete, ask: "Would you like me to proceed with implementation based on these findings?"

## Communication

- Always use the `AskUserQuestion` tool to clarify ambiguous requests
- Never respond with plain text questions - use the tool
- When multiple approaches are possible, present options using `AskUserQuestion`

## Naming Conventions

Follow exact naming conventions specified by the user:
- When a naming pattern is provided (e.g., 'add-team-members'), use it exactly
- Do NOT simplify or shorten names (e.g., don't use 'add-member' instead of 'add-team-members')
- Skills should use kebab-case with full descriptive names
- Before creating new files or classes, show proposed names and wait for approval

## Feature Slice Implementation

When implementing feature slices:
1. **Research first**: Analyze existing patterns in the codebase
2. **Ask before designing**: Use `AskUserQuestion` to confirm approach
3. **Follow naming**: Use exact names from roadmap documentation
4. **Implement incrementally**: Get user approval at each major step

## Planning and Checkpoints

Before multi-file changes:
1. Outline files you'll create/modify
2. Provide naming for new classes/methods
3. Confirm your understanding of the scope
4. Wait for approval before proceeding

## Project Context

This is a team management system for Claude Code with:
- YAML configuration files
- Feature slice architecture
- Skills-based interface for users
