# System Architecture Overview: Claude Team Manager

---

## 1. CLI Application & Technology Stack

- **Primary CLI Framework:** Bash shell scripts for core command logic and file operations
- **Claude Code Integration:** Claude Code Skills (`.claude/commands/`) as entry points that invoke underlying bash scripts
- **Natural Language Processing:** Claude's MCP agents handle complex NL understanding and command routing
- **MCP Server Development (Future):** TypeScript/Node.js for custom MCP servers if needed beyond existing integrations
- **JSON Processing:** `jq` command-line tool for parsing and manipulating JSON data
- **CLI Output Formatting:** Rich CLI formatting with colors and tables for enhanced user experience
  - Consider tools like: `column`, ANSI color codes, or lightweight CLI formatting libraries

---

## 2. Data & Persistence

- **Primary Storage Format:** JSON files for all structured data (tasks, team members, sprints, dependencies)
- **Data Directory Structure:**
  - `.team/` - Root directory for all team management data
  - `.team/teams/` - Multi-team support with separate subdirectories per team
  - `.team/tasks/` - Task definitions and status
  - `.team/sprints/` - Sprint/milestone data
  - `.team/members/` - Team member information
  - `.team/cache/` - Cached data from external integrations (GitLab, Jira, Confluence, Slack)
  - `.team/logs/` - Application logs (git-ignored)
- **Version Control:** All data files are git-tracked (except logs and sensitive cache), enabling team synchronization via git pull/push
- **Git Integration:** Native git commands for team member discovery and activity tracking
- **Data Validation:** Bash scripts validate JSON schema before write operations

---

## 3. External Integrations & MCP Auto-Discovery

- **MCP Configuration:** MCP servers are pre-configured in project's `.claude/mcp.json`
  - Users configure MCP servers once in their Claude Code environment
  - System automatically detects and uses available MCP servers at runtime
  - No separate connection commands or configuration files needed

- **Integration Discovery Pattern:**
  - Commands check for MCP availability when needed (lazy evaluation)
  - If MCP is available, use it; if not, fall back gracefully
  - No upfront validation or state storage required

- **GitLab Integration (if GitLab MCP available):**
  - Issue synchronization
  - Merge request tracking
  - Commit activity monitoring
  - Pipeline status

- **Jira Integration (if Atlassian MCP available):**
  - Bi-directional ticket synchronization
  - Sprint import and management
  - Status updates

- **Confluence Integration (if Atlassian MCP available):**
  - Documentation search and access
  - Page linking to tasks/sprints

- **Slack Integration (if Slack MCP available):**
  - Blocker detection from channel conversations
  - Status update notifications
  - Conversational queries

- **Progress Tracking Strategy:**
  - **If GitLab MCP available:** Primary progress tracking from GitLab commits, MRs, and issues
  - **If Jira MCP available:** Primary progress tracking from Jira ticket status updates
  - **If both available:** Sync progress between both systems
  - **If neither available:** Local-only progress tracking from git commits and manual status updates

- **Graceful Degradation:** System works fully offline with just local data; external integrations enhance but don't block functionality

---

## 4. Command Processing & Execution Flow

- **Command Entry Points:** Claude Code Skills (`.claude/commands/`) define available commands
- **Skill-to-Script Mapping:** Each skill invokes corresponding bash script in `scripts/` directory
- **Natural Language Processing Flow:**
  1. User inputs natural language command in Claude Code
  2. Claude Code skill provides command structure and context
  3. Claude's MCP agents interpret complex NL and extract parameters
  4. Bash script receives structured parameters and executes logic
  5. Script attempts to use configured MCP servers, falls back if unavailable

- **Command Execution Pattern:**
  ```
  User NL Input → Claude Skill → Claude MCP Intelligence → Bash Script → JSON Data Operations → MCP Integration (if available) → Formatted Output
  ```

- **Output Rendering:**
  - Commands return data to Claude for final formatting
  - Rich CLI output with colors, tables, and visual separators
  - ASCII-based charts for velocity and burndown visualization

- **Core Command Categories:**
  - **Initialization:** `/team-init` - Sets up team structure, discovers git team members
  - **Status & Queries:** `/team-status`, `/member-progress`, `/show-blockers`
  - **Task Management:** `/create-task`, `/assign-task`, `/task-blocked`
  - **Sprint Management:** `/sprint-create`, `/sprint-progress`
  - **Natural Language:** Conversational commands like "who's working on auth?" or "mark task blocked"

---

## 5. Observability & Error Handling

- **Logging Strategy:**
  - Log files stored in `.team/logs/` (git-ignored for privacy)
  - Log rotation: Keep last 7 days of logs
  - Log levels: ERROR, WARN, INFO, DEBUG (controlled via environment variable)

- **Error Handling Philosophy:** Fail fast with clear, actionable error messages
  - No silent failures
  - Detailed error context (command, file, line number)
  - User-friendly error messages with suggested fixes
  - MCP errors provide helpful guidance (e.g., "GitLab MCP not configured - see docs/setup-gitlab.md")

- **Error Categories:**
  - **Local Errors:** Immediate failure (file not found, invalid JSON, git errors)
  - **MCP Unavailable:** Warn user and continue with local-only functionality
  - **External API Errors:** Display clear error with status code and API message
  - **MCP Communication Errors:** Show connection status and suggest checking `.claude/mcp.json` configuration

- **Debugging Support:**
  - `DEBUG=1` environment variable enables verbose output
  - Dry-run mode for testing commands without persisting changes
  - JSON schema validation errors show exact field and expected format

- **Health Checks:**
  - Pre-command validation of `.team/` directory structure
  - On-demand MCP availability checks (non-blocking - warn if unavailable but continue)
  - Git repository status verification

---

## 6. Development & Distribution

- **Development Environment:**
  - Bash 4.0+ required
  - Dependencies: `jq`, `git`, `curl` (standard on most systems)
  - Claude Code with MCP support

- **Testing Strategy:**
  - Bash unit tests using `bats` (Bash Automated Testing System)
  - Integration tests with mock MCP responses
  - Manual E2E testing in real Claude Code environment

- **Distribution:**
  - Git repository clone (users clone and use directly)
  - No compilation or build step required
  - Setup script initializes required directories and validates dependencies
  - Example `.claude/mcp.json` template provided in `docs/` for reference

- **Documentation:**
  - Command reference in `.claude/commands/` (visible in Claude Code)
  - Developer documentation in `docs/` directory
  - Architecture decision records (ADRs) for significant technical decisions
  - **Integration Setup Guides (in `docs/`):**
    - GitLab MCP setup guide
    - Jira/Confluence MCP setup guide
    - Slack MCP setup guide
    - Common troubleshooting tips

---
