# Task List: Phase 3 - MCP Configuration & Setup

**Specification:** [Functional Spec](functional-spec.md) | [Technical Spec](technical-considerations.md)

---

## Slice 1: Create Example MCP Configuration File

**Goal:** Users can see an example MCP configuration with placeholders and verify `.mcp.json` is gitignored.

- [x] Create `mcp-config-example.json` in repository root with the structure specified in technical spec (includes all four integrations: gitlab, atlassian, slack) **[Agent: general-purpose]**
- [x] Add inline JSON comments explaining each configuration field and placeholder **[Agent: general-purpose]**
- [x] Verify `.mcp.json` is already present in `.gitignore` file **[Agent: general-purpose]**
- [x] **Manual Test:** Validate JSON structure is correct using `cat mcp-config-example.json | jq .` **[Agent: general-purpose]**
- [x] **Manual Test:** Copy `mcp-config-example.json` to `.mcp.json`, verify `git status` doesn't show `.mcp.json` as untracked **[Agent: general-purpose]**

---

## Slice 2: Update GitLab MCP Setup Documentation

**Goal:** Users can configure GitLab MCP using repo-local `.mcp.json` following clear documentation.

- [x] Update `docs/setup-gitlab-mcp.md` to reference `.mcp.json` in repository root instead of `~/.claude/mcp.json` **[Agent: general-purpose]**
- [x] Update setup instructions section to instruct users to copy `mcp-config-example.json` to `.mcp.json` and edit placeholders **[Agent: general-purpose]**
- [x] Add "Manual Testing" section with configuration validation steps (verify file exists, check gitignore, validate JSON) **[Agent: general-purpose]**
- [x] Add GitLab MCP connection test instructions (run `/add-team-members`, verify user search works) **[Agent: general-purpose]**
- [x] Add "Troubleshooting" section covering common GitLab MCP issues (auth failures, API URL errors, token permissions) **[Agent: general-purpose]**
- [x] **Manual Test:** Follow the updated documentation step-by-step and verify all instructions are accurate and complete **[Agent: general-purpose]**

---

## Slice 3: Update Slack MCP Setup Documentation

**Goal:** Users can configure Slack MCP using repo-local `.mcp.json` following clear documentation.

- [x] Update `docs/setup-slack-mcp.md` to reference `.mcp.json` in repository root instead of `~/.claude/mcp.json` **[Agent: general-purpose]**
- [x] Update setup instructions section to instruct users to copy `mcp-config-example.json` to `.mcp.json` and edit placeholders **[Agent: general-purpose]**
- [x] Add "Manual Testing" section with configuration validation steps **[Agent: general-purpose]**
- [x] Add Slack MCP connection test instructions (run `/import-slack-channel`, verify channel search works) **[Agent: general-purpose]**
- [x] Add "Troubleshooting" section covering common Slack MCP issues (bot token errors, team ID issues, permission errors) **[Agent: general-purpose]**
- [x] **Manual Test:** Follow the updated documentation step-by-step and verify all instructions are accurate and complete **[Agent: general-purpose]**

---

## Slice 4: Update Jira MCP Setup Documentation

**Goal:** Users can configure Jira MCP using repo-local `.mcp.json` following clear documentation.

- [x] Update `docs/setup-jira-mcp.md` to reference `.mcp.json` in repository root (using `atlassian` MCP server) **[Agent: general-purpose]**
- [x] Update setup instructions to show that Jira and Confluence share the same `atlassian` MCP configuration **[Agent: general-purpose]**
- [x] Add "Manual Testing" section with configuration validation steps **[Agent: general-purpose]**
- [x] Add note that Jira MCP connection testing will be available when Jira-dependent skills are implemented **[Agent: general-purpose]**
- [x] Add "Troubleshooting" section covering common Atlassian MCP issues (API token errors, domain URL format, permission scopes) **[Agent: general-purpose]**
- [x] **Manual Test:** Review documentation for accuracy and completeness **[Agent: general-purpose]**

---

## Slice 5: Update Confluence MCP Setup Documentation

**Goal:** Users can configure Confluence MCP using repo-local `.mcp.json` following clear documentation.

- [x] Update `docs/setup-confluence-mcp.md` to reference `.mcp.json` in repository root (using `atlassian` MCP server) **[Agent: general-purpose]**
- [x] Update setup instructions to show that Confluence and Jira share the same `atlassian` MCP configuration **[Agent: general-purpose]**
- [x] Add "Manual Testing" section with configuration validation steps **[Agent: general-purpose]**
- [x] Add note that Confluence MCP connection testing will be available when Confluence-dependent skills are implemented **[Agent: general-purpose]**
- [x] Add "Troubleshooting" section covering common Atlassian MCP issues **[Agent: general-purpose]**
- [x] **Manual Test:** Review documentation for accuracy and completeness **[Agent: general-purpose]**

---

## Slice 6: Update Skills with MCP Error Messages

**Goal:** Skills display clear error messages when required MCP integrations are not configured.

- [x] Update `.claude/skills/add-team-members/SKILL.md` Step 6.3 (Fallback) to add error message: "GitLab MCP not configured. Auto-detection unavailable. See: docs/setup-gitlab-mcp.md" **[Agent: general-purpose]**
- [x] Review `.claude/skills/import-slack-channel/SKILL.md` Step 3 and verify existing error message matches the standardized pattern from technical spec **[Agent: general-purpose]**
- [x] Update `.claude/skills/team-status/SKILL.md` to add MCP availability check step with error message: "MCP integrations not configured. Showing local data only. See: docs/setup-gitlab-mcp.md or docs/setup-jira-mcp.md" **[Agent: general-purpose]**
- [x] **Manual Test:** Remove/rename `.mcp.json`, run `/import-slack-channel`, verify error message displays correctly with doc reference **[Agent: general-purpose]**
- [x] **Manual Test:** Run `/add-team-members` without GitLab MCP configured, verify error message appears when user declines manual Git info entry **[Agent: general-purpose]**
- [x] **Manual Test:** Restore `.mcp.json` after testing **[Agent: general-purpose]**

---

## Recommendations

Since Phase 3 focuses on configuration files and documentation updates (no code implementation), all tasks are appropriately assigned to the `general-purpose` agent. No specialist agents are required for this phase.

| Task/Slice | Issue | Recommendation |
|------------|-------|----------------|
| All slices | Documentation and configuration work uses general-purpose agent | This is appropriate—no specialist agents needed for JSON/Markdown file editing and manual testing guidance |
