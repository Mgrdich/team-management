# Tasks: Real-time Status Dashboard

## Overview

This task list breaks down the `/team-status` command implementation into vertical slices. Each slice delivers a small, testable piece of end-to-end functionality.

**Architecture:** Claude Code Skill with MCP integration (Jira, GitLab, Slack)

---

## Slice 1: Basic Skill Structure with Team Selection

Create the minimal skill structure and implement team selection without any actual status display.

- [x] **Create skill file structure**
  - [x] Create `.claude/skills/team-status/SKILL.md` with YAML frontmatter
  - [x] Add usage documentation section
  - [x] Add placeholder instructions section
  - **[Agent: general-purpose]**

- [x] **Implement team selection logic**
  - [x] Call `file-ops.sh list_teams` to get team IDs
  - [x] Read team names from each `team-config.json`
  - [x] Use AskUserQuestion to prompt user when `--team` missing
  - [x] Parse `--team` parameter when provided
  - **[Agent: general-purpose]**

- [x] **Add placeholder response**
  - [x] Display message: "Team status feature coming soon for [team-name]"
  - **[Agent: general-purpose]**

- [ ] **Test Slice 1**
  - [ ] Run `/team-status` without parameters → verify team selection prompt appears
  - [ ] Run `/team-status --team=team-alpha` → verify team name shown in placeholder message
  - [ ] Verify no errors, skill executes successfully
  - **[Agent: general-purpose]**

---

## Slice 2: Display Jira Tasks (Default View)

Fetch and display Jira tasks for a team in a basic table format.

- [x] **Implement Jira MCP availability check**
  - [x] Check for Jira MCP tools availability
  - [x] Display error if unavailable: "Jira MCP not configured..."
  - [x] Exit if Jira unavailable (Jira is required)
  - **[Agent: general-purpose]**

- [x] **Load team members and projects**
  - [x] Read `members.json` and extract email addresses
  - [x] Read `projects.json` and extract Jira board IDs
  - [x] Build member lookup map (email → name)
  - **[Agent: general-purpose]**

- [x] **Query Jira via MCP**
  - [x] Build JQL query: `assignee in (emails...) AND status not in (Done, Closed, Resolved)`
  - [x] Execute Jira MCP search_issues call
  - [x] Parse response: extract key, summary, status, assignee
  - [x] Filter out completed tasks
  - **[Agent: general-purpose]**

- [x] **Render basic table**
  - [x] Build table with columns: Member | Task ID | Title | Status
  - [x] Use bash `column -t -s '|'` or `printf` for formatting
  - [x] Sort by member name alphabetically
  - **[Agent: general-purpose]**

- [ ] **Test Slice 2** (requires Jira MCP configured)
  - [ ] Run `/team-status --team=team-alpha`
  - [ ] Verify Jira tasks displayed in table format
  - [ ] Verify only active tasks shown (no Done/Closed)
  - [ ] Verify table columns: Member, Task ID, Title, Status
  - [ ] Test with team that has 0 tasks → should show empty message
  - **[Agent: general-purpose]**

---

## Slice 3: Add GitLab Issues and Merge Requests

Integrate GitLab data and merge with Jira results.

- [x] **Implement GitLab MCP availability check**
  - [x] Check for GitLab MCP tools availability
  - [x] If unavailable, show warning and continue with Jira-only
  - [x] Do NOT exit if GitLab unavailable (optional integration)
  - **[Agent: general-purpose]**

- [x] **Query GitLab via MCP**
  - [x] Extract GitLab project IDs from `projects.json`
  - [x] Extract git_email addresses from `members.json`
  - [x] Query GitLab issues by project and by assignee
  - [x] Query GitLab merge requests by project and by assignee
  - [x] Parse responses: extract iid, title, state, assignee
  - [x] Filter out closed/merged items
  - **[Agent: general-purpose]**

- [x] **Merge Jira and GitLab results**
  - [x] Combine jira_issues + gitlab_issues + gitlab_mrs
  - [x] Deduplicate if needed
  - [x] Sort by member name, then by status
  - **[Agent: general-purpose]**

- [x] **Update table rendering**
  - [x] Display GitLab MRs with "!" prefix (e.g., "!456")
  - [x] Display GitLab issues with "#" prefix (e.g., "#123")
  - [x] Keep same table format
  - **[Agent: general-purpose]**

- [ ] **Test Slice 3** (requires Jira + GitLab MCPs configured)
  - [ ] Run `/team-status --team=team-alpha`
  - [ ] Verify both Jira and GitLab tasks shown
  - [ ] Verify GitLab MRs have "!" prefix
  - [ ] Verify GitLab issues have "#" prefix
  - [ ] Test with GitLab MCP disabled → verify warning shown, Jira-only results
  - **[Agent: general-purpose]**

---

## Slice 4: Add Member Filtering

Implement the `--member` parameter to filter tasks by team member.

- [x] **Parse --member parameter**
  - [x] Extract `--member` from command arguments
  - [x] Support formats: first name, full name, email
  - [x] Search members.json for matches
  - **[Agent: general-purpose]**

- [x] **Handle multiple matches**
  - [x] If multiple members match (e.g., two "Sarah"s), use AskUserQuestion to select
  - [x] Display member name and email in options
  - **[Agent: general-purpose]**

- [x] **Filter results by member**
  - [x] After fetching Jira/GitLab, filter where assignee matches selected member
  - [x] Display error if no member found: "No team member found matching..."
  - **[Agent: general-purpose]**

- [ ] **Test Slice 4**
  - [ ] Run `/team-status --team=team-alpha --member=sarah`
  - [ ] Verify only Sarah's tasks shown
  - [ ] Test with first name: `/team-status --team=team-alpha --member=john`
  - [ ] Test with email: `/team-status --team=team-alpha --member=john@example.com`
  - [ ] Test with non-existent member → verify error message
  - [ ] Test with ambiguous name (2 matches) → verify disambiguation prompt
  - **[Agent: general-purpose]**

---

## Slice 5: Add Natural Language Query Support

Parse natural language queries to filter results dynamically.

- [x] **Implement query parsing**
  - [x] Extract query string from command arguments (text after parameters)
  - [x] Parse for patterns: "blocked", "in progress", member names, keywords
  - [x] Build filter criteria: status_filter, member_filter, keyword_filter
  - **[Agent: general-purpose]**

- [x] **Apply status filters**
  - [x] "blocked" / "blockers" → filter to status=Blocked
  - [x] "in progress" → filter to status="In Progress"
  - [x] Apply after fetching from MCP
  - **[Agent: general-purpose]**

- [x] **Apply keyword filters**
  - [x] Search task title/description for keyword (case-insensitive)
  - [x] Support queries like "auth feature", "payment"
  - **[Agent: general-purpose]**

- [x] **Apply combined filters**
  - [x] Support "sarah's blocked tasks" → member + status filter
  - [x] Support "jira only" → exclude GitLab results
  - [x] Support "merge requests" / "MRs" → show only GitLab MRs
  - **[Agent: general-purpose]**

- [x] **Add query fallback**
  - [x] If query cannot be parsed, show default view
  - [x] Display helper message: "Showing default view. Try queries like..."
  - **[Agent: general-purpose]**

- [ ] **Test Slice 5**
  - [ ] Run `/team-status --team=team-alpha "blocked tasks"`
  - [ ] Verify only blocked tasks shown
  - [ ] Run `/team-status --team=team-alpha "sarah's work"`
  - [ ] Verify only Sarah's tasks shown
  - [ ] Run `/team-status --team=team-alpha "auth feature"`
  - [ ] Verify keyword search in titles
  - [ ] Run `/team-status --team=team-alpha "sarah's blocked tasks"`
  - [ ] Verify combined filters work
  - [ ] Run `/team-status --team=team-alpha "jira only"`
  - [ ] Verify no GitLab results shown
  - [ ] Run with ambiguous query → verify default view + helper message
  - **[Agent: general-purpose]**

---

## Slice 6: Add Slack Name Enrichment

Enrich member display names with Slack names when Slack MCP available.

- [x] **Implement Slack MCP availability check**
  - [x] Check for Slack MCP tools availability
  - [x] If unavailable, silently fall back to members.json names
  - [x] No error shown (graceful degradation)
  - **[Agent: general-purpose]**

- [x] **Fetch Slack display names**
  - [x] For each member with `slack_user_id` in members.json
  - [x] Call Slack MCP `users.info`
  - [x] Extract `profile.display_name` or `profile.real_name`
  - [x] Build name map (email → slack_name)
  - **[Agent: general-purpose]**

- [x] **Use Slack names in table**
  - [x] Display Slack name if available
  - [x] Fall back to members.json name if Slack unavailable or user not found
  - **[Agent: general-purpose]**

- [ ] **Test Slice 6** (requires Slack MCP configured)
  - [ ] Add `slack_user_id` to a team member in members.json
  - [ ] Run `/team-status --team=team-alpha`
  - [ ] Verify Slack display name shown for that member
  - [ ] Test with Slack MCP disabled → verify members.json name used
  - [ ] Test with invalid slack_user_id → verify fallback to local name
  - **[Agent: general-purpose]**

---

## Slice 7: Add Adaptive Column Display

Allow users to request additional columns via natural language.

- [x] **Parse column requests**
  - [x] Detect keywords in query: "source", "updated", "detail", "email"
  - [x] Build list of requested additional columns
  - [x] "show more" / "details" → add all available columns
  - **[Agent: general-purpose]**

- [x] **Fetch additional data**
  - [x] For "source": track whether task from Jira or GitLab
  - [x] For "last updated": extract updated timestamp from API
  - [x] For "MR status": extract draft/ready/merged for GitLab MRs
  - [x] For "assignee email": include full email address
  - **[Agent: general-purpose]**

- [x] **Render additional columns**
  - [x] Add requested columns after default columns
  - [x] Format timestamps as "YYYY-MM-DD HH:MM"
  - [x] Adjust table width for additional columns
  - **[Agent: general-purpose]**

- [ ] **Test Slice 7**
  - [ ] Run `/team-status --team=team-alpha "show source"`
  - [ ] Verify Source column added (Jira/GitLab)
  - [ ] Run `/team-status --team=team-alpha "show last updated"`
  - [ ] Verify Last Updated column added with timestamps
  - [ ] Run `/team-status --team=team-alpha "show more details"`
  - [ ] Verify all available columns displayed
  - [ ] Verify table formatting still readable with extra columns
  - **[Agent: general-purpose]**

---

## Slice 8: Add Empty States and Error Handling

Handle edge cases and display helpful error messages.

- [x] **Implement empty state messages**
  - [x] Team has zero tasks → "No active tasks found for [team]. All clear!"
  - [x] Filtered query returns nothing → "No tasks match your query: '[query]'. Try a different search."
  - [x] Specific member has no tasks → "[Member] has no active tasks."
  - **[Agent: general-purpose]**

- [x] **Enhance MCP error messages**
  - [x] Jira MCP unavailable → "Jira MCP not configured. Team status requires Jira integration. See docs/setup-jira-mcp.md"
  - [x] GitLab MCP unavailable → "GitLab MCP not configured. Showing Jira data only. See docs/setup-gitlab-mcp.md"
  - [x] API rate limit (429) → "API rate limit reached. Please wait and retry."
  - [x] API errors (401, 403, 500) → Clear, helpful error messages with troubleshooting hints
  - **[Agent: general-purpose]**

- [x] **Handle external assignees**
  - [x] If task assigned to email not in members.json, still display it
  - [x] Use assignee name from Jira/GitLab API response
  - [x] No error thrown
  - **[Agent: general-purpose]**

- [ ] **Test Slice 8**
  - [ ] Create team with no tasks → run `/team-status --team=empty-team`
  - [ ] Verify empty state message shown
  - [ ] Run `/team-status --team=team-alpha "nonexistent"` (query with no results)
  - [ ] Verify "No tasks match your query" message
  - [ ] Disable Jira MCP → run `/team-status --team=team-alpha`
  - [ ] Verify error message with link to setup docs
  - [ ] Create Jira task assigned to external email (not in members.json)
  - [ ] Run `/team-status --team=team-alpha`
  - [ ] Verify external task displayed with API-provided name
  - **[Agent: general-purpose]**

---

## Summary

- **Total Slices:** 8
- **Testable:** Each slice includes verification steps
- **Incremental:** Each slice builds on the previous, keeping the system runnable
- **MCP Dependencies:** Jira MCP required, GitLab and Slack MCPs optional

**Required MCPs for Full Testing:**
- Jira MCP (required) - See `docs/setup-jira-mcp.md`
- GitLab MCP (optional, for Slices 3+) - See `docs/setup-gitlab-mcp.md`
- Slack MCP (optional, for Slice 6) - See `docs/setup-slack-mcp.md`

---
