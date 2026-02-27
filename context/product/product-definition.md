# Product Definition: Claude Team Manager

- **Version:** 1.0
- **Status:** Proposed

---

## 1. The Big Picture (The "Why")

### 1.1. Project Vision & Purpose

To provide engineering managers with real-time visibility into team velocity and progress without meetings, entirely within the Claude Code environment. Managers can track team progress in real-time during coding sessions by leveraging this repository's commands and MCP agents, eliminating the need to interrupt developers for status updates while maintaining clear oversight of blockers, dependencies, and work in flight.

### 1.2. Target Audience

Tech leads and engineering managers who use Claude Code and oversee development teams (typically 5-15 developers). These leaders are responsible for tracking sprint progress, identifying and resolving blockers, and reporting team velocity to leadership—all while staying within their Claude Code CLI environment.

### 1.3. User Personas

- **Persona 1: "Jordan the Engineering Manager"**
  - **Role:** Engineering Manager overseeing multiple teams (10-15 developers total), daily Claude Code user
  - **Goal:** Needs high-level visibility across projects to report to leadership and identify cross-team dependencies before they become blockers, all without leaving Claude Code
  - **Frustration:** Difficulty tracking blockers and dependencies in real-time. Currently forced to switch between Claude Code, Slack, Jira, GitLab, and Confluence to piece together team status, breaking flow and often discovering blockers too late.

---

## 2. The Product Experience (The "What")

### 2.1. Core Features

- **Claude Code Native Commands** - Dedicated commands for team management (e.g., `/team-status`, `/create-task`, `/sprint-create`)
- **Individual Member Progress Tracking** - View specific team member's current work, recent activity, and contribution history via `/member-progress` command
- **MCP Agent Integration** - Leverage Claude's MCP agents to automate task tracking, status updates, and notifications within the Claude Code environment
- **GitLab Integration** - Sync with GitLab issues, merge requests, and pipelines; pull member activity from GitLab commits and MRs
- **Jira Integration** - Bi-directional sync with Jira tickets, status updates, and sprint planning
- **Confluence Integration** - Link team documentation, sprint retrospectives, and project pages; display relevant docs in context
- **Repository-Based Storage** - All team data stored locally in the repository (JSON/markdown files), version-controlled and synchronized via git
- **Real-time Status Commands** - Run CLI commands to view team dashboard, task lists, blockers, and dependencies instantly
- **Task Creation via Natural Language** - Create and assign tasks using conversational commands processed by Claude
- **Blocker and Dependency Tracking** - Mark task dependencies and blockers through CLI commands, with automatic visualization on status requests
- **Sprint/Milestone Planning** - Group tasks into sprints using dedicated commands, track velocity through automated metrics
- **Git-Based Team Discovery** - Automatically discover team members from git commit history and repo contributors

### 2.2. User Journey

**Initial Setup:**
Jordan clones the Claude Team Manager repository into their local development environment. Within Claude Code, they run `/team-init` which sets up the team management structure in the repo. The system automatically discovers team members from git history. Jordan then runs `/connect-gitlab`, `/connect-jira`, and `/connect-confluence` to authenticate and link the team's external tools, enabling seamless data sync.

**Daily Workflow:**
Each morning, Jordan opens Claude Code and runs `/team-status` to view the real-time team dashboard. The output shows all active tasks (from both local tracking and synced Jira tickets), who's working on what, current blockers, and sprint progress—all rendered directly in the Claude Code interface.

When Jordan needs to check on a specific developer, they run `/member-progress @sarah` to see Sarah's current tasks, recent commits from GitLab, open merge requests, and completed work for the week. Throughout the day, Jordan uses commands like `/show-blockers` or natural language queries: "who's working on the auth feature?" to get instant answers.

**Sprint Planning:**
At sprint start, Jordan runs `/sprint-create` in Claude Code, then assigns tasks using conversational commands: "assign authentication refactor to @sarah", "import Jira tickets from sprint 15". The system pulls relevant Jira issues and displays them for quick assignment. Jordan can run `/sprint-progress` anytime to see velocity metrics and burndown. When developers update Jira tickets, those changes sync back to the local system automatically.

**Documentation Access:**
During planning or retros, Jordan runs `/confluence-search sprint 14 retrospective` to pull up relevant documentation without leaving Claude Code. The system displays a summary and provides commands to open specific pages or create new documentation.

**Team Collaboration:**
When developers need to update their status, they use Claude Code commands like `/task-blocked` or conversational updates: "mark my current task as blocked by database migration". Changes sync to Jira automatically. When developers create GitLab merge requests, the system detects them and updates task status accordingly. Since all data lives in the shared git repository with external tool integrations, changes propagate seamlessly across the team.

---

## 3. Project Boundaries

### 3.1. What's In-Scope for this Version

- **Claude Code CLI commands** for all team management operations (dedicated commands like `/team-status`, `/create-task`, `/member-progress`, etc.)
- **Individual member progress tracking** with detailed view of current work and recent activity
- **GitLab integration** for syncing issues, MRs, commits, and pipeline status
- **Jira integration** for bi-directional ticket sync and sprint planning
- **Confluence integration** for documentation access and linking
- **MCP agent integration** to process natural language commands and automate tracking
- **Repository-based data storage** using JSON/markdown files in `.team/` or similar directory
- **Git-based synchronization** of team data across the team
- **Real-time status visualization** rendered directly in Claude Code CLI output
- **Natural language task management** (create, assign, update, complete tasks via conversation)
- **Blocker and dependency tracking** through dedicated commands and data structures
- **Basic sprint/milestone planning** with velocity tracking via dedicated commands
- **Automated team member discovery** from git commit history
- **Command-line dashboard rendering** (ASCII/formatted text output in terminal)
- **External tool authentication** for connecting GitLab, Jira, and Confluence accounts

### 3.2. What's Out-of-Scope (Non-Goals)

- **Web interface or web portal** - Everything happens in Claude Code CLI, no browser-based UI
- **External databases or cloud services** - All data stored locally in repository files (external tool data is synced/cached locally)
- **Standalone applications** - Not a separate app; only works within Claude Code environment
- **Time tracking and timesheets** - No hour logging or detailed timesheet functionality
- **Mobile application** - CLI only, no mobile interface
- **Advanced reporting and analytics** - No custom report builders or BI features beyond basic velocity metrics
- **Real-time websocket/push notifications** - Status updates via CLI commands and git pulls only
- **Authentication/user management systems** - Relies on git identity and external tool authentication
- **GUI or graphical interfaces** - Terminal/CLI only, text-based output
- **Integrations with other PM tools** - Only GitLab, Jira, and Confluence for v1.0; no Linear, Asana, Trello, etc.
