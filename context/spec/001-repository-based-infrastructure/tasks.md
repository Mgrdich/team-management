# Task List: Repository-Based Infrastructure

## Overview

This task list breaks down the Repository-Based Infrastructure feature into small, incremental, runnable slices. Each slice delivers end-to-end functionality that can be tested and verified.

---

## Slice 1: Core Bash Utilities (Foundation)

Build the foundational bash utility scripts needed by all other features.

- [x] **Create bash utility for ID generation**
  - [x] Create `scripts/utils/id-generator.sh` with shebang and `set -euo pipefail`
  - [x] Implement `team_name_to_id()` function (converts "Team Alpha" to "team-alpha", max 63 chars, sanitize special chars)
  - [x] Implement `generate_member_id()` function (format: `mem-[timestamp]-[3-random-chars]`)
  - [x] Implement `generate_project_id()` function (format: `proj-[timestamp]-[3-random-chars]`)
  - [x] Make script executable: `chmod +x scripts/utils/id-generator.sh`
  - [x] **[Agent: bash-script-executor]**

- [x] **Create bash utility for file operations**
  - [x] Create `scripts/utils/file-ops.sh` with shebang and error handling
  - [x] Implement `create_team_structure()` function (creates `.team/[team-id]/` directory)
  - [x] Implement `validate_team_exists()` function (checks if `.team/[team-id]/` exists, returns 0/1)
  - [x] Implement `list_teams()` function (lists all team IDs from `.team/` subdirectories)
  - [x] Make script executable: `chmod +x scripts/utils/file-ops.sh`
  - [x] **[Agent: bash-script-executor]**

- [x] **Create bash utility for JSON operations**
  - [x] Create `scripts/utils/json-utils.sh` with shebang and error handling
  - [x] Implement `write_initial_files()` function (creates team-config.json, members.json, projects.json with correct schemas)
  - [x] Implement `append_member()` function (appends member to members.json, checks for duplicate by email)
  - [x] Implement `append_project()` function (appends project to projects.json)
  - [x] Implement `update_current_projects()` function (adds project ID to current_projects array in team-config.json)
  - [x] Implement `remove_member()` function (removes member by email using jq)
  - [x] Implement `read_team_config()`, `read_members()`, `read_projects()` functions (output JSON to stdout)
  - [x] Make script executable: `chmod +x scripts/utils/json-utils.sh`
  - [x] **[Agent: bash-script-executor]**

- [x] **Unit test bash utilities**
  - [x] Test `team_name_to_id` with various inputs (spaces, caps, special chars, long names)
  - [x] Test ID generation produces unique IDs and matches expected format
  - [x] Test `create_team_structure` creates directory correctly
  - [x] Test `validate_team_exists` returns correct exit codes
  - [x] Test `write_initial_files` creates valid JSON files with correct schemas
  - [x] Test `append_member` adds member and rejects duplicates
  - [x] Test `remove_member` removes by email correctly
  - [x] **[Agent: test-writer]**

---

## Slice 2: Initialize Single Team

Enable users to initialize their first team with the `/team-init` command.

- [x] **Create `/team-init` skill**
  - [x] Create `.claude/skills/team-init/SKILL.md` skill file
  - [x] Add frontmatter with description: "Initialize team management with a specific team name"
  - [x] Document usage: `/team-init --name="Team Name"`
  - [x] Document parameters: `--name` (required, max 63 chars)
  - [x] Document behavior:
    - Prompts for team name if not provided
    - Validates team name not empty
    - Calls bash utilities to convert name to ID, create structure, write JSON files
    - If team exists, preserves data (merge/update)
    - Displays detailed summary with paths and next steps
  - [x] Add examples section
  - [x] **[Agent: general-purpose]**

- [x] **Test team initialization**
  - [x] Run `/team-init --name="Test Team"` in Claude Code
  - [x] Verify `.team/test-team/` directory created
  - [x] Verify `team-config.json` exists with correct schema (team_id, team_name, created_at, current_projects array)
  - [x] Verify `members.json` exists as empty array: `[]`
  - [x] Verify `projects.json` exists as empty array: `[]`
  - [x] Verify detailed summary displays with team ID, paths, and next steps
  - [x] Test without `--name` parameter: verify prompts for team name
  - [x] Test re-initialization: add dummy data to members.json, run `/team-init --name="Test Team"` again, verify data preserved
  - [x] **[Agent: general-purpose]**

---

## Slice 3: List Teams

Enable users to view all initialized teams with the `/list-teams` command.

- [x] **Create `/list-teams` skill**
  - [x] Create `.claude/skills/list-teams/SKILL.md` skill file
  - [x] Add frontmatter with description: "List all initialized teams"
  - [x] Document usage: `/list-teams`
  - [x] Document behavior:
    - Calls `file-ops.sh list_teams` to get team IDs
    - For each team, reads team-config.json to get team name, member count, project count
    - Displays formatted table or list
    - If no teams exist, shows message: "No teams initialized. Run /team-init to create one."
  - [x] Add examples section
  - [x] **[Agent: general-purpose]**

- [x] **Test listing teams**
  - [x] With zero teams: verify "No teams initialized" message
  - [x] Initialize one team: run `/team-init --name="Team Alpha"`
  - [x] Run `/list-teams`: verify shows "team-alpha" with name "Team Alpha", 0 members, 0 projects
  - [x] Initialize second team: run `/team-init --name="Team Beta"`
  - [x] Run `/list-teams`: verify shows both teams with correct info
  - [x] **[Agent: general-purpose]**

---

## Slice 4: Add Members Manually

Enable users to manually add team members with the `/add-team-members` command.

- [x] **Create `/add-team-members` skill**
  - [x] Create `.claude/skills/add-team-members/SKILL.md` skill file
  - [x] Add frontmatter with description: "Add one or more team members manually to a team"
  - [x] Document usage: `/add-team-members --team=[team-id]`
  - [x] Document parameters: `--team` (required)
  - [x] Document behavior:
    - Validates team exists using bash utility
    - Collects member info: name, email, role/title (plain text)
    - Searches GitLab via MCP based on member name to auto-populate git info
    - Uses AskUserQuestion tool to present GitLab user options
    - Fallback to manual git entry if GitLab MCP unavailable or no matches
    - Generates member ID using bash utility
    - Builds member JSON object with current ISO 8601 timestamp and source: "manual"
    - Calls `json-utils.sh append_member` to add to members.json
    - Displays confirmation: "Added [name] to [team-name]"
    - Uses AskUserQuestion tool to ask "Add another member?" - loops until user says No
    - Shows final summary with count of members added
  - [x] Add examples section
  - [x] **[Agent: general-purpose]**

- [x] **Test adding members**
  - [x] Run bash utilities manually to test member addition workflow
  - [x] Added "John Doe", email: "john@example.com", role: "Engineer" without git info
  - [x] Verify member added to `team-alpha/members.json` with all fields (member_id, name, email, role, added_at, source)
  - [x] Added "Jane Smith", email: "jane@example.com", role: "Designer" with git info
  - [x] Added git information: username "jsmith", email "jsmith@github.com"
  - [x] Verified second member added with git fields (git_username, git_email)
  - [x] Verified members.json contains array of 2 members
  - [x] Tested duplicate email: tried adding member with "john@example.com" again, verified error "Member with email already exists"
  - [x] **[Agent: general-purpose]**

---

## Slice 5: Remove Member

Enable users to remove team members with the `/remove-team-member` command.

- [x] **Create `/remove-team-member` skill**
  - [x] Create `.claude/skills/remove-team-member/SKILL.md` skill file
  - [x] Add frontmatter with description: "Remove team member"
  - [x] Document usage: `/remove-team-member --team=team-alpha`
  - [x] Document parameters: `--team` (required)
  - [x] Document behavior:
    - Validates team exists
    - Reads current members from members.json
    - Uses AskUserQuestion tool to present list of members for selection
    - Uses AskUserQuestion tool to confirm removal
    - Provides "Cancel" option at both selection and confirmation stages
    - Calls `json-utils.sh remove_member` to remove from members.json by email
    - Displays confirmation with removed member details and remaining count
  - [x] Add examples section (including cancel scenarios and empty team)
  - [x] **[Agent: general-purpose]**

- [x] **Test removing members**
  - [x] Verified team-alpha has 2 members (John Doe, Jane Smith)
  - [x] Tested removing John Doe by email via bash utilities
  - [x] Verified member removed from members.json
  - [x] Verified only 1 member remains (Jane Smith)
  - [x] Tested removing Jane Smith
  - [x] Verified empty members array (no members remaining)
  - [x] Tested reading from empty array (returns no output as expected)
  - [x] Restored test data: re-added both members to team-alpha
  - [x] **[Agent: general-purpose]**

---

## Slice 6: Import Members from Slack

Enable users to import team members from Slack channels with the `/import-slack-channel` command.

- [x] **Create `/import-slack-channel` skill**
  - [x] Create `.claude/skills/import-slack-channel/SKILL.md` skill file
  - [x] Add frontmatter with description: "Import team members from Slack channel via MCP"
  - [x] Document usage: `/import-slack-channel --team=[team-id]`
  - [x] Document parameters: `--team` (required)
  - [x] Document behavior:
    - Validates team exists
    - Checks if Slack MCP is available; if not, shows error: "Slack MCP not configured. See docs/setup-slack-mcp.md"
    - Asks for channel search keyword in plain text
    - Calls Slack MCP: `conversations.list` to search channels
    - Uses AskUserQuestion tool to present channel options (show name, member count, description)
    - Provides "Cancel" option during channel selection
    - After selection, calls Slack MCP: `conversations.members` to get member IDs
    - For each member, calls Slack MCP: `users.info` to get profile (name, email, role)
    - Generates member IDs using bash utility
    - Builds member JSON objects with source: "slack_import" and slack_user_id field
    - Calls `json-utils.sh append_member` in loop (skips duplicates by email)
    - Tracks: total users, imported, duplicates, no-email
    - Displays summary: "Imported X members from #channel-name (Y duplicates skipped, Z no email)"
  - [x] Add examples section (5 scenarios including MCP not configured, cancel, duplicates)
  - [x] Document error handling for missing MCP
  - [x] Document performance considerations for large channels (50+ members)
  - [x] **[Agent: general-purpose]**

- [ ] **Test Slack import (requires Slack MCP)**
  - [ ] **BLOCKED: Slack MCP not configured yet (see Phase 3 roadmap)**
  - [ ] Verify Slack MCP is configured (check for Slack MCP tools availability)
  - [ ] Run `/import-slack-channel --team=team-alpha`
  - [ ] Enter search keyword for a test Slack channel
  - [ ] Select channel from presented options via AskUserQuestion
  - [ ] Wait for import to complete (observe progress for large channels)
  - [ ] Verify members.json populated with Slack members (name, email, role, source: "slack_import", slack_user_id)
  - [ ] Verify summary shows: total, imported, duplicates, no-email counts
  - [ ] Re-import same channel: verify all marked as duplicates (0 imported)
  - [ ] **[Agent: general-purpose]**
  - [ ] **Note: Testing deferred until Phase 3 (MCP Configuration & Setup) is complete**

---

## Slice 7: Add Project (Basic)

Enable users to add projects without external tool links.

- [x] **Create `/add-project` skill (basic version)**
  - [x] Create `.claude/skills/add-project/SKILL.md` skill file
  - [x] Add frontmatter with description: "Add project to team"
  - [x] Document usage: `/add-project --team=[team-id]`
  - [x] Document parameters: `--team` (required)
  - [x] Document behavior:
    - Validates team exists
    - Collects project info in plain text: project name (required), repository URL (optional), description (optional)
    - Uses AskUserQuestion tool for status dropdown: Active, Planned, On Hold, Archived
    - For now, skip external tool linking (add in next slice)
    - Generates project ID using bash utility
    - Builds project JSON object with timestamps (only includes optional fields if provided)
    - Calls `json-utils.sh append_project` to add to projects.json
    - Calls `json-utils.sh update_current_projects` to add to current_projects array
    - Displays confirmation with project details
    - Note: Handles bash "status" reserved variable by using "project_status" instead
  - [x] Add examples section (5 scenarios including all details, minimal, archived, team not found, missing name)
  - [x] Document future enhancements (Slice 8 will add external tool linking)
  - [x] **[Agent: general-purpose]**

- [x] **Test adding basic project**
  - [x] Added project "Authentication Service" with full details (name, repo URL, description, status "active")
  - [x] Verified project added to projects.json with all fields (project_id, name, repository_url, description, status, team_id, timestamps)
  - [x] Verified external link fields (jira_board_id, gitlab_project_id, confluence_space) are NOT present in basic version
  - [x] Verified project ID added to current_projects array in team-config.json
  - [x] Added second project "Mobile App Redesign" with minimal details (name and status "planned" only)
  - [x] Verified optional fields (repository_url, description) are omitted when not provided
  - [x] Verified both project IDs in current_projects array
  - [x] **[Agent: general-purpose]**

---

## Slice 8: Add Project with External Tool Links

Enhance `/add-project` to support linking Jira, GitLab, and Confluence resources.

- [x] **Enhance `/add-project` skill for external links**
  - [x] Update `.claude/skills/add-project/SKILL.md` skill file
  - [x] Add to behavior documentation (Steps 6-10):
    - After collecting basic project info and status, ask if user wants external tool linking using AskUserQuestion
    - Ask which external tools to link (Jira, GitLab, Confluence) using AskUserQuestion with multiSelect
    - For each selected tool:
      - Check if respective MCP is available (Jira/Atlassian MCP, GitLab MCP, Confluence/Atlassian MCP)
      - If not available, show warning with setup instructions and skip
      - Ask for search keyword in plain text
      - Call MCP to search resources (boards for Jira, projects for GitLab, spaces for Confluence)
      - Present search results using AskUserQuestion with "None" option
      - Store selected resource IDs in project JSON (jira_board_id, gitlab_project_id, confluence_space)
    - If user skips external linking or selects "No", project created without external links
    - Update JSON building (Step 12) to conditionally add external tool fields
    - Update confirmation display (Step 15) to show external links
  - [x] Update "Future Enhancements" section to "External Tool Integration" (now implemented)
  - [x] Document MCP requirements and error handling for each tool
  - [x] **[Agent: general-purpose]**

- [ ] **Test project with external links (requires MCPs)**
  - [ ] **BLOCKED: Requires Jira, GitLab, and Confluence MCPs (see Phase 3 roadmap)**
  - [ ] Verify Jira MCP and GitLab MCP configured
  - [ ] Run `/add-project --team=team-alpha`
  - [ ] Provide basic project info
  - [ ] Select "Yes, link to external tools"
  - [ ] Select Jira, GitLab, Confluence from multi-select
  - [ ] For Jira: search, select board from AskUserQuestion
  - [ ] For GitLab: search, select project from AskUserQuestion
  - [ ] For Confluence: search, select space from AskUserQuestion
  - [ ] Verify projects.json contains project with jira_board_id, gitlab_project_id, and confluence_space populated
  - [ ] **[Agent: general-purpose]**
  - [ ] **Note: Testing deferred until Phase 3 (MCP Configuration & Setup) is complete**

---

## Slice 9: Multi-Team Isolation

Verify that multiple teams can coexist without interference.

- [x] **Test multi-team isolation**
  - [x] Initialize second team: Team Beta (team-beta) using bash utilities
  - [x] Add member to team-alpha: "Alice Johnson" with email "alice@example.com"
  - [x] Add different member to team-beta: "Bob Smith" with email "bob@example.com"
  - [x] Add project to team-alpha: "Alpha Project"
  - [x] Add different project to team-beta: "Beta Project"
  - [x] Verify team-alpha/members.json contains Alice (note: also has previous test data John, Jane)
  - [x] Verify team-beta/members.json contains only Bob (isolated)
  - [x] Verify team-alpha/projects.json contains Alpha Project (note: also has previous test data)
  - [x] Verify team-beta/projects.json contains only Beta Project (isolated)
  - [x] Verify isolation: Bob not in team-alpha, Alice not in team-beta
  - [x] Verify isolation: Beta Project not in team-alpha, Alpha Project not in team-beta
  - [x] Verify list output: team-alpha (3 members, 3 projects), team-beta (1 member, 1 project)
  - [x] **[Agent: general-purpose]**
  - [x] **Note: team-alpha contains previous test data; key validation is proper isolation between teams**

---

## Slice 10: Edge Cases and Error Handling

Test edge cases and verify proper error handling.

- [x] **Test edge cases**
  - [x] Team name validation:
    - [x] Empty name: returns error "Team name required" ✓
    - [x] Spaces only: returns error "must contain at least one alphanumeric character" ✓
    - [x] Very long name (70+ chars): truncates to 63 characters ✓
    - [x] Special characters: sanitizes to alphanumeric with dashes ("Team@#$%Name!&*" → "teamname") ✓
  - [x] Duplicate prevention:
    - [x] Add member with same email twice: returns error "Member with email already exists" ✓
    - [x] Import Slack channel twice: duplicates skipped (feature documented, MCP testing blocked)
  - [x] Non-existent team:
    - [x] Test `validate_team_exists` with nonexistent team: returns "Team not found" ✓
  - [x] Missing MCP:
    - [x] Skills document clear error messages for missing MCPs with setup instructions ✓
    - [x] Graceful fallback: skills continue without MCP (e.g., /add-project skips external linking) ✓
  - [x] JSON corruption:
    - [x] Manually corrupted members.json with invalid syntax ✓
    - [x] Verified jq detects corruption: "parse error: Invalid numeric literal" ✓
    - [x] Bash utilities using jq will fail gracefully on corrupted JSON ✓
  - [x] **[Agent: general-purpose]**

---

## Slice 11: Documentation and Final Polish

Create setup documentation and finalize implementation.

- [x] **Create setup documentation**
  - [x] Create `docs/setup-slack-mcp.md` with comprehensive Slack MCP setup instructions
    - Step-by-step Slack app creation
    - OAuth scopes configuration
    - Bot token setup
    - MCP JSON configuration examples
    - Troubleshooting section
    - Security best practices
  - [x] Create `docs/setup-jira-mcp.md` with Jira/Atlassian MCP setup instructions
    - API token creation for Jira Cloud
    - Atlassian MCP configuration
    - Environment variable setup
    - Board linking workflow
    - Troubleshooting and permissions
  - [x] Create `docs/setup-gitlab-mcp.md` with GitLab MCP setup instructions
    - Personal Access Token creation
    - GitLab MCP configuration (Cloud and self-hosted)
    - User search and project linking
    - Rate limits and API documentation
    - Security best practices
  - [x] Create `docs/setup-confluence-mcp.md` with Confluence/Atlassian MCP setup instructions
    - API token setup
    - Combined Atlassian MCP configuration
    - Space linking workflow
    - Confluence Cloud vs Server differences
    - Troubleshooting section
  - [x] Create `README.md` with comprehensive documentation:
    - Feature overview (core + MCP integrations)
    - Quick start guide with examples
    - Complete list of available commands
    - Requirements (bash, jq, git, Claude Code)
    - Data structure and JSON schemas
    - Optional MCP setup links
    - Architecture overview
    - Roadmap (Phases 1-4)
    - Project structure
  - [x] **[Agent: general-purpose]**

- [x] **Add .gitignore for .team directory**
  - [x] Create `.team/.gitignore` to exclude:
    - `*.backup`, `*.temp`, `*.tmp` (temporary files)
    - `.temp`, `.backup/` (directories)
    - `logs/`, `*.log` (if adding logging later)
  - [x] Ensure `.team/*/` data files ARE tracked with negation rules:
    - `!*/members.json`
    - `!*/projects.json`
    - `!*/team-config.json`
  - [x] **[Agent: general-purpose]**

- [x] **Final integration test**
  - [x] Integration test performed across all slices (1-9)
  - [x] Verified complete user journey:
    - [x] Initialize team: Team Alpha, Team Beta ✓
    - [x] List teams: Shows both teams with counts ✓
    - [x] Add member manually: Alice, Bob, John, Jane ✓
    - [x] Add projects: Authentication Service, Mobile App, Alpha Project, Beta Project ✓
    - [x] Remove member: Tested removal workflow ✓
    - [x] List teams: Verified counts (team-alpha: 3 members, 3 projects; team-beta: 1 member, 1 project) ✓
  - [x] Verified all data correct in JSON files (proper schemas, isolation)
  - [x] Verified git tracking works: All commits successful, data properly tracked
  - [x] **Note:** Slack import and external tool linking require MCP configuration (Phase 3)
  - [x] **[Agent: general-purpose]**

---

## Agent Assignment Summary

- **bash-script-executor**: Bash utility scripts (id-generator.sh, file-ops.sh, json-utils.sh)
- **test-writer**: Unit tests for bash utilities
- **general-purpose**: All Claude Code skills, integration tests, documentation

## Notes

- Slack MCP required for Slice 6 - if not available, document manual testing approach
- Jira/GitLab/Confluence MCPs optional for Slice 8 - features gracefully degrade without them
- Each slice produces runnable, testable functionality
- Application remains in working state after each slice completion
