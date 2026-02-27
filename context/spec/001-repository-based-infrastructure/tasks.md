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

## Slice 4: Add Member Manually

Enable users to manually add team members with the `/add-member` command.

- [ ] **Create `/add-member` skill**
  - [ ] Create `.claude/commands/add-member.md` skill file
  - [ ] Add frontmatter with description: "Add team member manually"
  - [ ] Document usage: `/add-member --team=[team-id]`
  - [ ] Document parameters: `--team` (required)
  - [ ] Document behavior:
    - Validates team exists using bash utility
    - Uses AskUserQuestion to collect: name, email, role/title
    - Optionally asks for git username/email
    - Generates member ID using bash utility
    - Builds member JSON object with current ISO 8601 timestamp and source: "manual"
    - Calls `json-utils.sh append_member` to add to members.json
    - Displays confirmation: "Added [name] to [team-name]"
  - [ ] Add examples section
  - [ ] **[Agent: general-purpose]**

- [ ] **Test adding members**
  - [ ] Run `/add-member --team=test-team`
  - [ ] Provide name: "John Doe", email: "john@example.com", role: "Engineer"
  - [ ] Verify member added to `test-team/members.json` with all fields (member_id, name, email, role, added_at, source)
  - [ ] Verify confirmation message displayed
  - [ ] Add second member with same email: verify duplicate rejected with error message
  - [ ] Add second member with different email: verify successfully added
  - [ ] Verify members.json contains array of 2 members
  - [ ] **[Agent: general-purpose]**

---

## Slice 5: Remove Member

Enable users to remove team members with the `/remove-member` command.

- [ ] **Create `/remove-member` skill**
  - [ ] Create `.claude/commands/remove-member.md` skill file
  - [ ] Add frontmatter with description: "Remove team member"
  - [ ] Document usage: `/remove-member --team=[team-id]`
  - [ ] Document parameters: `--team` (required)
  - [ ] Document behavior:
    - Validates team exists
    - Reads current members from members.json
    - Uses AskUserQuestion to present list of members for selection
    - Confirms removal with user
    - Calls `json-utils.sh remove_member` to remove from members.json
    - Displays confirmation
  - [ ] Add examples section
  - [ ] **[Agent: general-purpose]**

- [ ] **Test removing members**
  - [ ] Verify test-team has 2 members from previous slice
  - [ ] Run `/remove-member --team=test-team`
  - [ ] Select first member from list
  - [ ] Confirm removal
  - [ ] Verify member removed from members.json
  - [ ] Verify only 1 member remains
  - [ ] Verify confirmation message displayed
  - [ ] **[Agent: general-purpose]**

---

## Slice 6: Import Members from Slack

Enable users to import team members from Slack channels with the `/import-slack-channel` command.

- [ ] **Create `/import-slack-channel` skill**
  - [ ] Create `.claude/commands/import-slack-channel.md` skill file
  - [ ] Add frontmatter with description: "Import team members from Slack channel"
  - [ ] Document usage: `/import-slack-channel --team=[team-id]`
  - [ ] Document parameters: `--team` (required)
  - [ ] Document behavior:
    - Validates team exists
    - Checks if Slack MCP is available; if not, shows error: "Slack MCP not configured. See docs/setup-slack.md"
    - Uses AskUserQuestion to get channel search keyword
    - Calls Slack MCP: `conversations.list` to search channels
    - Presents channel options using AskUserQuestion (show name, member count, description)
    - After selection, calls Slack MCP: `conversations.members` to get member IDs
    - For each member, calls Slack MCP: `users.info` to get profile (name, email, role)
    - Generates member IDs using bash utility
    - Builds member JSON objects with source: "slack_import"
    - Calls `json-utils.sh append_members` to add all (skips duplicates by email)
    - Displays summary: "Imported X members from #channel-name (Y duplicates skipped)"
  - [ ] Add examples section
  - [ ] Document error handling for missing MCP
  - [ ] **[Agent: general-purpose]**

- [ ] **Test Slack import (requires Slack MCP)**
  - [ ] Verify Slack MCP is configured (check `.claude/mcp.json` or show error)
  - [ ] Run `/import-slack-channel --team=test-team`
  - [ ] Enter search keyword for a test Slack channel
  - [ ] Select channel from presented options
  - [ ] Wait for import to complete
  - [ ] Verify members.json populated with Slack members (name, email, role, source: "slack_import")
  - [ ] Verify summary shows number imported and duplicates skipped
  - [ ] Re-import same channel: verify all marked as duplicates
  - [ ] **[Agent: general-purpose]**
  - [ ] **Note: Requires Slack MCP configured - if not available, document manual testing steps**

---

## Slice 7: Add Project (Basic)

Enable users to add projects without external tool links.

- [ ] **Create `/add-project` skill (basic version)**
  - [ ] Create `.claude/commands/add-project.md` skill file
  - [ ] Add frontmatter with description: "Add project to team"
  - [ ] Document usage: `/add-project --team=[team-id]`
  - [ ] Document parameters: `--team` (required)
  - [ ] Document behavior:
    - Validates team exists
    - Uses AskUserQuestion to collect: project name (required), repository URL (optional), description (optional)
    - Uses AskUserQuestion for status dropdown: active, archived, planned, on-hold
    - For now, skip external tool linking (add in next slice)
    - Generates project ID using bash utility
    - Builds project JSON object with timestamps
    - Calls `json-utils.sh append_project` to add to projects.json
    - Calls `json-utils.sh update_current_projects` to add to current_projects array
    - Displays confirmation with project details
  - [ ] Add examples section
  - [ ] **[Agent: general-purpose]**

- [ ] **Test adding basic project**
  - [ ] Run `/add-project --team=test-team`
  - [ ] Provide: name "Test Project", repo URL "https://github.com/test/repo", description "Test", status "active"
  - [ ] Verify project added to projects.json with all fields (project_id, name, repository_url, description, status, team_id, timestamps)
  - [ ] Verify external link fields (jira_board_id, gitlab_project_id, confluence_space) are null or absent
  - [ ] Verify project ID added to current_projects array in team-config.json
  - [ ] Verify confirmation message displayed
  - [ ] **[Agent: general-purpose]**

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
