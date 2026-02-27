# Technical Specification: Phase 3 - MCP Configuration & Setup

- **Functional Specification:** [context/spec/003-mcp-configuration-setup/functional-spec.md](context/spec/003-mcp-configuration-setup/functional-spec.md)
- **Status:** Completed
- **Author(s):** Claude (via awos:tech)

---

## 1. High-Level Technical Approach

This phase establishes repo-local MCP configuration for external tool integrations (GitLab, Jira, Confluence, Slack). The approach:

1. Create an example configuration file (`mcp-config-example.json`) with placeholder credentials for all four integrations
2. Ensure `.mcp.json` is gitignored (already complete)
3. Update existing setup documentation to reference repo-local `.mcp.json` instead of global `~/.claude/mcp.json`
4. Update SKILL.md files to include MCP error handling instructions
5. Provide manual testing procedures in updated documentation

**Key Architectural Decision**: Use repo-local `.mcp.json` instead of global configuration to allow team-specific credentials per repository.

---

## 2. Proposed Solution & Implementation Plan

### 2.1. Example Configuration File

**File:** `mcp-config-example.json` (repo root)

**Structure:**
```json
{
  "mcpServers": {
    "gitlab": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gitlab"],
      "env": {
        "GITLAB_PERSONAL_ACCESS_TOKEN": "YOUR_GITLAB_TOKEN_HERE",
        "GITLAB_API_URL": "https://gitlab.com/api/v4"
      }
    },
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-atlassian"],
      "env": {
        "ATLASSIAN_URL": "https://your-domain.atlassian.net",
        "ATLASSIAN_EMAIL": "your-email@example.com",
        "ATLASSIAN_API_TOKEN": "YOUR_JIRA_CONFLUENCE_TOKEN_HERE"
      }
    },
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "YOUR_SLACK_BOT_TOKEN_HERE",
        "SLACK_TEAM_ID": "YOUR_SLACK_TEAM_ID_HERE"
      }
    }
  }
}
```

**Key Details:**
- Jira and Confluence share the `atlassian` MCP server with a single API token
- All four integrations in one file (users can omit sections they don't need)
- Placeholder values clearly marked with `YOUR_*_HERE` pattern
- Include comments in the JSON file explaining each field

### 2.2. Documentation Updates

**Files to Update:**
- `docs/setup-gitlab-mcp.md`
- `docs/setup-jira-mcp.md`
- `docs/setup-confluence-mcp.md`
- `docs/setup-slack-mcp.md`

**Changes per file:**

| Section | Current | Updated |
|---------|---------|---------|
| Configuration Location | `~/.claude/mcp.json` | `.mcp.json` in repository root |
| Setup Instructions | Direct JSON editing | 1. Copy `mcp-config-example.json` to `.mcp.json`<br>2. Edit `.mcp.json` to replace placeholders<br>3. Verify `.mcp.json` is in `.gitignore` |
| Manual Testing | (varies by doc) | Add specific manual testing steps (see section 2.4) |

**Additional Content to Add:**

Each doc should include:
- **Prerequisites section**: Token permissions, workspace access requirements
- **Step-by-step setup**: Detailed token creation, configuration, and verification
- **Manual testing section**: How to verify the MCP connection works
- **Troubleshooting section**: Common issues (auth failures, network errors, permission errors)

### 2.3. Skill Updates (SKILL.md files)

**Skills requiring MCP error message updates:**

| Skill | File | MCP Requirement | Update Location | Error Message |
|-------|------|-----------------|-----------------|---------------|
| `/add-team-members` | `.claude/skills/add-team-members/SKILL.md` | GitLab (optional) | Step 6.3 (Fallback) | "GitLab MCP not configured. Auto-detection unavailable. See: docs/setup-gitlab-mcp.md" |
| `/import-slack-channel` | `.claude/skills/import-slack-channel/SKILL.md` | Slack (required) | Step 3 | Verify existing error message matches pattern |
| `/team-status` | `.claude/skills/team-status/SKILL.md` | GitLab/Jira (optional) | Add new step for MCP check | "MCP integrations not configured. Showing local data only. See: docs/setup-gitlab-mcp.md or docs/setup-jira-mcp.md" |

**Error Message Pattern (standardized):**

```markdown
**Error Handling:**
- If [Integration] MCP is not available, display error:
  ```
  Error: [Integration] MCP not configured.

  To use this feature, configure [Integration] MCP integration.
  See documentation: docs/setup-[integration]-mcp.md

  [Optional: Alternative action if applicable]
  ```
- [Action: Stop execution / Continue with limited functionality]
```

### 2.4. Manual Testing Procedures

**Document in each setup doc:**

#### 1. Configuration Validation
```bash
# Verify file exists
ls -la .mcp.json

# Verify it's gitignored
git check-ignore .mcp.json  # Should output: .mcp.json

# Verify JSON is valid
cat .mcp.json | jq .  # Should parse without errors
```

#### 2. Connection Test (per integration)

**GitLab MCP Test:**
1. Open Claude Code in the repository
2. Run `/add-team-members --team=<any-team>`
3. Enter a member name that exists in your GitLab instance
4. Verify Claude searches GitLab and presents user options
5. If error appears, check token permissions and API URL

**Slack MCP Test:**
1. Open Claude Code in the repository
2. Run `/import-slack-channel --team=<any-team>`
3. Enter a channel search keyword
4. Verify Claude lists Slack channels
5. If error appears, check bot token and team ID

**Jira/Confluence MCP Test** (Future Phase):
- Test when Jira/Confluence-dependent skills are implemented

#### 3. Error Message Test
1. Rename `.mcp.json` to `.mcp.json.backup`
2. Run a skill requiring MCP (e.g., `/import-slack-channel`)
3. Verify error message appears with doc reference
4. Restore: `mv .mcp.json.backup .mcp.json`

### 2.5. File Changes Summary

| File | Action | Content |
|------|--------|---------|
| `mcp-config-example.json` | CREATE | Example MCP config with placeholders for all 4 integrations |
| `.gitignore` | VERIFY | Ensure `.mcp.json` is listed (already complete) |
| `docs/setup-gitlab-mcp.md` | UPDATE | Change to repo-local config, add manual testing section |
| `docs/setup-jira-mcp.md` | UPDATE | Change to repo-local config, add manual testing section |
| `docs/setup-confluence-mcp.md` | UPDATE | Change to repo-local config, add manual testing section |
| `docs/setup-slack-mcp.md` | UPDATE | Change to repo-local config, add manual testing section |
| `.claude/skills/add-team-members/SKILL.md` | UPDATE | Add GitLab MCP error message to Step 6.3 |
| `.claude/skills/import-slack-channel/SKILL.md` | VERIFY | Confirm existing error message matches pattern |
| `.claude/skills/team-status/SKILL.md` | UPDATE | Add MCP availability check with graceful degradation |

---

## 3. Impact and Risk Analysis

### 3.1. System Dependencies

**Internal Dependencies:**
- Skills depend on SKILL.md documentation being accurate
- Claude Code's ability to detect available MCP servers at runtime
- Existing skills must gracefully handle missing MCP configuration

**External Dependencies:**
- MCP server packages: `@modelcontextprotocol/server-gitlab`, `@modelcontextprotocol/server-atlassian`, `@modelcontextprotocol/server-slack`
- Node.js/npx availability for running MCP servers
- Network access to external services (GitLab, Jira, Confluence, Slack)

### 3.2. Potential Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Credentials accidentally committed** | HIGH - Security breach | `.mcp.json` already in `.gitignore`; add pre-commit hook check (future) |
| **Incomplete/incorrect documentation** | MEDIUM - Users can't configure MCP | Manual testing procedures included in each doc; peer review required |
| **MCP server version compatibility** | MEDIUM - Skills fail unexpectedly | Document required MCP server versions in setup docs; test with latest stable versions |
| **Network/firewall blocking MCP** | MEDIUM - Can't reach external services | Error messages guide users to check connectivity; skills degrade gracefully |
| **Token permission issues** | MEDIUM - MCP auth fails | Document exact required permissions in each setup guide; provide troubleshooting section |
| **Partial configuration confusion** | LOW - Users unclear which integrations work | Error messages specify exactly which MCP is missing; each skill checks independently |

---

## 4. Testing Strategy

### 4.1. Manual Testing Approach

**Phase 3 uses manual testing only** (per functional spec). No automated test scripts are created.

**Testing Checklist:**

- [ ] **Example File**: Verify `mcp-config-example.json` has valid JSON structure and all placeholder values are clearly marked
- [ ] **Gitignore**: Confirm `.mcp.json` is in `.gitignore` and git doesn't track it
- [ ] **Documentation Accuracy**: Follow each setup doc step-by-step and verify instructions work
- [ ] **GitLab MCP**: Configure GitLab, test `/add-team-members` with user search
- [ ] **Slack MCP**: Configure Slack, test `/import-slack-channel` with channel search
- [ ] **Error Messages**: Test each skill without MCP configured and verify error messages appear correctly
- [ ] **Partial Configuration**: Configure only GitLab, verify GitLab skills work and Slack skills show error
- [ ] **Token Rotation**: Test with expired/invalid tokens and verify error messages are helpful

### 4.2. Test Scenarios

**Scenario 1: Fresh Setup (No MCP)**
1. Clone repository
2. Run `/import-slack-channel`
3. Verify error: "Slack MCP not configured" with doc reference

**Scenario 2: GitLab Only Configuration**
1. Copy example config to `.mcp.json`
2. Configure GitLab section only (leave Slack blank)
3. Test `/add-team-members` with GitLab search - should work
4. Test `/import-slack-channel` - should show error

**Scenario 3: All Four Integrations**
1. Configure all sections in `.mcp.json`
2. Test each integration independently
3. Verify all skills work as expected

**Scenario 4: Invalid Credentials**
1. Configure `.mcp.json` with invalid token
2. Test skill requiring that MCP
3. Verify error message is clear and actionable

---
