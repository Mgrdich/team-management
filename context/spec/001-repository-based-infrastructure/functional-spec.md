# Functional Specification: Repository-Based Infrastructure

- **Roadmap Item:** Repository-Based Infrastructure (Local Data Storage, Multi-Team Support, Team Discovery)
- **Status:** Draft
- **Author:** Claude
- **Date:** 2026-02-27

---

## 1. Overview and Rationale (The "Why")

### Problem Statement
Engineering managers using Claude Code need a team management system that works seamlessly within their CLI environment without requiring complex setup of external databases, cloud services, or additional infrastructure. The current landscape requires managers to configure multiple external services before they can start tracking their teams.

### Solution
This feature provides a repository-based storage foundation where all team configuration data (members, projects, Slack channels) is stored locally in JSON files within a `.team/` directory. This approach eliminates setup complexity—users can initialize team management with a single command and start immediately. All data is version-controlled through git, enabling standard git workflows for synchronization across the team.

### Success Metrics
- Managers can initialize team management in under 30 seconds with zero external dependencies
- Team configuration data syncs reliably using standard git operations
- Multiple teams can coexist in the same repository without conflicts
- Managers can import team members from Slack channels in one command

---

## 2. Functional Requirements (The "What")

### 2.1 Team Initialization

**As a** manager, **I want to** initialize team management with a specific team name, **so that** I can create identifiable team structures in my repository.

**Acceptance Criteria:**
- [ ] When I run `/team-init --name="Team Alpha"`, the system creates a `.team/team-alpha/` directory structure (kebab-case derived from name)
- [ ] The initialization creates three JSON files in the team directory: `team-config.json`, `members.json`, and `projects.json`
- [ ] The `team-config.json` file contains both the provided team name and the generated team ID:
  ```json
  {
    "team_id": "team-alpha",
    "team_name": "Team Alpha",
    "created_at": "2026-02-27T10:00:00Z",
    "current_projects": []
  }
  ```
- [ ] If I run `/team-init` without providing a `--name` parameter, the system prompts me: "What would you like to name this team?"
- [ ] If I run `/team-init --name="Team Alpha"` when `.team/team-alpha/` already exists, the system updates the existing configuration without data loss
- [ ] After successful initialization, I see a detailed summary showing:
  - Team name and team ID
  - Created directory structure and file paths (e.g., `.team/team-alpha/`)
  - Next steps (e.g., "Add team members with `/add-member --team=team-alpha` or import from Slack with `/import-slack-channel --team=team-alpha`")
  - Instructions for connecting external tools (Jira, GitLab, Slack)

### 2.2 Multi-Team Support

**As a** manager overseeing multiple teams, **I want to** manage multiple teams in the same repository, **so that** I can track all teams from one location.

**Acceptance Criteria:**
- [ ] Each team has its own subdirectory based on its name: `.team/team-alpha/`, `.team/team-beta/`, `.team/backend-team/`, etc.
- [ ] When I run `/team-init --name="Team Beta"`, the system creates a new team instance in `.team/team-beta/`
- [ ] All team management commands accept a `--team` parameter using the team ID (e.g., `/team-status --team=team-alpha`)
- [ ] Each team maintains isolated configuration files (separate members.json, projects.json, team-config.json)
- [ ] Teams can have different members, projects, and Slack channels without interference
- [ ] I can list all initialized teams by viewing the `.team/` directory structure or running a command like `/list-teams`

### 2.3 Team Member Management

**As a** manager, **I want to** add team members manually or import them from Slack, **so that** I can quickly build my team roster.

**Manual Addition:**
- [ ] When I run a command to add a member manually, the system prompts me for: name, email, role/title
- [ ] The member is added to `members.json` with a unique member ID
- [ ] I can optionally provide git username/email for linking commits later

**Slack Channel Import:**
- [ ] When I run a command to import from Slack channel (e.g., `/import-slack-channel --team=team-alpha`), the system:
  - Authenticates with Slack using credentials from environment variables (`SLACK_TOKEN`)
  - Prompts me to search for a Slack channel by keyword
  - Queries Slack API and presents matching channels as options using AskUserQuestion
  - After I select a channel, retrieves all members from that channel
  - For each Slack member, automatically retrieves: name, email address, role/title
  - Adds all discovered members to `members.json`
- [ ] After import completes, I see a summary: "Imported 12 members from #team-alpha-channel"

**Member Removal:**
- [ ] I can remove members from the team roster at any time
- [ ] Removed members are deleted from `members.json`

### 2.4 Project Management

**As a** manager, **I want to** link projects to my team with connections to external tools, **so that** I can track which projects my team works on.

**Acceptance Criteria:**
- [ ] I can add a project to the team configuration
- [ ] For each project, the system stores:
  - Project name/ID (unique identifier)
  - Repository URL or path
  - External tool links (Jira board, GitLab project, Confluence space)
  - Project status (e.g., active, archived, planned)
  - Project description
  - Team assignment
- [ ] When adding external tool links (e.g., Jira board), the system:
  - Authenticates with the external tool using environment variables (`JIRA_TOKEN`, `GITLAB_TOKEN`, `CONFLUENCE_TOKEN`)
  - Prompts me to search by keyword
  - Queries the external tool API and presents matching resources as options using AskUserQuestion
  - Saves the selected resource ID/URL to the project configuration
- [ ] The team can have multiple current/active projects stored as an array in `team-config.json`
- [ ] Projects are stored in `projects.json` as an array of project objects

### 2.5 Data Synchronization

**As a** team member, **I want** team configuration changes to sync via standard git workflows, **so that** I can use familiar git operations.

**Acceptance Criteria:**
- [ ] When I modify team configuration (add member, update project), changes are made to local JSON files only
- [ ] I must manually commit changes using `git add .team/` and `git commit`
- [ ] I sync changes with the team by running `git push` and `git pull`
- [ ] If two team members modify the same configuration simultaneously, standard git merge conflicts occur
- [ ] Git merge conflicts in JSON files are resolved manually in the text editor
- [ ] The file structure (one file per configuration type) minimizes conflict likelihood

### 2.6 Configuration File Structure

**As a** developer integrating with this system, **I need** a well-defined JSON schema, **so that** I can programmatically read and write team data.

**team-config.json:**
```json
{
  "team_id": "team-alpha",
  "team_name": "Team Alpha",
  "created_at": "2026-02-27T10:00:00Z",
  "current_projects": ["project-1", "project-2"]
}
```

**members.json:**
```json
[
  {
    "member_id": "mem-001",
    "name": "Sarah Johnson",
    "email": "sarah@example.com",
    "role": "Senior Engineer",
    "git_username": "sarahj",
    "git_email": "sarah@example.com",
    "added_at": "2026-02-27T10:05:00Z"
  }
]
```

**projects.json:**
```json
[
  {
    "project_id": "project-1",
    "name": "Authentication Service",
    "repository_url": "https://gitlab.com/company/auth-service",
    "description": "User authentication and authorization",
    "status": "active",
    "team_id": "team-alpha",
    "jira_board_id": "BOARD-123",
    "gitlab_project_id": "456",
    "confluence_space": "AUTH",
    "created_at": "2026-02-27T10:10:00Z"
  }
]
```

**Acceptance Criteria:**
- [ ] All JSON files follow the schemas defined above
- [ ] Each object has a unique ID field
- [ ] Timestamps are in ISO 8601 format
- [ ] Arrays are used for collections (members, projects, current_projects)

### 2.7 External Tool Authentication

**As a** manager, **I want** to authenticate with external tools using environment variables, **so that** credentials are not stored in the repository.

**Acceptance Criteria:**
- [ ] The system reads credentials from environment variables: `SLACK_TOKEN`, `JIRA_TOKEN`, `GITLAB_TOKEN`, `CONFLUENCE_TOKEN`
- [ ] If a required token is missing when I try to connect a tool, I see a clear error message with instructions: "SLACK_TOKEN environment variable not found. Please set it to your Slack API token."
- [ ] Credentials are never written to any `.team/` JSON files
- [ ] The system validates tokens by making a test API call on connection

---

## 3. Scope and Boundaries

### In-Scope

- **Team Initialization:** `/team-init --name="Team Name"` command creates `.team/[team-id]/` directory with JSON files
- **Team Naming:** Teams must be named during initialization; name is converted to kebab-case for directory/ID
- **Multi-Team Support:** Directory-based team isolation with `--team` parameter
- **Member Management:** Manual addition and Slack channel import of team members
- **Project Management:** Store project metadata with external tool links (Jira, GitLab, Confluence)
- **Keyword Search:** Search external tools by keyword and present options to user via AskUserQuestion
- **Standard Git Sync:** Team configuration syncs using manual git commit/push/pull
- **JSON Storage:** team-config.json, members.json, projects.json files
- **Environment Variable Auth:** External tool credentials stored in env vars
- **Merge/Update on Re-init:** Preserve existing data when running `/team-init` again on existing team

### Out-of-Scope

- **Automatic Git Operations:** No auto-commit, auto-push, or auto-sync features
- **Task/Ticket Storage:** This feature stores team configuration only, not task or ticket data (tasks will be handled by external tools)
- **Real-time Sync:** No websocket or push-based synchronization; git pull required for updates
- **Conflict Resolution UI:** No guided conflict resolution; users resolve git conflicts manually
- **Credential Management UI:** No credential entry prompts; users must set environment variables manually
- **Git-Based Team Discovery:** No automatic discovery from git commit history (replaced by Slack import and manual addition)
- **Database Storage:** No SQL or NoSQL databases; JSON files only
- **Web Interface:** No browser-based configuration UI
- **Slack User ID Storage:** Slack import retrieves name, email, role but not Slack user IDs (handled by future Slack integration features)
- **Default Team Context:** No "current team" context switching; all commands require explicit `--team` parameter
- **Other Roadmap Features:** Sprint planning, task management commands, MCP agents, status dashboards, blocker tracking, individual member progress tracking, dependency management (all covered in separate specifications)

---
