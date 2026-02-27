# Technical Specification: Real-time Status Dashboard

- **Functional Specification:** `functional-spec.md`
- **Status:** Draft
- **Author:** Claude
- **Date:** 2026-02-27

---

## 1. High-Level Technical Approach

The `/team-status` command will be implemented as a Claude Code Skill that orchestrates MCP calls to Jira and GitLab, then renders results as a formatted table in the CLI. The implementation follows the established architecture pattern:

**Core Components:**
- **Claude Code Skill** (`.claude/skills/team-status/SKILL.md`) - Handles all logic, MCP orchestration, and output formatting
- **Bash Utilities** (reuse existing `file-ops.sh`, `json-utils.sh`) - Read team data from `.team/` directory
- **MCP Integration** - Direct MCP calls from Claude (no bash wrapper)
- **Table Rendering** - Bash `column` or `printf` for CLI table formatting

**Data Flow:**
```
User Command → Skill Entry Point → Team Selection (if needed) → Parse NL Query →
Fetch from Jira MCP → Fetch from GitLab MCP → Enrich with Slack MCP →
Filter & Sort → Render Table → Display to User
```

**Key Architectural Decisions:**
- All logic resides in the skill; bash utilities only read JSON files
- MCP calls are orchestrated by Claude, not bash scripts
- No local caching—all data fetched on-demand from external systems
- Natural language parsing handled by Claude's native understanding
- Table output uses standard bash commands for portability

---

## 2. Proposed Solution & Implementation Plan

### 2.1 Skill Structure

**File Location:** `.claude/skills/team-status/SKILL.md`

**YAML Frontmatter:**
```yaml
---
name: team-status
description: Display real-time team task status from Jira and GitLab
user-invocable: true
---
```

**Skill Sections:**
1. Usage documentation with parameter examples
2. Step-by-step instructions for execution
3. Natural language query patterns
4. MCP integration details
5. Error handling guidelines
6. Example scenarios

### 2.2 Team Selection Logic

**When `--team` parameter is missing:**

1. **List Available Teams:**
   ```bash
   bash -c 'source ./scripts/utils/file-ops.sh && list_teams'
   ```
   Returns: JSON array of team IDs (e.g., `["team-alpha", "team-beta"]`)

2. **Read Team Names:**
   For each team ID:
   ```bash
   jq -r '.team_name' .team/<team-id>/team-config.json
   ```

3. **Prompt User with AskUserQuestion:**
   - Question: "Which team would you like to view status for?"
   - Header: "Team"
   - Options: Each team with `label: team_name` and `description: team_id`
   - multiSelect: false

### 2.3 Natural Language Query Parsing

**Query Patterns Recognized:**

| User Query | Filter Applied |
|------------|----------------|
| "blocked" / "blockers" | status = Blocked (Jira) or blocking labels (GitLab) |
| "in progress" | status = In Progress or equivalent |
| "sarah" / "sarah's work" | assignee matches member "Sarah" |
| "auth feature" / "auth" | title/description contains "auth" (case-insensitive) |
| "merge requests" / "MRs" | show only GitLab MRs |
| "jira only" | exclude GitLab results |
| Combined: "sarah's blocked tasks" | assignee=Sarah AND status=Blocked |

**Implementation:**
- Claude interprets the query string using natural language understanding
- Extracts filter criteria: `member_filter`, `status_filter`, `keyword_filter`, `source_filter`
- Applies filters when processing MCP results
- If query is ambiguous, defaults to showing all active tasks with helper message

### 2.4 Member Data Loading

**Read Team Members:**
```bash
jq -r '.[]' .team/<team-id>/members.json
```

**Extract Member Emails for Jira Queries:**
```bash
jq -r '.[].email' .team/<team-id>/members.json
```

**Extract Git Emails for GitLab Queries:**
```bash
jq -r '.[].git_email // empty' .team/<team-id>/members.json
```

**Build Member Lookup Map:**
- Key: email address
- Value: member object (name, role, slack_user_id, etc.)
- Used to enrich assignee data in table output

### 2.5 Project Data Loading

**Read Team Projects:**
```bash
jq -r '.[]' .team/<team-id>/projects.json
```

**Extract Jira Project Keys:**
```bash
jq -r '.[] | select(.jira_board_id != null) | .jira_board_id' .team/<team-id>/projects.json
```

**Extract GitLab Project IDs:**
```bash
jq -r '.[] | select(.gitlab_project_id != null) | .gitlab_project_id' .team/<team-id>/projects.json
```

### 2.6 Jira MCP Integration

**MCP Availability Check:**
- Attempt to list available MCP tools
- Check for Jira-related tools (e.g., `jira_search_issues`, `jira_get_issue`)
- If unavailable, display error and exit (Jira is required)

**Query Strategy (Batched for Performance):**

1. **Build JQL Query:**
   ```
   assignee in (email1@example.com, email2@example.com, ...)
   AND status not in (Done, Closed, Resolved)
   OR project in (PROJ1, PROJ2, ...)
   AND status not in (Done, Closed, Resolved)
   ```

2. **Execute MCP Call:**
   Use Jira MCP `search_issues` tool with constructed JQL

3. **Parse Response:**
   Extract for each issue:
   - `key` (e.g., "PROJ-123")
   - `fields.summary` (title)
   - `fields.status.name` (status)
   - `fields.assignee.emailAddress` (assignee email)
   - `fields.assignee.displayName` (assignee name)
   - `fields.updated` (last updated timestamp)
   - `fields.customfield_*` (for GitLab MR link extraction)

4. **Extract GitLab MR Links (if no GitLab repos linked):**
   - Check common custom fields: "Git Integration", "Development", fields containing "gitlab"
   - Parse issue comments for GitLab URLs
   - Parse issue links for GitLab merge request references

**Error Handling:**
- MCP unavailable: Show setup instructions, exit
- API rate limit: Display clear message with retry suggestion
- Invalid JQL: Log error, show simplified query results
- Timeout: Show partial results if available, warn about incomplete data

### 2.7 GitLab MCP Integration

**MCP Availability Check:**
- Check for GitLab-related MCP tools
- If unavailable, show warning and continue with Jira-only data

**Query Strategy:**

1. **Query by Project IDs (if linked in projects.json):**
   For each GitLab project ID:
   - Call GitLab MCP `get_project_issues` and `get_project_merge_requests`
   - Filter: state = opened

2. **Query by Assignee (all projects):**
   - Call GitLab MCP `search_issues` with assignee filter
   - Use git_email values from members.json

3. **Merge Results:**
   - Combine issues and MRs
   - Deduplicate by issue/MR IID
   - Filter out merged/closed items

4. **Parse Response:**
   Extract for each issue/MR:
   - `iid` (e.g., "!456" for MRs, "#123" for issues)
   - `title`
   - `state` (opened, closed, merged)
   - `assignee.email` or `assignees[].email`
   - `assignee.name` or `assignees[].name`
   - `updated_at`
   - For MRs: `draft`, `work_in_progress`

**Error Handling:**
- MCP unavailable: Warn user, continue without GitLab data
- API errors: Log error, show Jira-only results
- Rate limiting: Display message, suggest retry

### 2.8 Slack MCP Integration (Member Name Enrichment)

**MCP Availability Check:**
- Check for Slack MCP tools
- If unavailable, gracefully fall back to names from members.json (no error shown)

**Enrichment Strategy:**

1. **For each member with `slack_user_id` in members.json:**
   - Call Slack MCP `users.info` with user ID
   - Extract `profile.display_name` or `profile.real_name`

2. **Build Name Map:**
   - Key: email address
   - Value: enriched display name (Slack) or fallback name (members.json)

3. **Use in Table Rendering:**
   - Display Slack name if available
   - Fall back to members.json name if Slack MCP unavailable or user not found

**Error Handling:**
- MCP unavailable: Silent fallback to local names
- User not found: Use members.json name
- API errors: Log warning, use local names

### 2.9 Data Processing & Filtering

**Combine Jira and GitLab Results:**
```
combined_tasks = jira_issues + gitlab_issues + gitlab_mrs
```

**Apply Filters (based on NL query):**
- **Member Filter:** Filter where assignee email matches member in members.json
- **Status Filter:** Filter by status value (e.g., "Blocked", "In Progress")
- **Keyword Filter:** Case-insensitive search in title/description
- **Source Filter:** Show only Jira or only GitLab if requested

**Sort Results:**
- Primary: Member name (alphabetical)
- Secondary: Status (Blocked first, then In Progress, then others)
- Tertiary: Last updated (most recent first)

**Handle External Assignees:**
- If assignee email not in members.json, still include the task
- Use assignee name from Jira/GitLab API response
- Display in table under section "External Contributors" or inline with indicator

**Filter Empty Members:**
- After filtering, if a team member has zero tasks, do not show them in table

### 2.10 Adaptive Column Display

**Default Columns:**
```
Member | Task ID | Title | Status
```

**Additional Columns (on request):**
- **Source:** "Jira" or "GitLab"
- **Last Updated:** ISO 8601 timestamp (formatted as "YYYY-MM-DD HH:MM")
- **MR Status:** For GitLab MRs, show "Draft", "Ready", "Merged"
- **Blocker Reason:** Extract from Jira links or GitLab blocking issues
- **Assignee Email:** Show full email address

**Column Selection Logic:**
- Parse NL query for keywords: "source", "updated", "detail", "email"
- Add requested columns to default set
- If query contains "show more" or "details", add all available columns

### 2.11 Table Rendering

**Rendering Approach:**

1. **Build Table Data Structure:**
   ```bash
   # Header row
   echo "Member|Task ID|Title|Status"
   echo "------|-------|-----|------"

   # Data rows (one per task)
   for each task:
     echo "$member_name|$task_id|$title|$status"
   ```

2. **Format with `column` Command:**
   ```bash
   table_data | column -t -s '|'
   ```

3. **Alternative (Manual Formatting with printf):**
   ```bash
   printf "%-20s | %-12s | %-40s | %-15s\n" "Member" "Task ID" "Title" "Status"
   printf "%-20s-+-%-12s-+-%-40s-+-%-15s\n" "..." "..." "..." "..."
   for each task:
     printf "%-20s | %-12s | %-40s | %-15s\n" "$member" "$id" "$title" "$status"
   ```

**Column Widths (suggested):**
- Member: 20 chars (truncate longer names with "...")
- Task ID: 12 chars
- Title: 40 chars (truncate with "...")
- Status: 15 chars
- Additional columns: 15-20 chars each

**Grouping by Member:**
- Sort by member name
- Optionally add blank line between different members for readability

### 2.12 Error Messages & Empty States

**MCP Configuration Errors:**
```
Jira MCP not configured. Team status requires Jira integration.
See docs/setup-jira-mcp.md for setup instructions.
```

```
GitLab MCP not configured. Showing Jira data only.
To include GitLab issues and MRs, see docs/setup-gitlab-mcp.md
```

**Empty States:**
```
No active tasks found for team-alpha. All clear!
```

```
No tasks match your query: 'blocked tasks'. Try a different search.
```

```
Sarah Johnson has no active tasks.
```

**Query Parsing Fallback:**
```
Showing default view. Try queries like 'blocked tasks', 'sarah's work', or 'auth feature'.
```

### 2.13 File Structure

**New Files:**
- `.claude/skills/team-status/SKILL.md` - Main skill implementation

**Modified Files:**
- None (reuses existing utilities)

**Dependencies:**
- `./scripts/utils/file-ops.sh` - Team listing and validation
- `./scripts/utils/json-utils.sh` - JSON file reading
- Jira MCP - Required for task data
- GitLab MCP - Optional for GitLab issues/MRs
- Slack MCP - Optional for name enrichment

---

## 3. Impact and Risk Analysis

### 3.1 System Dependencies

**Required Dependencies:**
- Claude Code with MCP support
- Jira MCP configured and accessible
- Bash 4.0+ (for skill execution)
- `jq` (for JSON parsing)
- `column` command (for table formatting, usually pre-installed)

**Optional Dependencies:**
- GitLab MCP (graceful degradation without it)
- Slack MCP (graceful degradation without it)

**Affected Systems:**
- None - read-only operation, no data modifications
- External systems: Jira API (via MCP), GitLab API (via MCP), Slack API (via MCP)

### 3.2 Potential Risks & Mitigations

**Risk 1: MCP Call Performance**
- **Impact:** Slow response time with many team members (20+ API calls)
- **Mitigation:**
  - Batch Jira queries using JQL: `assignee in (email1, email2, ...)`
  - Query GitLab by project first, then filter by assignee locally
  - Target: <5 seconds for team of 15 members with 40 tasks
- **Monitoring:** Log MCP call latency separately for performance analysis

**Risk 2: API Rate Limiting**
- **Impact:** Commands fail or return partial results
- **Mitigation:**
  - Batch queries to minimize API calls (as above)
  - Display clear error messages with retry instructions
  - Show partial results rather than complete failure
  - Document rate limits in setup guides
- **Example Error:** "Jira API rate limit reached (429). Please wait 60 seconds and retry."

**Risk 3: Natural Language Query Ambiguity**
- **Impact:** User query misinterpreted, wrong results shown
- **Mitigation:**
  - Default to showing all active tasks if query unclear
  - Display helper message with example queries
  - Log interpreted filters for debugging
- **Example Fallback:** "Showing default view. Try queries like 'blocked tasks' or 'sarah's work'."

**Risk 4: Large Result Sets**
- **Impact:** Table becomes unreadable with 100+ tasks
- **Mitigation:**
  - Group tasks by member for easier scanning
  - Show summary at top: "Showing 47 active tasks (5 blocked, 42 in progress)"
  - Consider pagination in future (not in scope for v1)
  - Encourage specific queries for large teams

**Risk 5: GitLab MR Link Extraction from Jira**
- **Impact:** MR links not found in Jira tickets, missing GitLab context
- **Mitigation:**
  - Try multiple extraction strategies: custom fields, comments, issue links
  - Gracefully skip if extraction fails (show Jira-only data)
  - Document preference for linking GitLab repos in `projects.json`
  - Provide clear setup guide for Jira-GitLab integration

**Risk 6: External Assignee Display**
- **Impact:** Tasks assigned to non-team members might confuse output
- **Mitigation:**
  - Clearly display external assignees (use actual name from API)
  - Consider visual indicator or separate section
  - Document this behavior in skill description

**Risk 7: Stale Member Data**
- **Impact:** members.json out of sync with Jira/GitLab (members removed from external systems)
- **Mitigation:**
  - Query Jira/GitLab by both member list AND project list
  - Show external assignees even if not in members.json
  - Recommend periodic review of members.json

**Risk 8: MCP Timeout**
- **Impact:** Long-running queries (large teams, slow APIs) exceed timeout
- **Mitigation:**
  - Set reasonable MCP timeout (30 seconds suggested)
  - Show partial results if some queries succeed
  - Display clear timeout message with suggestion to query specific members

---

## 4. Testing Strategy

### 4.1 Unit Testing (Skill Logic)

**Test Team Selection:**
- No teams exist (empty `.team/` directory) → error message
- Single team exists → auto-select without prompt
- Multiple teams exist → prompt with AskUserQuestion

**Test Natural Language Parsing:**
- "blocked tasks" → status filter applied
- "sarah's work" → member filter applied
- "auth feature" → keyword filter applied
- "sarah's blocked tasks" → combined filters applied
- Ambiguous query → default view with helper message

**Test Member/Project Data Loading:**
- Valid members.json → parse successfully
- Missing members.json → graceful error
- Invalid JSON → graceful error with helpful message
- Empty members array → empty state message

**Test Table Formatting:**
- 0 tasks → empty state message
- 1 task → single-row table
- 50 tasks → properly formatted multi-page table
- Very long titles/names → truncation with "..."
- Special characters in task titles → proper escaping

### 4.2 Integration Testing (MCP)

**Test Jira MCP Integration:**
- Query by assignee email list → returns correct tasks
- Query by project keys → returns correct tasks
- Combined query (assignee + project) → deduplicates correctly
- Jira MCP unavailable → error message displayed
- Jira API error → helpful error message

**Test GitLab MCP Integration:**
- Query by project ID → returns issues and MRs
- Query by assignee (git_email) → returns correct items
- GitLab MCP unavailable → warning shown, Jira-only results displayed
- No GitLab repos in projects.json → MR extraction from Jira attempted

**Test Slack MCP Integration:**
- Slack MCP available → member names enriched
- Slack MCP unavailable → fallback to members.json names (no error)
- Member not found in Slack → fallback to local name

**Test Combined Results:**
- Jira + GitLab results → merged and deduplicated
- Same task in both systems → no duplicates shown
- Sorting by member then status → correct order

### 4.3 End-to-End Testing Scenarios

**Scenario 1: Default View**
```
Command: /team-status
Expected: Prompt to select team → display all active tasks in table
Verify: All members with tasks shown, grouped by member
```

**Scenario 2: Team Parameter**
```
Command: /team-status --team=team-alpha
Expected: Display all active tasks for team-alpha
Verify: Correct team data loaded, Jira + GitLab results combined
```

**Scenario 3: Member Filter**
```
Command: /team-status --team=team-alpha --member=sarah
Expected: Display only Sarah's tasks
Verify: Only tasks assigned to sarah@example.com shown
```

**Scenario 4: Natural Language Query - Blocked Tasks**
```
Command: /team-status --team=team-alpha "blocked tasks"
Expected: Display only tasks with Blocked status
Verify: Jira Blocked and GitLab blocking labels both shown
```

**Scenario 5: Natural Language Query - Keyword Search**
```
Command: /team-status --team=team-alpha "auth feature"
Expected: Display tasks with "auth" in title/description
Verify: Case-insensitive search, both Jira and GitLab results
```

**Scenario 6: Adaptive Detail**
```
Command: /team-status --team=team-alpha "show source and last updated"
Expected: Table includes Source and Last Updated columns
Verify: Additional columns shown, proper formatting maintained
```

**Scenario 7: External Assignees**
```
Setup: Create Jira task assigned to email not in members.json
Command: /team-status --team=team-alpha
Expected: External task shown with assignee name from Jira
Verify: External task displayed, no error thrown
```

**Scenario 8: Empty States**
```
Command: /team-status --team=empty-team (team with no tasks)
Expected: "No active tasks found for empty-team. All clear!"
Verify: Graceful empty state message
```

**Scenario 9: MCP Unavailable**
```
Setup: Disable Jira MCP
Command: /team-status --team=team-alpha
Expected: Error message with setup instructions
Verify: Clear error, link to docs/setup-jira-mcp.md
```

**Scenario 10: GitLab Optional**
```
Setup: Jira MCP available, GitLab MCP unavailable
Command: /team-status --team=team-alpha
Expected: Warning shown, Jira-only results displayed
Verify: Warning message, no crash, Jira data shown correctly
```

### 4.4 Performance Testing

**Target Performance:**
- Team with 15 members, 40 tasks → <5 seconds total
- MCP call latency: <2 seconds per API call
- Table rendering: <500ms regardless of size

**Test Cases:**
- Small team (3 members, 5 tasks)
- Medium team (10 members, 30 tasks)
- Large team (20 members, 80 tasks)

**Metrics to Track:**
- Total execution time (user command → table displayed)
- MCP call count (minimize via batching)
- MCP call latency (per call)
- Data processing time (filtering, sorting)
- Table rendering time

**Performance Optimization Checkpoints:**
- Verify JQL batching reduces Jira calls to 1-2 max
- Verify GitLab project queries batched by project
- Verify no redundant MCP calls (caching within single execution)

### 4.5 Error Handling Testing

**Test MCP Errors:**
- 401 Unauthorized → "Authentication failed. Check MCP credentials."
- 403 Forbidden → "Insufficient permissions. Check MCP configuration."
- 404 Not Found → "Project/board not found. Check projects.json configuration."
- 429 Rate Limited → "API rate limit reached. Please wait and retry."
- 500 Server Error → "External API error. Please try again later."
- Network timeout → "Request timed out. Check network connection."

**Test Data Errors:**
- Invalid JSON in members.json → "Invalid members.json format. Please check file."
- Missing team directory → "Team 'team-alpha' not found. Run /list-teams to see available teams."
- Empty members.json → "No members found in team. Run /add-team-members to add members."

### 4.6 User Acceptance Testing

**Test with Real Users:**
- Engineering managers test with their actual teams
- Verify query patterns match real usage
- Gather feedback on table readability
- Identify missing query patterns
- Test response time perception (<5s target)

---
