# Product Roadmap: Claude Team Manager

_This roadmap outlines our strategic direction based on customer needs and business goals. It focuses on the "what" and "why," not the technical "how."_

---

### Phase 1: Foundation & Core Commands

_The highest priority features that form the core foundation of the team management system._

- [x] **Repository-Based Infrastructure** _(In Progress - 15/377 tasks complete)_
  - [x] **Local Data Storage:** Implement JSON/markdown-based storage in `.team/` directory for all team data (members, projects), version-controlled via git.
  - [x] **Multi-Team Support:** Enable users to initialize and manage multiple teams within the same repository, each with separate data structures and configurations.
  - [ ] **Git-Based Team Discovery:** Automatically detect and populate team members from git commit history and repository contributors.

- [x] **Basic Command Framework** _(Partially Complete)_
  - [x] **Team Initialization:** Provide `/team-init` command to set up team management structure in the repository, supporting multiple team instances.
  - [x] **Team Listing:** Provide `/list-teams` command to view all initialized teams with member and project counts.
  - [x] **Member Management:** Provide `/add-team-members` command to add members manually (supports GitLab MCP auto-detection when configured).
  - [ ] **Task Management Commands:** Enable creation, assignment, and status updates of tasks through dedicated CLI commands (`/create-task`, `/assign-task`, etc.).
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

**Note:** The `/add-team-members` skill (Slice 4) is already built with GitLab MCP support. Once GitLab MCP is configured, it will automatically search GitLab users by name and present matching accounts for selection.

- [ ] **GitLab MCP Setup**
  - [ ] **Create MCP Configuration:** Write `.claude/mcp/gitlab.json` or add to `~/.claude/mcp.json` with GitLab server URL and authentication token
  - [ ] **Test Connection:** Verify GitLab MCP can connect and authenticate successfully
  - [ ] **Test User Search:** Verify `search_users` function works (required by `/add-team-members` skill)
  - [ ] **Document Setup:** Create `docs/setup-gitlab-mcp.md` with step-by-step configuration instructions
  - [ ] **Verify in Skills:** Test `/add-team-members` skill with GitLab MCP enabled and confirm auto-detection works

- [ ] **Jira MCP Setup**
  - [ ] **Create MCP Configuration:** Write MCP config with Jira instance URL and API token
  - [ ] **Test Connection:** Verify Jira MCP can connect and authenticate
  - [ ] **Test Board Search:** Verify board/project search functions work
  - [ ] **Document Setup:** Create `docs/setup-jira-mcp.md` with configuration instructions

- [ ] **Confluence MCP Setup**
  - [ ] **Create MCP Configuration:** Write MCP config with Confluence URL and authentication
  - [ ] **Test Connection:** Verify Confluence MCP can connect and authenticate
  - [ ] **Test Space Search:** Verify space and page search functions work
  - [ ] **Document Setup:** Create `docs/setup-confluence-mcp.md` with configuration instructions

- [ ] **Slack MCP Setup**
  - [ ] **Create MCP Configuration:** Write MCP config with Slack workspace token
  - [ ] **Test Connection:** Verify Slack MCP can connect and authenticate
  - [ ] **Test Channel/Member Search:** Verify channel listing and member search functions work
  - [ ] **Document Setup:** Create `docs/setup-slack-mcp.md` with configuration instructions

---

### Phase 4: External Tool Integrations

_Once MCP is configured, implement advanced integrations that leverage external tool data._

- [ ] **GitLab Advanced Integration**
  - [ ] **Issue Sync:** Bi-directional sync between local tasks and GitLab issues
  - [ ] **Merge Request Tracking:** Pull and display open merge requests, link them to tasks, and track review status
  - [ ] **Activity Integration:** Show GitLab commits and pipeline status in member progress views
  - [ ] **Webhook Support:** Set up webhooks to receive real-time updates from GitLab

- [ ] **Jira Advanced Integration**
  - [ ] **Ticket Sync:** Bi-directional sync between local tasks and Jira tickets (status, assignee, description)
  - [ ] **Sprint Integration:** Link local sprint data with Jira sprints
  - [ ] **Burndown Charts:** Generate burndown data from Jira ticket progress

- [ ] **Confluence Integration**
  - [ ] **Documentation Access:** Implement `/confluence-search` command to search and access team documentation
  - [ ] **Context Linking:** Link Confluence pages to tasks and sprints for easy reference
  - [ ] **Documentation Display:** Render Confluence page summaries directly in CLI output

- [ ] **Slack Integration**
  - [ ] **Blocker Detection:** Monitor designated Slack channels for blocker mentions and automatically create/update blocked task status
  - [ ] **Status Updates to Slack:** Push team status updates and blocker alerts to configured Slack channels
  - [ ] **Conversational Queries:** Allow team members to query task status and blockers directly through Slack using natural language

---
