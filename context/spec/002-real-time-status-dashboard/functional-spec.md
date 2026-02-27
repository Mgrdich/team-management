# Functional Specification: Real-time Status Dashboard

- **Roadmap Item:** Real-time Status Dashboard
- **Status:** Draft
- **Author:** Claude
- **Date:** 2026-02-27

---

## 1. Overview and Rationale (The "Why")

### Problem Statement
Engineering managers using Claude Code need instant visibility into their team's current work without switching between multiple tools. Today, Jordan (our Engineering Manager persona) must jump between Jira, GitLab, and Slack to answer simple questions like "What is everyone working on?" or "What's blocking the payment feature?" This context-switching breaks flow and often results in stale or incomplete information.

### Solution
The `/team-status` command provides real-time visibility into team tasks and progress by fetching data directly from Jira and GitLab via MCP integration. Managers can run the command with no parameters for a quick overview, or use natural language queries to drill into specific areas (e.g., "show blocked tasks", "sarah's work", "auth feature status").

### Success Metrics
- Managers can get team status in under 5 seconds without leaving Claude Code
- Zero context switches to external tools for basic status queries
- Questions about team status answered with a single command

---

## 2. Functional Requirements (The "What")

### 2.1 Default Team Status View

**As a** manager, **I want to** run `/team-status` to see my team's active tasks, **so that** I can quickly understand what everyone is working on.

**Acceptance Criteria:**
- [ ] When I run `/team-status` without `--team` parameter, the system prompts me to select a team using AskUserQuestion (lists all teams from `.team/` directory)
- [ ] When I run `/team-status --team=team-alpha`, the system fetches real-time data from:
  - Jira: All tasks assigned to team members (by matching Jira assignee email to `members.json` emails) AND all tasks in Jira projects linked in team's `projects.json`
  - GitLab: All issues/MRs assigned to team members (by matching GitLab assignee to `git_email` in `members.json`) AND all issues/MRs in GitLab projects linked in team's `projects.json`
- [ ] The output is a table with columns: `Member | Task ID | Title | Status`
- [ ] Only active tasks are shown (excludes Done, Closed, Resolved, or equivalent completed statuses in Jira/GitLab)
- [ ] If a task is assigned to someone NOT in `members.json`, the task is still shown with the assignee's actual name from Jira/GitLab
- [ ] Team members with zero active tasks are not shown in the table
- [ ] For GitLab merge requests:
  - If the team's project has linked GitLab repositories in `projects.json`, query those repos directly
  - If no GitLab repos are linked, attempt to extract MR links from Jira ticket fields (e.g., "Git Integration" custom field, comments, or links)
- [ ] Member names are enriched with Slack display names if Slack MCP is available (falls back to names from `members.json`)

**Example Output:**
```
Member          | Task ID      | Title                      | Status
------------------------------------------------------------------------
Sarah Johnson   | PROJ-123     | Auth refactor              | In Progress
Sarah Johnson   | PROJ-125     | Login bug fix              | Blocked
John Doe        | PROJ-130     | Payment integration        | In Progress
John Doe        | !456         | Fix payment gateway MR     | Open
Alice Johnson   | PROJ-140     | Database migration         | In Progress
```

### 2.2 Filtered Status by Team Member

**As a** manager, **I want to** filter status to a specific team member, **so that** I can see what one person is working on.

**Acceptance Criteria:**
- [ ] When I run `/team-status --team=team-alpha --member=sarah`, the table shows only tasks assigned to Sarah Johnson
- [ ] The `--member` parameter accepts:
  - First name only (e.g., `--member=sarah`)
  - Full name (e.g., `--member="Sarah Johnson"`)
  - Email (e.g., `--member=sarah@example.com`)
- [ ] If multiple members match (e.g., two people named "Sarah"), the system prompts me to select the specific member using AskUserQuestion
- [ ] If no member matches, the system displays: "No team member found matching 'sarah'. Available members: [list]"

### 2.3 Natural Language Query Support

**As a** manager, **I want to** ask natural language questions about team status, **so that** I can get specific information without memorizing parameter syntax.

**Acceptance Criteria:**
- [ ] When I run `/team-status --team=team-alpha "blocked tasks"`, the table shows only tasks with status Blocked or equivalent
- [ ] When I run `/team-status --team=team-alpha "sarah's work"` or `"what is sarah working on"`, the table filters to Sarah's tasks only
- [ ] When I run `/team-status --team=team-alpha "auth feature"`, the table shows tasks whose title or description contains "auth" (case-insensitive keyword search)
- [ ] Natural language queries can combine filters: `"sarah's blocked tasks"` shows only Sarah's blocked items
- [ ] Common query patterns recognized:
  - "blocked" / "blockers" → filter to blocked status
  - "in progress" → filter to in-progress status
  - Member names → filter to that member
  - Keywords → search task titles/descriptions
  - "merge requests" / "MRs" → show only GitLab MRs
  - "jira only" → show only Jira tasks
- [ ] If the query cannot be parsed, the system shows the default view with a message: "Showing default view. Try queries like 'blocked tasks', 'sarah's work', or 'auth feature'."

### 2.4 Adaptive Output Detail

**As a** manager, **I want to** request additional detail when needed, **so that** I can see more context about tasks.

**Acceptance Criteria:**
- [ ] Default table columns: `Member | Task ID | Title | Status`
- [ ] When I ask for more detail (e.g., "show source", "show last updated", "show merge requests"), the table adds requested columns:
  - `Source`: Jira or GitLab
  - `Last Updated`: Timestamp of last task update
  - `MR Status`: For GitLab MRs, show Draft/Ready/Merged
  - `Blocker Reason`: If task is blocked, show dependency or reason (if available in Jira/GitLab)
  - `Assignee Email`: Show full email address
- [ ] Requests for detail are interpreted from natural language (e.g., "show more details", "include source", "show when tasks were updated")
- [ ] Additional columns appear after the default columns

**Example with Detail:**
```
Member        | Task ID  | Title          | Status      | Source | Last Updated
------------------------------------------------------------------------------------
Sarah Johnson | PROJ-123 | Auth refactor  | In Progress | Jira   | 2026-02-27 10:30
```

### 2.5 MCP Configuration Handling

**As a** manager, **I want to** receive clear guidance when MCPs are not configured, **so that** I can set them up properly.

**Acceptance Criteria:**
- [ ] If Jira MCP is not configured, the system displays: "Jira MCP not configured. Team status requires Jira integration. See docs/setup-jira-mcp.md for setup instructions."
- [ ] If GitLab MCP is not configured but Jira is, the system displays the table with Jira data only and shows a warning: "GitLab MCP not configured. Showing Jira data only. To include GitLab issues and MRs, see docs/setup-gitlab-mcp.md"
- [ ] If Slack MCP is not configured, member names fall back to names from `members.json` (no error shown, graceful degradation)
- [ ] Error messages include direct links to setup documentation
- [ ] The command does not proceed if Jira MCP is unavailable (Jira is required)

### 2.6 Empty State Handling

**As a** manager, **I want to** see appropriate messages when there's no data to display, **so that** I understand the current state.

**Acceptance Criteria:**
- [ ] If the entire team has zero active tasks, the system displays: "No active tasks found for team-alpha. All clear!"
- [ ] If a filtered query returns no results, the system displays: "No tasks match your query: 'blocked tasks'. Try a different search."
- [ ] If a team member is specified but they have no tasks, the system displays: "Sarah Johnson has no active tasks."

---

## 3. Scope and Boundaries

### In-Scope

- `/team-status` command with optional `--team` and `--member` parameters
- Natural language query parsing for common patterns (blocked, member names, keywords)
- Real-time data fetching from Jira via MCP (no local caching)
- Real-time data fetching from GitLab via MCP when configured
- GitLab MR extraction from Jira ticket fields when GitLab repos not linked
- Table output format (always table, adaptive columns)
- Team selection prompt when `--team` not provided
- Display of external assignees (not in team's `members.json`)
- MCP availability checking and clear error messages with setup links
- Slack MCP integration for enriched member display names
- Filtering by member, status, keywords
- Adaptive detail (show more columns on request)

### Out-of-Scope

- **Sprint/milestone tracking** - Removed from roadmap, not included in this feature
- **Local data caching or storage** - All data fetched on-demand from external systems
- **Web or graphical interface** - CLI table output only
- **Export to CSV, JSON, or other formats** - Table output only for this version
- **Historical trend analysis** - Real-time view only, no historical data
- **Saved filters or query bookmarks** - Each command runs fresh
- **Email or Slack notifications** - View-only command, no notifications
- **Task editing or status updates** - Read-only view (future features may add editing)
- **Individual Progress Tracking** - Separate roadmap item with dedicated specification
- **Dependency & Blocker Management** - Separate roadmap item, only displays blocked status in this feature
- **Natural Language Task Creation** - Separate roadmap item, only reads tasks in this feature
- **Confluence integration** - Not used in team status display
- **Other team management commands** - `/add-project`, `/add-team-members`, etc. are separate features

---
