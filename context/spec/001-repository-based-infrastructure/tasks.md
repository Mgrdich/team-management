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

- [ ] **Enhance `/add-project` skill for external links**
  - [ ] Update `.claude/commands/add-project.md` skill file
  - [ ] Add to behavior documentation:
    - After collecting basic project info, ask which external tools to link (Jira, GitLab, Confluence) using AskUserQuestion
    - For each selected tool:
      - Check if respective MCP is available (Jira/Atlassian MCP, GitLab MCP, Confluence/Atlassian MCP)
      - If not available, show error with setup instructions
      - Use AskUserQuestion to get search keyword
      - Call MCP to search resources (boards for Jira, projects for GitLab, spaces for Confluence)
      - Present search results using AskUserQuestion
      - Store selected resource IDs in project JSON
    - If user skips external linking, project still created successfully
  - [ ] Update examples to show external linking
  - [ ] Document MCP requirements and error handling
  - [ ] **[Agent: general-purpose]**

- [ ] **Test project with external links (requires MCPs)**
  - [ ] Verify Jira MCP and GitLab MCP configured (or document limitation)
  - [ ] Run `/add-project --team=test-team`
  - [ ] Provide basic project info
  - [ ] Choose to link Jira board
  - [ ] Search for board by keyword
  - [ ] Select board from results
  - [ ] Choose to link GitLab project
  - [ ] Search and select GitLab project
  - [ ] Skip Confluence linking
  - [ ] Verify projects.json contains project with jira_board_id and gitlab_project_id populated
  - [ ] Verify confluence_space is null or absent
  - [ ] **[Agent: general-purpose]**
  - [ ] **Note: Requires Jira and GitLab MCPs - if not available, document manual testing steps**

---

## Slice 9: Multi-Team Isolation

Verify that multiple teams can coexist without interference.

- [ ] **Test multi-team isolation**
  - [ ] Initialize second team: `/team-init --name="Team Beta"`
  - [ ] Add member to team-alpha: "Alice" with email "alice@example.com"
  - [ ] Add different member to team-beta: "Bob" with email "bob@example.com"
  - [ ] Add project to team-alpha: "Alpha Project"
  - [ ] Add different project to team-beta: "Beta Project"
  - [ ] Verify team-alpha/members.json contains only Alice
  - [ ] Verify team-beta/members.json contains only Bob
  - [ ] Verify team-alpha/projects.json contains only Alpha Project
  - [ ] Verify team-beta/projects.json contains only Beta Project
  - [ ] Run `/list-teams`: verify both teams shown with correct member/project counts
  - [ ] **[Agent: general-purpose]**

---

## Slice 10: Edge Cases and Error Handling

Test edge cases and verify proper error handling.

- [ ] **Test edge cases**
  - [ ] Team name validation:
    - Empty name: verify error or prompt
    - Spaces only: verify error or sanitization
    - Very long name (70+ chars): verify truncation or error
    - Special characters: verify sanitization removes them
  - [ ] Duplicate prevention:
    - Add member with same email twice: verify error
    - Import Slack channel twice: verify duplicates skipped
  - [ ] Non-existent team:
    - Run `/add-member --team=nonexistent`: verify error "Team not found"
  - [ ] Missing MCP:
    - Run `/import-slack-channel` without Slack MCP: verify clear error with setup instructions
    - Run `/add-project` and try to link Jira without Jira MCP: verify clear error
  - [ ] JSON corruption:
    - Manually corrupt members.json (invalid JSON syntax)
    - Run `/add-member`: verify detects corruption and shows error
  - [ ] **[Agent: general-purpose]**

---

## Slice 11: Documentation and Final Polish

Create setup documentation and finalize implementation.

- [ ] **Create setup documentation**
  - [ ] Create `docs/setup-slack.md` with instructions for configuring Slack MCP
  - [ ] Create `docs/setup-jira.md` with instructions for configuring Jira/Atlassian MCP
  - [ ] Create `docs/setup-gitlab.md` with instructions for configuring GitLab MCP
  - [ ] Create `docs/setup-confluence.md` with instructions for configuring Confluence/Atlassian MCP
  - [ ] Create `README.md` or update existing with:
    - Feature overview
    - Quick start guide
    - List of available commands
    - Requirements (bash, jq, git, Claude Code)
    - Optional MCP setup links
  - [ ] **[Agent: general-purpose]**

- [ ] **Add .gitignore for .team directory**
  - [ ] Create `.team/.gitignore` to exclude:
    - `.backup/` (if implementing backup functionality)
    - `.temp` (temporary files)
    - `logs/` (if adding logging later)
  - [ ] Ensure `.team/*/` data files ARE tracked (members.json, projects.json, team-config.json)
  - [ ] **[Agent: general-purpose]**

- [ ] **Final integration test**
  - [ ] Start fresh (delete .team directory)
  - [ ] Run through complete user journey:
    - Initialize team
    - List teams
    - Add member manually
    - Import from Slack (if MCP available)
    - Add project with external links
    - Remove member
    - List teams (verify counts)
  - [ ] Verify all data correct in JSON files
  - [ ] Verify git tracking works (commit, push, pull)
  - [ ] **[Agent: general-purpose]**

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
