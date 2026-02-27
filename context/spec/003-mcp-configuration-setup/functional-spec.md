# Functional Specification: Phase 3 - MCP Configuration & Setup

- **Roadmap Item:** Phase 3: MCP Configuration & Setup
- **Status:** Completed
- **Author:** Claude (via awos:spec)

---

## 1. Overview and Rationale (The "Why")

### Problem
Skills that depend on external tool integrations (GitLab, Jira, Confluence, Slack) do not work without MCP (Model Context Protocol) configuration. Users cannot use implemented features like `/add-team-members` with GitLab auto-detection, Slack channel import, or future Jira/Confluence integrations until MCP is properly configured and authenticated with their organization's external services.

### Solution
This phase provides the infrastructure for users to configure MCP integrations in a repo-local configuration file (`.mcp.json`), with clear documentation, example configurations, and graceful error handling when integrations are missing.

### Success Measurement
- Users can successfully configure MCP for the integrations they need
- `.mcp.json` is properly gitignored to prevent credential leaks
- Skills fail gracefully with clear error messages when MCP is not configured
- Users can work with partial MCP configuration (e.g., only GitLab configured, Jira unconfigured)

---

## 2. Functional Requirements (The "What")

### Requirement 1: Repository-Local MCP Configuration

**As a** team manager using Claude Code, **I want to** configure MCP integrations in my team management repository, **so that** skills can access external tools without exposing my credentials in version control.

**Acceptance Criteria:**
- [x] A `.mcp.json` file can be created in the repository root directory containing MCP configuration for GitLab, Jira, Confluence, and Slack
- [x] The `.mcp.json` file supports a single-file structure with sections for all four integrations
- [x] Users can leave sections blank or omit them entirely for unconfigured integrations (partial configuration is supported)
- [x] The `.mcp.json` file is added to `.gitignore` to prevent accidental credential commits

### Requirement 2: Example Configuration File

**As a** new user setting up MCP, **I want to** have an example configuration file with placeholder values, **so that** I know the correct JSON structure and what credentials I need to provide.

**Acceptance Criteria:**
- [x] A `mcp-config-example.json` file exists in the repository root with placeholder values for all four MCP integrations (GitLab, Jira, Confluence, Slack)
- [x] Placeholder values clearly indicate what needs to be replaced (e.g., `"YOUR_GITLAB_TOKEN_HERE"`, `"YOUR_GITLAB_SERVER_URL"`)
- [x] The example file is committed to version control and serves as the reference template
- [x] Users can copy `mcp-config-example.json` to `.mcp.json` and replace placeholders with real credentials

### Requirement 3: MCP Setup Documentation

**As a** user configuring MCP, **I want to** follow clear setup instructions for each integration, **so that** I can successfully authenticate and test my MCP connections.

**Acceptance Criteria:**
- [x] Existing setup documentation (`docs/setup-gitlab-mcp.md`, `docs/setup-jira-mcp.md`, `docs/setup-confluence-mcp.md`, `docs/setup-slack-mcp.md`) remains accurate and is used as-is
- [x] Users can follow the documentation to obtain necessary credentials (API tokens, server URLs, permissions)
- [x] Documentation includes instructions for manually testing authentication for each MCP integration

### Requirement 4: Graceful Failure with Clear Error Messages

**As a** user running a skill that requires MCP, **I want to** see a clear error message if MCP is not configured, **so that** I understand why the feature isn't working and what to do next.

**Acceptance Criteria:**
- [x] Skills that depend on MCP (e.g., `/add-team-members` with GitLab, `/import-slack-channel`) detect when required MCP configuration is missing
- [x] When MCP is not configured, skills display a generic error message indicating which MCP integration is required (e.g., "GitLab MCP is not configured")
- [x] Error messages appear only when the user attempts to use an affected skill (not at startup or during other commands)

### Requirement 5: Partial Configuration Support

**As a** user, **I want to** be able to configure only the MCP integrations I need, **so that** I can use some features without being forced to set up all four integrations.

**Acceptance Criteria:**
- [x] Users can configure GitLab MCP only and use GitLab-dependent skills while other integrations remain unconfigured
- [x] Users can configure any combination of the four MCP integrations (1, 2, 3, or all 4)
- [x] Skills that don't require MCP or require different MCP integrations work independently of each other

### Requirement 6: Authentication Verification

**As a** user who has configured MCP, **I want to** manually verify that authentication is working, **so that** I have confidence that the integration is correctly set up before using it in my workflow.

**Acceptance Criteria:**
- [x] Users can follow documentation to manually test MCP authentication for each integration they've configured
- [x] Authentication testing confirms the MCP server can connect to the external service and authenticate successfully
- [x] No automated test command is required—manual testing per documentation is sufficient

---

## 3. Scope and Boundaries

### In-Scope

- Creating `.mcp.json` configuration file structure in repository root
- Adding `.mcp.json` to `.gitignore`
- Creating `mcp-config-example.json` with placeholder values for all four integrations
- Referencing existing setup documentation (`docs/setup-gitlab-mcp.md`, etc.) for configuration instructions
- Implementing generic error messages in skills when MCP is not configured
- Supporting partial MCP configuration (users can configure 1-4 integrations)
- Manual authentication testing as documented

### Out-of-Scope

- **Other roadmap phases:** Repository-Based Infrastructure (Phase 1), Basic Command Framework (Phase 1), Natural Language Interface (Phase 1), Individual Progress Tracking (Phase 2), Dependency & Blocker Management (Phase 2), MCP Agent Integration (Phase 2)
- **Automated MCP test commands:** No `/test-mcp-connections` or similar commands; verification is manual per documentation
- **Function testing beyond authentication:** Testing specific MCP functions (e.g., `search_users`, `board_search`) is not required in Phase 3
- **Startup MCP verification:** No automatic checking or warnings about MCP configuration at system startup
- **Updating/rewriting setup documentation:** Existing `docs/setup-*-mcp.md` files are used as-is
- **MCP configuration wizard:** No interactive prompts or inline configuration; users follow documentation
- **Global MCP configuration:** No support for `~/.claude/mcp.json` or other global MCP configs—only repo-local `.mcp.json`
