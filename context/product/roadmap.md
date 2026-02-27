# Product Roadmap: Claude Team Manager

_This roadmap outlines our strategic direction based on customer needs and business goals. It focuses on the "what" and "why," not the technical "how."_

---

### Phase 1: Foundation & Core Commands

_The highest priority features that form the core foundation of the team management system._

- [x] **Repository-Based Infrastructure** _(Completed - 25/377 tasks complete, 2 deferred to Phase 3)_
  - [x] **Local Data Storage:** Implement JSON/markdown-based storage in `.team/` directory for all team data (members, projects), version-controlled via git.
  - [x] **Multi-Team Support:** Enable users to initialize and manage multiple teams within the same repository, each with separate data structures and configurations.
  - [x] **Member Import:** Replaced git-based discovery with manual addition and Slack channel import for more accurate team rosters.

- [x] **Basic Command Framework** _(Partially Complete)_
  - [x] **Team Initialization:** Provide `/team-init` command to set up team management structure in the repository, supporting multiple team instances.
  - [x] **Team Listing:** Provide `/list-teams` command to view all initialized teams with member and project counts.
  - [x] **Member Management:** Provide `/add-team-members` command to add members manually (supports GitLab MCP auto-detection when configured).
  - [ ] **Real-time Status Dashboard:** Implement `/team-status` command to view all active tasks, assignments, and progress in formatted CLI output.

- [ ] **Natural Language Interface**
  - [ ] **Conversational Task Creation:** Allow users to get progress on tasks using natural language (e.g., "what is happening with the auth feature?").
  - [ ] **Status Queries:** Enable natural language queries about team status (e.g., "who's working on the auth feature?").

---

### Phase 2: Advanced Team Management

_Once the foundational features are complete, we will move on to these high-value additions._

- [ ] **Individual Progress Tracking**
  - [ ] **Member Progress View:** Implement `/member-progress` command to show detailed view of individual developer's current work, recent activity, and contribution history.
  - [ ] **Activity Timeline:** Display chronological view of member's recent commits, task updates, and completions.

- [ ] **Dependency & Blocker Management**
  - [ ] **Blocker Tracking:** Provide commands to mark tasks as blocked and specify dependencies (`/task-blocked`, `/show-blockers`).
  - [ ] **Dependency Visualization:** Automatically visualize task dependencies and blocked items in status views.
  - [ ] **Blocker Notifications:** Alert managers when new blockers are identified or when blocking tasks are completed.

- [ ] **MCP Agent Integration**
  - [ ] **Automated Status Detection:** Leverage MCP agents to automatically detect progress from git commits and update task status.
  - [ ] **Intelligent Command Processing:** Use Claude's MCP agents to parse complex natural language commands and execute appropriate actions.

---

### Phase 3: MCP Configuration & Setup

_Configure and verify external tool integrations via Model Context Protocol (MCP). These are required for skills that depend on external data sources._

**Status:** ✅ **Completed** - Infrastructure and documentation for MCP configuration is complete. Users can now configure MCP integrations using the example file and comprehensive setup documentation.

- [x] **MCP Configuration Infrastructure**
  - [x] **Example Configuration File:** Created `mcp-config-example.json` with placeholder values for all four integrations (GitLab, Atlassian/Jira/Confluence, Slack)
  - [x] **Security:** Verified `.mcp.json` is gitignored to prevent credential leaks
  - [x] **Partial Configuration Support:** Structure supports configuring any combination of integrations (1, 2, 3, or all 4)

- [x] **GitLab MCP Setup Documentation**
  - [x] **Setup Instructions:** Updated `docs/setup-gitlab-mcp.md` to reference repo-local `.mcp.json`
  - [x] **Manual Testing Section:** Added configuration validation and connection test instructions
  - [x] **Troubleshooting:** Added comprehensive troubleshooting section covering auth failures, API URL errors, and token permissions
  - [x] **Skill Error Messages:** Updated `/add-team-members` skill with GitLab MCP error handling

- [x] **Jira MCP Setup Documentation**
  - [x] **Setup Instructions:** Updated `docs/setup-jira-mcp.md` with repo-local configuration and shared Atlassian MCP server guidance
  - [x] **Manual Testing Section:** Added configuration validation steps
  - [x] **Troubleshooting:** Added Atlassian MCP troubleshooting (API token, domain URL, permission scopes)

- [x] **Confluence MCP Setup Documentation**
  - [x] **Setup Instructions:** Updated `docs/setup-confluence-mcp.md` with repo-local configuration and shared Atlassian MCP server guidance
  - [x] **Manual Testing Section:** Added configuration validation steps
  - [x] **Troubleshooting:** Added Atlassian MCP troubleshooting including shared configuration issues

- [x] **Slack MCP Setup Documentation**
  - [x] **Setup Instructions:** Updated `docs/setup-slack-mcp.md` to reference repo-local `.mcp.json`
  - [x] **Manual Testing Section:** Added configuration validation and connection test instructions
  - [x] **Troubleshooting:** Added troubleshooting for bot token, team ID, and permission errors
  - [x] **Skill Error Messages:** Updated `/import-slack-channel` and `/team-status` skills with Slack MCP error handling

---
