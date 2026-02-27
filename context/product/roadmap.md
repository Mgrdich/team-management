# Product Roadmap: Claude Team Manager

_This roadmap outlines our strategic direction based on customer needs and business goals. It focuses on the "what" and "why," not the technical "how."_

---

### Phase 1: Foundation & Core Commands

_The highest priority features that form the core foundation of the team management system._

- [ ] **Repository-Based Infrastructure**
  - [ ] **Local Data Storage:** Implement JSON/markdown-based storage in `.team/` directory for all team data (tasks, members, sprints), version-controlled via git.
  - [ ] **Multi-Team Support:** Enable users to initialize and manage multiple teams within the same repository, each with separate data structures and configurations.
  - [ ] **Git-Based Team Discovery:** Automatically detect and populate team members from git commit history and repository contributors.

- [ ] **Basic Command Framework**
  - [ ] **Team Initialization:** Provide `/team-init` command to set up team management structure in the repository, supporting multiple team instances.
  - [ ] **Task Management Commands:** Enable creation, assignment, and status updates of tasks through dedicated CLI commands (`/create-task`, `/assign-task`, etc.).
  - [ ] **Real-time Status Dashboard:** Implement `/team-status` command to view all active tasks, assignments, and progress in formatted CLI output.

- [ ] **Natural Language Interface**
  - [ ] **Conversational Task Creation:** Allow users to create and manage tasks using natural language (e.g., "create task for API migration and assign to @mike").
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

- [ ] **Sprint Planning & Velocity**
  - [ ] **Sprint Management:** Enable creating and managing sprints through CLI commands (`/sprint-create`, `/sprint-progress`).
  - [ ] **Velocity Tracking:** Calculate and display team velocity metrics based on completed tasks and sprint progress.
  - [ ] **Burndown Visualization:** Show sprint burndown and progress toward milestone completion in CLI output.

- [ ] **MCP Agent Integration**
  - [ ] **Automated Status Detection:** Leverage MCP agents to automatically detect progress from git commits and update task status.
  - [ ] **Intelligent Command Processing:** Use Claude's MCP agents to parse complex natural language commands and execute appropriate actions.

---

### Phase 3: External Tool Integrations

_Features planned for future consideration. Their priority and scope may be refined based on user feedback from earlier phases._

- [ ] **GitLab Integration**
  - [ ] **Authentication Setup:** Implement `/connect-gitlab` command for secure authentication with GitLab API.
  - [ ] **Issue Sync:** Bi-directional sync between local tasks and GitLab issues.
  - [ ] **Merge Request Tracking:** Pull and display open merge requests, link them to tasks, and track review status.
  - [ ] **Activity Integration:** Show GitLab commits and pipeline status in member progress views.

- [ ] **Jira Integration**
  - [ ] **Jira Authentication:** Implement `/connect-jira` command for Jira API connection.
  - [ ] **Ticket Sync:** Bi-directional sync between local tasks and Jira tickets (status, assignee, description).
  - [ ] **Sprint Import:** Import Jira sprint structure and tickets into local team management system.
  - [ ] **Auto-Update:** Automatically push local task status changes back to Jira.

- [ ] **Confluence Integration**
  - [ ] **Documentation Access:** Implement `/confluence-search` command to search and access team documentation without leaving Claude Code.
  - [ ] **Context Linking:** Link Confluence pages to tasks and sprints for easy reference.
  - [ ] **Documentation Display:** Render Confluence page summaries directly in CLI output.

- [ ] **Slack MCP Integration**
  - [ ] **Slack Connection:** Implement `/connect-slack` command to authenticate with Slack workspace via MCP.
  - [ ] **Blocker Detection from Conversations:** Monitor designated Slack channels for blocker mentions and automatically create/update blocked task status.
  - [ ] **Status Updates to Slack:** Push team status updates and blocker alerts to configured Slack channels.
  - [ ] **Conversational Queries:** Allow team members to query task status and blockers directly through Slack using natural language.

---
