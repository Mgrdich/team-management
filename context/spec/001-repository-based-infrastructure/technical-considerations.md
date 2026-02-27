# Technical Specification: Repository-Based Infrastructure

- **Functional Specification:** `functional-spec.md`
- **Status:** Draft
- **Author:** Claude
- **Date:** 2026-02-27

---

## 1. High-Level Technical Approach

This feature implements repository-based storage for team configuration data using a simple, maintainable architecture:

**Core Components:**
- **Claude Code Skills** (`.claude/commands/`) - Handle all natural language understanding, MCP interactions, user prompts, business logic, and output formatting
- **Bash Utility Scripts** (`scripts/utils/`) - Perform repetitive file operations (create directories, read/write JSON, generate IDs)
- **JSON Storage** (`.team/[team-id]/`) - Store team configuration as JSON files, version-controlled via git
- **MCP Integration** - Skills orchestrate external tool calls (Slack, Jira, GitLab, Confluence) via their respective MCP servers

**Key Architectural Decisions:**
- Skills contain ALL logic; bash scripts are minimal utilities for file operations only
- No direct API calls from bash scripts - all external integrations via MCP servers
- MCP-only approach: if MCP not available, show clear error with setup instructions
- Each team isolated in separate directory for multi-team support
- Standard git workflow for synchronization (no auto-commit/push)

---

## 2. Proposed Solution & Implementation Plan

### 2.1 Directory Structure & File Organization

**Project Structure:**
```
.team/
  config.json                    # Global system configuration
  team-alpha/
    team-config.json             # Team metadata
    members.json                 # Team member roster
    projects.json                # Team projects with external links
  team-beta/
    team-config.json
    members.json
    projects.json

scripts/
  utils/
    file-ops.sh                  # Directory and file operations
    json-utils.sh                # JSON read/write/append operations
    id-generator.sh              # ID generation utilities

.claude/
  commands/
    team-init.md                 # Initialize team
    list-teams.md                # List all teams
    add-member.md                # Add member manually
    remove-member.md             # Remove member
    import-slack-channel.md      # Import members from Slack
    add-project.md               # Add project with external links
```

**Configuration Files:**

`.team/config.json` (global system settings):
```json
{
  "version": "1.0.0",
  "log_level": "INFO",
  "default_team": null,
  "output_format": "rich"
}
```

### 2.2 Skill and Script Responsibilities

**Architecture Principle:** Skills handle ALL logic and orchestration. Bash scripts only perform repetitive file operations.

#### Skill: `/team-init` (`.claude/commands/team-init.md`)

**Responsibilities:**
- Prompt user for team name if `--name` not provided (using AskUserQuestion)
- Validate team name is not empty
- Call `scripts/utils/id-generator.sh team_name_to_id` to convert name to kebab-case ID
- Check if team exists using `scripts/utils/file-ops.sh validate_team_exists`
- If exists: inform user about merge/update behavior (data will be preserved)
- Create team structure: `scripts/utils/file-ops.sh create_team_structure [team-id]`
- Write initial JSON files: `scripts/utils/json-utils.sh write_initial_files [team-id] [team-name]`
- Display detailed summary with:
  - Team name and team ID
  - Created directory paths
  - Next steps (add members, import from Slack, add projects)
  - Instructions for connecting external tools

#### Skill: `/list-teams` (`.claude/commands/list-teams.md`)

**Responsibilities:**
- Call `scripts/utils/file-ops.sh list_teams` to get all team IDs
- For each team, read team-config.json to get team name
- Display formatted list showing ID, name, member count, project count
- If no teams exist, show message: "No teams initialized. Run /team-init to create one."

#### Skill: `/add-member` (`.claude/commands/add-member.md`)

**Responsibilities:**
- Validate `--team` parameter provided
- Check team exists using bash script
- Use AskUserQuestion to collect: name, email, role/title
- Optionally ask for git username/email for future commit linking
- Generate member ID: `scripts/utils/id-generator.sh generate_member_id`
- Build member JSON object with current timestamp
- Append to members.json: `scripts/utils/json-utils.sh append_member [team-id] [member-json]`
- Display confirmation: "Added [name] to [team-name]"

#### Skill: `/remove-member` (`.claude/commands/remove-member.md`)

**Responsibilities:**
- Validate `--team` parameter
- Read current members: `scripts/utils/json-utils.sh read_members [team-id]`
- Use AskUserQuestion to present list of members for selection
- Confirm removal with user
- Remove from members.json: `scripts/utils/json-utils.sh remove_member [team-id] [member-email]`
- Display confirmation

#### Skill: `/import-slack-channel` (`.claude/commands/import-slack-channel.md`)

**Responsibilities:**
- Validate `--team` parameter provided
- Check team exists using bash script
- Verify Slack MCP is available; if not, show error with setup instructions
- Use AskUserQuestion to get channel search keyword from user
- Call Slack MCP to search channels: `conversations.list` with search filter
- Present channel options using AskUserQuestion (show channel name, member count, description)
- After selection, call Slack MCP to get channel members: `conversations.members`
- For each member ID, call Slack MCP: `users.info` to get profile data:
  - Name (display name or real name)
  - Email (from profile)
  - Role/title (from profile title field)
- Generate member ID for each: `scripts/utils/id-generator.sh generate_member_id`
- Build member JSON objects with all fields and current timestamp
- Check for duplicates by email before appending
- Append all new members: `scripts/utils/json-utils.sh append_members [team-id] [json-array]`
- Display summary: "Imported X members from #channel-name (Y duplicates skipped)"
- Handle MCP errors: show clear error if Slack MCP not configured with link to setup docs

#### Skill: `/add-project` (`.claude/commands/add-project.md`)

**Responsibilities:**
- Validate `--team` parameter
- Use AskUserQuestion to collect:
  - Project name (required)
  - Repository URL (optional)
  - Description (optional)
  - Status (dropdown: active, archived, planned, on-hold)
- Ask user which external tools to link (Jira, GitLab, Confluence) using AskUserQuestion
- For each selected tool:
  - Verify respective MCP is available
  - Use AskUserQuestion to get search keyword
  - Call MCP to search resources:
    - Jira MCP: search boards/projects
    - GitLab MCP: search repositories/projects
    - Confluence MCP: search spaces
  - Present search results using AskUserQuestion
  - Store selected resource IDs/URLs
- Generate project ID: `scripts/utils/id-generator.sh generate_project_id`
- Build project JSON object with all collected data and timestamps
- Append to projects.json: `scripts/utils/json-utils.sh append_project [team-id] [project-json]`
- Update current_projects array: `scripts/utils/json-utils.sh update_current_projects [team-id] [project-id]`
- Display confirmation with project details and linked tools

### 2.3 Bash Script Functions

All bash scripts in `scripts/utils/` are simple, reusable utilities for file operations.

#### `scripts/utils/file-ops.sh`

```bash
create_team_structure <team-id>
  # Creates .team/[team-id]/ directory
  # Returns: 0 on success, 1 on error

validate_team_exists <team-id>
  # Checks if .team/[team-id]/ exists
  # Returns: 0 if exists, 1 if not

list_teams
  # Outputs list of team IDs (one per line)
  # Scans .team/ for subdirectories with valid structure
```

#### `scripts/utils/json-utils.sh`

```bash
write_initial_files <team-id> <team-name>
  # Creates team-config.json, members.json (empty array), projects.json (empty array)
  # Uses current ISO 8601 timestamp for created_at fields

append_member <team-id> <member-json>
  # Appends single member object to members.json
  # Checks for duplicate by email, returns 1 if duplicate exists

append_members <team-id> <json-array>
  # Appends array of member objects to members.json
  # Filters out duplicates by email

append_project <team-id> <project-json>
  # Appends project object to projects.json

update_current_projects <team-id> <project-id>
  # Adds project-id to current_projects array in team-config.json
  # Creates array if doesn't exist

remove_member <team-id> <member-email>
  # Removes member from members.json by email match
  # Returns: 0 if removed, 1 if not found

read_team_config <team-id>
  # Outputs team-config.json content to stdout

read_members <team-id>
  # Outputs members.json content to stdout

read_projects <team-id>
  # Outputs projects.json content to stdout

read_project <team-id> <project-id>
  # Outputs single project object matching project-id
```

**Implementation Notes:**
- All JSON operations use `jq` for parsing and manipulation
- Validate JSON schema before every write operation
- Use atomic writes: write to temp file, validate, then move to final location
- Set proper error handling: `set -euo pipefail` in all scripts

#### `scripts/utils/id-generator.sh`

```bash
team_name_to_id <name>
  # Converts "Team Alpha" to "team-alpha"
  # Logic: lowercase, replace spaces with hyphens, strip special chars
  # Max length: 63 characters (filesystem safe)
  # Outputs: kebab-case ID

generate_member_id
  # Outputs: mem-[unix-timestamp]-[3-random-chars]
  # Example: mem-1709123456-abc

generate_project_id
  # Outputs: proj-[unix-timestamp]-[3-random-chars]
  # Example: proj-1709123456-xyz
```

### 2.4 Data Model & JSON Schemas

#### `.team/[team-id]/team-config.json`
```json
{
  "team_id": "team-alpha",
  "team_name": "Team Alpha",
  "created_at": "2026-02-27T10:00:00Z",
  "updated_at": "2026-02-27T10:00:00Z",
  "current_projects": ["proj-1709123456-xyz", "proj-1709123457-abc"]
}
```

**Fields:**
- `team_id` (string, required): Kebab-case identifier
- `team_name` (string, required): Human-readable display name
- `created_at` (ISO 8601 string, required): Team creation timestamp
- `updated_at` (ISO 8601 string, required): Last modification timestamp
- `current_projects` (array of strings, required): Project IDs marked as current/active

#### `.team/[team-id]/members.json`
```json
[
  {
    "member_id": "mem-1709123456-abc",
    "name": "Sarah Johnson",
    "email": "sarah@example.com",
    "role": "Senior Engineer",
    "git_username": "sarahj",
    "git_email": "sarah@example.com",
    "added_at": "2026-02-27T10:05:00Z",
    "source": "slack_import"
  }
]
```

**Fields:**
- `member_id` (string, required): Unique identifier
- `name` (string, required): Full name
- `email` (string, required): Email address (unique constraint)
- `role` (string, optional): Job title or role
- `git_username` (string, optional): Git username for commit tracking
- `git_email` (string, optional): Git email for commit tracking
- `added_at` (ISO 8601 string, required): When member was added
- `source` (string, required): "manual" or "slack_import"

#### `.team/[team-id]/projects.json`
```json
[
  {
    "project_id": "proj-1709123456-xyz",
    "name": "Authentication Service",
    "repository_url": "https://gitlab.com/company/auth-service",
    "description": "User authentication and authorization",
    "status": "active",
    "team_id": "team-alpha",
    "jira_board_id": "BOARD-123",
    "gitlab_project_id": "456",
    "confluence_space": "AUTH",
    "created_at": "2026-02-27T10:10:00Z",
    "updated_at": "2026-02-27T10:10:00Z"
  }
]
```

**Fields:**
- `project_id` (string, required): Unique identifier
- `name` (string, required): Project display name
- `repository_url` (string, optional): Git repository URL
- `description` (string, optional): Project description
- `status` (enum string, required): "active", "archived", "planned", "on-hold"
- `team_id` (string, required): Parent team identifier
- `jira_board_id` (string, optional): Linked Jira board ID
- `gitlab_project_id` (string, optional): Linked GitLab project ID
- `confluence_space` (string, optional): Linked Confluence space key
- `created_at` (ISO 8601 string, required): Project creation timestamp
- `updated_at` (ISO 8601 string, required): Last modification timestamp

### 2.5 MCP Integration (Skills Only)

**Architecture:** All MCP interactions happen in Claude Code skills. Bash scripts never call external APIs.

**Referenced MCP Servers (configured in user's `.claude/mcp.json`):**

#### Slack MCP
- **Used by:** `/import-slack-channel`
- **Tools:**
  - `conversations.list` - Search and list channels
  - `conversations.members` - Get member IDs in channel
  - `users.info` - Get user profile data (name, email, title)
- **Purpose:** Import team members from Slack channels
- **Error Handling:** If not available, show: "Slack MCP not configured. See docs/setup-slack.md"

#### Jira MCP (Atlassian MCP)
- **Used by:** `/add-project`
- **Tools:**
  - Board search - Find Jira boards by keyword
  - Project listing - List available Jira projects
- **Purpose:** Link Jira boards to projects during initial setup
- **Note:** Future phases will add project sync and status updates
- **Error Handling:** If not available when linking requested, show setup instructions

#### GitLab MCP
- **Used by:** `/add-project`
- **Tools:**
  - Project search - Find GitLab projects by keyword
  - Repository listing - List accessible repositories
- **Purpose:** Link GitLab projects to team projects during setup
- **Note:** Future phases will add MR tracking and issue synchronization
- **Error Handling:** If not available when linking requested, show setup instructions

#### Confluence MCP (Atlassian MCP)
- **Used by:** `/add-project`
- **Tools:**
  - Space search - Find Confluence spaces by keyword
  - Space listing - List available spaces
- **Purpose:** Link Confluence spaces to projects during setup
- **Error Handling:** If not available when linking requested, show setup instructions

**MCP Availability Pattern:**
- Skills check for MCP availability before attempting calls
- If MCP not available when needed, display clear error with:
  - What MCP is missing
  - What functionality is unavailable
  - Link to setup documentation
  - Suggestion to continue without external integration if applicable

### 2.6 Claude Code Skills Structure

Each skill follows this markdown format in `.claude/commands/`:

**Example: `team-init.md`**
```markdown
---
description: Initialize team management with a specific team name
---

# /team-init

Initialize team management structure in the repository.

## Usage
/team-init --name="Team Name"

## Parameters
- `--name`: Team name (required if not provided via prompt)
  - Will be converted to kebab-case for team ID
  - Maximum 63 characters
  - Can contain letters, numbers, spaces, hyphens

## Behavior
1. Prompts for team name if --name not provided
2. Validates team name is not empty
3. Converts name to kebab-case ID (e.g., "Team Alpha" → "team-alpha")
4. Creates .team/[team-id]/ directory structure
5. Initializes team-config.json, members.json, projects.json
6. If team exists, updates configuration without data loss

## Output
Displays detailed summary:
- Team name and team ID
- Created directory paths
- Next steps for adding members and projects
- Instructions for connecting external tools

## Examples
/team-init --name="Engineering Team"
/team-init --name="Platform Services"

## Implementation
Calls scripts/utils/id-generator.sh and scripts/utils/file-ops.sh
```

**Skill Documentation Sections:**
- **description** (frontmatter): Brief description for command listing
- **Usage**: Command syntax
- **Parameters**: All parameters with validation rules
- **Behavior**: Step-by-step what the command does
- **Output**: What user sees after execution
- **Examples**: Real usage examples
- **Implementation**: Which bash scripts are called

---

## 3. Impact and Risk Analysis

### 3.1 System Dependencies

**Required Dependencies:**
- Bash 4.0+ (for associative arrays and modern bash features)
- `jq` 1.5+ (for JSON parsing and manipulation)
- `git` (already required by project nature)
- Claude Code environment with MCP support

**Optional Dependencies (External Integrations):**
- Slack MCP (only required for `/import-slack-channel`)
- Jira MCP / Atlassian MCP (only required if linking Jira boards)
- GitLab MCP (only required if linking GitLab projects)
- Confluence MCP / Atlassian MCP (only required if linking Confluence spaces)

**Affected Systems:**
- None - this is foundational infrastructure with no existing system dependencies
- All operations are local file operations until external integrations are explicitly invoked

### 3.2 Potential Risks & Mitigations

#### Risk 1: JSON File Corruption
**Impact:** Team data could become unreadable, losing team configuration

**Mitigation:**
- Validate JSON schema before every write using `jq` validation
- Use atomic writes: write to `.temp` file, validate, then move to final location
- Consider creating `.backup` subdirectory with timestamped backups on modifications
- Provide recovery command if corruption detected

#### Risk 2: Concurrent Modifications via Git
**Impact:** Merge conflicts when multiple managers update same team simultaneously

**Mitigation:**
- Document git workflow clearly in setup guide
- Keep files granular (separate members.json, projects.json) to minimize conflicts
- Members and projects are arrays, easier to merge than nested objects
- Provide documentation on resolving JSON merge conflicts
- Recommend: coordinate updates through Slack before git push

#### Risk 3: Invalid Team Names
**Impact:** Directory creation failures, invalid file paths, or conflicts

**Mitigation:**
- Validate team name in skill before calling scripts:
  - Not empty
  - Maximum 63 characters (filesystem limit consideration)
  - Only alphanumeric, spaces, hyphens allowed
- Sanitize in `team_name_to_id` function:
  - Strip special characters
  - Collapse multiple spaces/hyphens
- Test edge cases: emoji, unicode, very long names

#### Risk 4: MCP Server Not Configured
**Impact:** Commands fail when trying to use external integrations

**Mitigation:**
- Skills check for MCP availability before attempting calls
- Show clear error messages with:
  - Which MCP is missing
  - What functionality is unavailable
  - Direct link to setup documentation (docs/setup-[service].md)
- Provide graceful degradation where possible:
  - `/add-project` can add project without external links
  - User can add links later when MCP configured

#### Risk 5: Duplicate Members/Projects
**Impact:** Data inconsistency, confusion about which record is correct

**Mitigation:**
- Unique constraint on member email in append operations
- Check for duplicates in `append_member` function before writing
- Display warning if duplicate found during import: "X members skipped (already exist)"
- For projects, check by name and warn user if similar name exists
- Use AskUserQuestion to confirm adding potential duplicate

#### Risk 6: Large Slack Channel Imports
**Impact:** Slack channel with 500+ members could overwhelm system or cause timeout

**Mitigation:**
- Process members in batches (100 at a time)
- Show progress indicator during import
- Consider adding `--limit` parameter to cap import size
- Add timeout handling for Slack MCP calls
- Allow user to cancel long-running imports

#### Risk 7: ID Collisions
**Impact:** Two members/projects could theoretically get same ID if generated at same millisecond

**Mitigation:**
- Include random component in ID generation (3 random characters)
- Collision probability very low (timestamp + 17,576 possible combinations)
- If paranoid: add collision detection and regenerate if detected
- Use cryptographically secure random if available

#### Risk 8: Git Repository Not Initialized
**Impact:** Users run commands in non-git directory, data not version controlled

**Mitigation:**
- Check for `.git` directory before allowing team initialization
- Show error: "This directory is not a git repository. Initialize git first."
- Provide guidance on initializing git repo
- Consider auto-initializing `.gitignore` for `.team/.backup/` and `.team/logs/`

---

## 4. Testing Strategy

### 4.1 Unit Testing (Bash Scripts)

**Framework:** `bats` (Bash Automated Testing System)

**Test Files:**
- `tests/utils/test-id-generator.bats`
- `tests/utils/test-file-ops.bats`
- `tests/utils/test-json-utils.bats`

**Coverage for `utils/id-generator.sh`:**
- ✓ `team_name_to_id` with various inputs:
  - Simple name: "Team Alpha" → "team-alpha"
  - Multiple spaces: "Team  Beta" → "team-beta"
  - Mixed case: "TEAM gamma" → "team-gamma"
  - Special characters: "Team #1!" → "team-1"
  - Very long name (>63 chars): truncate or error
  - Unicode/emoji: strip or error
- ✓ ID generation produces unique IDs across multiple calls
- ✓ ID format matches expected pattern: `mem-\d{10}-[a-z]{3}`

**Coverage for `utils/file-ops.sh`:**
- ✓ `create_team_structure` with valid team ID
- ✓ `create_team_structure` with invalid path characters
- ✓ `validate_team_exists` returns 0 for existing team
- ✓ `validate_team_exists` returns 1 for non-existing team
- ✓ `list_teams` with 0 teams (empty directory)
- ✓ `list_teams` with 1 team
- ✓ `list_teams` with multiple teams
- ✓ `list_teams` ignores non-team directories

**Coverage for `utils/json-utils.sh`:**
- ✓ `write_initial_files` creates valid JSON files
- ✓ `append_member` adds member to array
- ✓ `append_member` rejects duplicate email
- ✓ `append_members` processes array correctly
- ✓ `append_members` filters duplicates
- ✓ `remove_member` removes by email
- ✓ `remove_member` handles non-existent email
- ✓ Read operations return valid JSON
- ✓ Handles malformed JSON gracefully
- ✓ Atomic writes (temp file usage)

### 4.2 Integration Testing (Skills)

**Approach:** Manual testing in Claude Code environment with test scenarios

#### Scenario 1: Fresh Team Initialization
**Steps:**
1. Run `/team-init --name="Test Team"`
2. Verify `.team/test-team/` created
3. Verify all three JSON files exist with correct schemas
4. Verify team-config.json has correct team_id and team_name
5. Verify members.json and projects.json are empty arrays
6. Verify detailed summary displayed with paths and next steps

**Expected:** Team created successfully, all files valid

#### Scenario 2: Re-initialization (Merge/Update)
**Steps:**
1. Initialize team with `/team-init --name="Test Team"`
2. Manually add member to members.json via `/add-member`
3. Run `/team-init --name="Test Team"` again
4. Verify member still exists in members.json (data preserved)
5. Verify updated_at timestamp changed in team-config.json

**Expected:** Data preserved, no loss of existing members/projects

#### Scenario 3: Slack Import (with MCP)
**Steps:**
1. Ensure Slack MCP configured
2. Run `/import-slack-channel --team=test-team`
3. Enter search keyword (e.g., "engineering")
4. Select channel from presented options
5. Wait for import completion
6. Verify members.json populated with correct data structure
7. Verify all fields present: name, email, role, timestamps
8. Re-import same channel
9. Verify duplicate detection works (shows "X duplicates skipped")

**Expected:** Members imported correctly, duplicates handled

#### Scenario 4: Slack Import (without MCP)
**Steps:**
1. Ensure Slack MCP NOT configured
2. Run `/import-slack-channel --team=test-team`
3. Verify clear error message displayed
4. Verify error includes setup instructions
5. Verify error mentions docs/setup-slack.md

**Expected:** Clear error, no crash, helpful guidance

#### Scenario 5: Manual Member Management
**Steps:**
1. Run `/add-member --team=test-team`
2. Provide name, email, role via prompts
3. Skip optional git username/email
4. Verify member added to members.json with:
   - Generated member_id
   - All provided fields
   - source: "manual"
   - Current timestamp
5. Run `/remove-member --team=test-team`
6. Select member from list
7. Confirm removal
8. Verify member removed from members.json

**Expected:** Member lifecycle works correctly

#### Scenario 6: Project with External Links
**Steps:**
1. Ensure Jira and GitLab MCPs configured
2. Run `/add-project --team=test-team`
3. Provide project name, repo URL, description
4. Select status: "active"
5. Choose to link Jira board
6. Search for board by keyword
7. Select board from results
8. Choose to link GitLab project
9. Search and select GitLab project
10. Skip Confluence linking
11. Verify projects.json contains:
    - All project fields
    - jira_board_id populated
    - gitlab_project_id populated
    - confluence_space null or absent
12. Verify current_projects array in team-config.json updated

**Expected:** Project created with correct external links

#### Scenario 7: Project without External Links
**Steps:**
1. Run `/add-project --team=test-team`
2. Provide project name only
3. Choose not to link any external tools
4. Verify project created with only basic fields
5. Verify all external link fields are null or absent

**Expected:** Project creation works without external dependencies

#### Scenario 8: Multi-Team Management
**Steps:**
1. Initialize "Team Alpha": `/team-init --name="Team Alpha"`
2. Initialize "Team Beta": `/team-init --name="Team Beta"`
3. Add members to team-alpha
4. Add different members to team-beta
5. Add projects to team-alpha
6. Add different projects to team-beta
7. Verify complete isolation:
   - team-alpha/members.json ≠ team-beta/members.json
   - team-alpha/projects.json ≠ team-beta/projects.json
8. Run `/list-teams`
9. Verify both teams listed with correct info

**Expected:** Teams completely isolated, list shows both

#### Scenario 9: Team Name Edge Cases
**Steps:**
1. Try empty name: `/team-init --name=""`
2. Try spaces only: `/team-init --name="   "`
3. Try very long name (70 chars)
4. Try special characters: `/team-init --name="Team @#$%"`
5. Try unicode: `/team-init --name="Team 🚀"`

**Expected:** Validation errors or proper sanitization

#### Scenario 10: Concurrent Git Modifications
**Steps:**
1. Initialize team and add members
2. Commit and push to git
3. In separate clone, modify members.json (add different member)
4. In first clone, also modify members.json (add another member)
5. Both commit locally
6. One pushes successfully
7. Other attempts to push, gets conflict
8. Resolve conflict manually in editor
9. Verify both members present after resolution

**Expected:** Git workflow works, conflicts resolvable

### 4.3 Edge Cases & Error Conditions

**Test Coverage:**
- ✓ Empty team name
- ✓ Team name with only spaces
- ✓ Team name with special characters
- ✓ Team name longer than 63 characters
- ✓ Team name with unicode/emoji
- ✓ Slack channel with 0 members
- ✓ Slack channel with 1 member
- ✓ Slack channel with 1000+ members
- ✓ Slack member with missing email field
- ✓ Slack member with missing profile title
- ✓ JSON files with Windows line endings (CRLF)
- ✓ JSON files with incorrect permissions
- ✓ `.team/` directory doesn't exist
- ✓ `.team/` exists but is a file, not directory
- ✓ Corrupted JSON file (invalid syntax)
- ✓ Empty JSON file
- ✓ JSON file with incorrect schema
- ✓ Disk full during write operation
- ✓ Permission denied for directory creation
- ✓ Running commands outside git repository
- ✓ MCP timeout during API call
- ✓ MCP returns unexpected response format
- ✓ Network interruption during import
- ✓ Simultaneous writes to same JSON file

### 4.4 Performance Testing

**Scenarios:**
- Import Slack channel with 100 members - should complete in <10 seconds
- Import Slack channel with 500 members - should complete in <30 seconds with batching
- List 20 teams - should complete instantly (<1 second)
- Add project with all external links - should complete in <5 seconds

---
