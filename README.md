# Claude Team Manager

A repository-based team management system for Claude Code that tracks team members, projects, and integrates with external tools via MCP.

## Features

### Core Functionality
- ✅ **Multi-Team Support** - Manage multiple teams in one repository
- ✅ **Team Member Management** - Add, remove, and track team members
- ✅ **Project Tracking** - Create and manage projects with status tracking
- ✅ **Git-Based Storage** - All data stored in version-controlled JSON files
- ✅ **Local-First** - No external database required

### External Tool Integration (via MCP)
- 🔗 **GitLab Integration** - Auto-detect git info from GitLab user profiles
- 🔗 **Slack Integration** - Import team members from Slack channels
- 🔗 **Jira Integration** - Link projects to Jira boards
- 🔗 **Confluence Integration** - Link projects to Confluence spaces

## Quick Start

### Prerequisites

- **Claude Code CLI** - Install from [claude.ai/code](https://claude.ai/code)
- **bash** - Shell for running utility scripts
- **jq** - JSON processor (`brew install jq` on macOS)
- **git** - Version control

### Initialize Your First Team

```bash
# 1. Initialize a team
/team-init --name="Engineering Team"

# 2. Add team members
/add-team-members --team=engineering-team

# 3. Add a project
/add-project --team=engineering-team

# 4. View your teams
/list-teams
```

## Available Commands

### Team Management

| Command | Description |
|---------|-------------|
| `/team-init --name="Team Name"` | Initialize a new team |
| `/list-teams` | List all teams with member/project counts |

### Member Management

| Command | Description |
|---------|-------------|
| `/add-team-members --team=<team-id>` | Add members manually (supports GitLab MCP auto-detection) |
| `/remove-team-member --team=<team-id>` | Remove a member from a team |
| `/import-slack-channel --team=<team-id>` | Import members from Slack channel (requires Slack MCP) |

### Project Management

| Command | Description |
|---------|-------------|
| `/add-project --team=<team-id>` | Add a project (supports external tool linking via MCP) |

### Team Status & Reporting

| Command | Description | MCP Requirements |
|---------|-------------|------------------|
| `/team-status [--team=<team-id>] [--member=<name>] ["query"]` | Display real-time team task status from Jira and GitLab | **Requires:** Jira MCP<br>**Optional:** GitLab MCP, Slack MCP |

## Data Structure

All team data is stored in `.team/<team-id>/` directories:

```
.team/
├── team-alpha/
│   ├── team-config.json     # Team metadata and settings
│   ├── members.json          # Team members
│   └── projects.json         # Team projects
└── team-beta/
    ├── team-config.json
    ├── members.json
    └── projects.json
```

### Team Config Schema

```json
{
  "team_id": "team-alpha",
  "team_name": "Team Alpha",
  "created_at": "2026-02-27T17:09:05Z",
  "updated_at": "2026-02-27T17:48:23Z",
  "current_projects": ["proj-1772214332-bmx"]
}
```

### Member Schema

```json
{
  "member_id": "mem-1772212829-rvc",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "Engineer",
  "added_at": "2026-02-27T17:20:56Z",
  "source": "manual",
  "git_username": "jdoe",           // Optional (from GitLab MCP)
  "git_email": "jdoe@github.com",   // Optional (from GitLab MCP)
  "slack_user_id": "U1234567"       // Optional (from Slack import)
}
```

### Project Schema

```json
{
  "project_id": "proj-1772214332-bmx",
  "name": "Authentication Service",
  "status": "active",
  "team_id": "team-alpha",
  "repository_url": "https://github.com/company/auth-service",
  "description": "OAuth2 authentication microservice",
  "created_at": "2026-02-27T17:45:48Z",
  "updated_at": "2026-02-27T17:45:48Z",
  "jira_board_id": "123",               // Optional (via Jira MCP)
  "gitlab_project_id": "456",           // Optional (via GitLab MCP)
  "confluence_space": "ENG"             // Optional (via Confluence MCP)
}
```

## Optional: MCP Integration

MCP (Model Context Protocol) enables integration with external tools. Each integration is optional and independent.

### GitLab CLI Setup

Configure the GitLab CLI (`glab`) for enhanced Git integration:

```bash
# Install glab (if not already installed)
# macOS:
brew install glab

# Follow prompts to authenticate with your GitLab account
glab auth login
```

### Available MCP Integrations

| MCP                | Feature                                                                             | Setup Guide                                                  |
|--------------------|-------------------------------------------------------------------------------------|--------------------------------------------------------------|
| **GitLab MCP**     | Auto-detect git info when adding members<br>Optional enhancement for `/team-status` | [docs/setup-gitlab-mcp.md](docs/setup-gitlab-mcp.md)         |
| **Jira MCP**       | Link projects to Jira boards<br>**Required for `/team-status`**                     | [docs/setup-jira-mcp.md](docs/setup-jira-mcp.md)             |
| **Confluence MCP** | Link projects to Confluence spaces                                                  | [docs/setup-confluence-mcp.md](docs/setup-confluence-mcp.md) |

### Quick MCP Setup (LiveNation)

```bash
# Configure Jira MCP server
claude mcp add \
  --transport http \
  jira \
  --header "Authorization: Token <token>" \
  --scope user \
  https://mcp.jira.domain.com/mcp/

# Configure Confluence MCP server
claude mcp add \
  --transport http \
  confluence \
  --header "Authorization: Token <token>" \
  --scope user \
  https://mcp.confluence.domain.com/mcp/
```

**Note:** Replace `<token>` with your API token. See setup guides for detailed instructions.

**MCP Requirements:**
- **Core team management** (team-init, add-team-members, add-project, list-teams, remove-team-member) works without any MCP
- **`/team-status`** requires Jira MCP; GitLab and Slack MCPs are optional enhancements
- **`/import-slack-channel`** requires Slack MCP
- **GitLab MCP** enhances `/add-team-members` with auto-detection but is not required

## Architecture

### Bash Utilities

Core functionality is implemented as dependency-free bash scripts:

- `scripts/utils/id-generator.sh` - Generate unique IDs for teams, members, projects
- `scripts/utils/file-ops.sh` - File system operations and team management
- `scripts/utils/json-utils.sh` - JSON manipulation using jq

### Claude Code Skills

User-facing commands implemented as Claude Code skills in `.claude/skills/`:

- `team-init/` - Initialize teams
- `list-teams/` - List all teams
- `add-team-members/` - Add members with optional MCP integration
- `remove-team-member/` - Remove members
- `import-slack-channel/` - Import from Slack (requires Slack MCP)
- `add-project/` - Add projects with optional external tool linking
- `team-status/` - Real-time team status dashboard (requires Jira MCP)

### Design Principles

1. **Local-First** - All data stored locally in git repository
2. **Dependency-Free** - Core functionality requires only bash, jq, git
3. **MCP-Enhanced** - Optional MCP integrations for external tools
4. **Multi-Team** - Support multiple independent teams per repository
5. **Version-Controlled** - All team data tracked in git

## Development

### Running Tests

```bash
# Run bash utility tests (requires bats)
bats tests/utils/test-id-generator.bats
bats tests/utils/test-file-ops.bats
bats tests/utils/test-json-utils.bats
```

### Project Structure

```
team-management/
├── .claude/
│   └── skills/              # Claude Code skills
│       ├── team-init/
│       ├── list-teams/
│       ├── add-team-members/
│       ├── remove-team-member/
│       ├── import-slack-channel/
│       ├── add-project/
│       └── team-status/
├── .team/                   # Team data (git-tracked)
│   ├── team-alpha/
│   └── team-beta/
├── scripts/
│   └── utils/               # Bash utility scripts
│       ├── id-generator.sh
│       ├── file-ops.sh
│       └── json-utils.sh
├── tests/                   # Unit tests
├── docs/                    # MCP setup guides
└── context/                 # Product and technical specs
```

## Roadmap

### Phase 1: Foundation ✅ (Complete)
- ✅ Repository-based infrastructure
- ✅ Team initialization and listing
- ✅ Member management (add, remove)
- ✅ Project management (basic)
- ✅ Multi-team support

### Phase 2: Status & Reporting ✅ (Complete)
- ✅ Real-time team status dashboard (`/team-status`)
- ✅ Jira task integration
- ✅ GitLab issues and MR tracking
- ✅ Member filtering and natural language queries
- ✅ Slack name enrichment

### Phase 3: MCP Configuration ✅ (Complete)
- ✅ GitLab MCP setup and documentation
- ✅ Slack MCP setup and documentation
- ✅ Jira MCP setup and documentation
- ✅ Confluence MCP setup and documentation
- ✅ Environment-based credential management

### Phase 4: Advanced Features (Planned)
- 🔲 Individual progress tracking
- 🔲 Dependency and blocker management
- 🔲 Task assignment and updates
- 🔲 Bi-directional sync with external tools
- 🔲 Automated status detection
- 🔲 Webhook support

## Contributing

This project follows an incremental development approach:
1. Each feature is implemented as a complete, testable slice
2. Features work standalone without external dependencies
3. MCP integrations enhance but don't block core functionality

## License

[Add your license here]

## Support

- **Documentation**: See `docs/` directory for MCP setup guides
- **Issues**: [Add issue tracker link]
- **Discussions**: [Add discussions link]

## Acknowledgments

Built with [Claude Code](https://claude.ai/code) using:
- Bash utilities for core functionality
- jq for JSON processing
- MCP for external tool integration
