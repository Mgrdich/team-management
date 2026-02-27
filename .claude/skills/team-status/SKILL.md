---
name: team-status
description: Display real-time team task status from Jira and GitLab
user-invocable: true
---

# Team Status Skill

This skill displays real-time visibility into team tasks by fetching data from Jira and GitLab via MCP integration. It shows task status in a CLI table format.

## Usage

```
/team-status
```

No parameters - will prompt for team selection.

```
/team-status --team=team-alpha
```

Display status for a specific team.

```
/team-status --team=team-alpha --member=sarah
```

Filter status to a specific team member.

```
/team-status --team=team-alpha "blocked tasks"
```

Display status with natural language query filtering.

### Parameters

- `--team` (optional): Team ID to view status for. If not provided, will prompt user to select from available teams.
- `--member` (optional): Filter to specific team member by name or member ID.
- Query text (optional): Natural language query for filtering results (e.g., "blocked tasks", "in progress", "high priority").

## Instructions

When this skill is invoked, follow these steps:

### Step 1: Parse and Validate Team Parameter

Extract the `--team` parameter from command arguments (if provided).

**Instructions:**
- Check if `--team` parameter exists in the command arguments
- If provided, extract its value (e.g., `team-alpha`)
- Store in a variable for later use

### Step 2: Team Selection (if --team not provided)

If `--team` parameter is missing, prompt the user to select a team.

**Instructions:**

1. **Get all team IDs:**
   ```bash
   bash -c 'source ./scripts/utils/file-ops.sh && list_teams'
   ```
   This returns a JSON array like `["team-alpha", "team-beta"]`

2. **Parse team IDs:**
   ```bash
   echo '[team-ids-json]' | jq -r '.[]'
   ```
   This outputs one team ID per line.

3. **For each team ID, read team name:**
   ```bash
   jq -r '.team_name' .team/<team-id>/team-config.json
   ```

4. **Use AskUserQuestion to prompt user:**
   ```
   - Question: "Which team would you like to view status for?"
   - Header: "Team"
   - Options: Build array with each team as:
     - label: team_name (e.g., "Team Alpha")
     - description: team_id (e.g., "team-alpha")
   - multiSelect: false
   ```

5. **Store selected team ID** for use in subsequent steps.

**Error Handling:**
- If no teams exist (empty array `[]`), display: "No teams found. Run /team-init to create your first team."
- If team directory doesn't exist or team-config.json is missing, skip that team with a warning

### Step 3: Validate Team Exists

Verify the selected/provided team exists.

**Instructions:**
- Check if `.team/<team-id>/` directory exists
- Check if `.team/<team-id>/team-config.json` exists
- If not found, display error: "Team '<team-id>' not found. Run /list-teams to see available teams."
- Exit if team doesn't exist

### Step 4: Get Team Name

Read the team name for display purposes.

**Instructions:**
```bash
jq -r '.team_name' .team/<team-id>/team-config.json
```

Store the team name for use in output messages.

### Step 4A: Parse Member Filter Parameter (Optional)

Check if the user provided a `--member` parameter to filter results to a specific team member.

**Instructions:**

1. **Check for --member parameter:**
   - Look for `--member` in command arguments
   - If not present, set `member_filter = null` (no filtering)
   - If present, extract the value

2. **Parse member filter value:**
   - The value can be:
     - First name: `sarah`
     - Full name: `Sarah Johnson`
     - Email address: `sarah@example.com`

3. **Search for matching members:**
   - Load `members.json` for the team (using `team_id` from Step 2-3)
     ```bash
     jq -r '.[]' .team/<team-id>/members.json
     ```
   - Search for members matching the filter:
     - Match against `name` field (case-insensitive partial match)
     - Match against `email` field (exact match)
   - Collect all matches

4. **Handle match results:**
   - If 0 matches: Display error and exit
     ```
     No team member found matching '[filter-value]'.
     Available members: [list member names from members.json]
     ```
   - If 1 match: Store the matched member
   - If multiple matches: Will be handled in next step (disambiguation)

**Data Storage:**
Store these values for later use:
- `member_filter` - The original filter value provided
- `matched_members` - Array of matching member objects
- `selected_member` - The member to filter by (if single match)

**Important Notes:**
- This step runs BEFORE any data fetching (Jira/GitLab queries)
- Parameter is optional - if not provided, no filtering occurs
- Matching is flexible (first name, full name, email)
- Multiple matches are OK - will be resolved in next step

### Step 4B: Disambiguate Multiple Member Matches (If Needed)

If multiple members match the filter, prompt the user to select the specific member.

**Instructions:**

1. **Check matched_members count:**
   - If `matched_members` has exactly 1 member: Skip this step (already handled in 4A)
   - If `matched_members` has 0 members: Already handled in 4A (error displayed)
   - If `matched_members` has 2+ members: Continue with disambiguation

2. **Use AskUserQuestion to prompt user:**
   ```
   - Question: "Multiple members match '[member_filter]'. Which one would you like to view?"
   - Header: "Select member"
   - Options: Build array with each matched member as:
     - label: member name (e.g., "Sarah Johnson")
     - description: member role + email (e.g., "Engineer - sarah@example.com")
   - multiSelect: false
   ```

3. **Store selected member:**
   - Get the user's selection from AskUserQuestion
   - Store in `selected_member` variable
   - This will be used later for filtering results

**Example:**
If user provided `--member=sarah` and two Sarahs exist:
```
Multiple members match 'sarah'. Which one would you like to view?

Options:
- Sarah Johnson (Engineer - sarah.johnson@example.com)
- Sarah Williams (Designer - sarah.williams@example.com)
```

**Data Storage:**
Update `selected_member` with the user's choice.

**Important Notes:**
- This only runs if Step 4A found multiple matches
- Uses AskUserQuestion (not plain text prompts)
- Helps user by showing role and email for context
- The actual filtering happens later (after data is fetched)

### Step 5: Check MCP Availability

Verify that MCP integrations are available before proceeding.

**Instructions:**

1. **Check for Jira MCP tools:**
   - Attempt to detect Jira MCP by checking if Jira-related tools are available
   - Look for tools like `jira_search_issues` or similar Jira MCP functions

2. **Check for GitLab MCP tools:**
   - Attempt to detect GitLab MCP by checking if GitLab-related tools are available
   - Look for tools like `gitlab_get_project_issues` or similar GitLab MCP functions

3. **Handle MCP availability:**

   **If both MCP integrations are unavailable:**
   - Display error message:
     ```
     Error: MCP integrations not configured.

     To use this feature, configure MCP integrations.
     See documentation: docs/setup-jira-mcp.md or docs/setup-gitlab-mcp.md

     Showing local data only (team members and projects from configuration).
     ```
   - Skip to local data display (show team members and projects only)
   - Do not fetch task data

   **If only Jira MCP is unavailable (GitLab available):**
   - Display error message:
     ```
     Error: Jira MCP not configured.

     To use this feature, configure Jira MCP integration.
     See documentation: docs/setup-jira-mcp.md

     Team status requires Jira integration to display task data.
     ```
   - Exit the command (do not proceed)

   **If Jira MCP is available:**
   - Store Jira availability flag: `jira_mcp_available = true`
   - Store GitLab availability flag: `gitlab_mcp_available = true/false`
   - Proceed to the next step

**Error Handling:**
- Jira MCP is REQUIRED for task status functionality
- GitLab MCP is OPTIONAL and enhances the output
- If neither is available, fall back to showing local team configuration data only
- Provide clear instructions pointing to the setup documentation

### Step 6: Load Team Members and Projects

Load team data needed for querying Jira.

**Instructions:**

1. **Read team members:**
   ```bash
   jq -r '.[]' .team/<team-id>/members.json
   ```
   Store the complete members array for later use.

2. **Extract member email addresses:**
   ```bash
   jq -r '.[].email' .team/<team-id>/members.json
   ```
   Create a list of all member emails. This will be used in the Jira JQL query.

3. **Build member lookup map:**
   - Create a map with email as key and member data (name, role) as value
   - This will be used to enrich Jira assignee data with team member names
   - Example: `{"john@example.com": {"name": "John Doe", "role": "Engineer"}}`

4. **Read team projects:**
   ```bash
   jq -r '.[]' .team/<team-id>/projects.json
   ```

5. **Extract Jira board/project IDs:**
   ```bash
   jq -r '.[] | select(.jira_board_id != null) | .jira_board_id' .team/<team-id>/projects.json
   ```
   Create a list of Jira board IDs or project keys. This will be used in the Jira JQL query.

**Error Handling:**
- If `members.json` doesn't exist or is empty, display: "No members found in team. Run /add-team-members to add members."
- If `projects.json` doesn't exist, it's OK - we can still query by assignee emails
- If JSON parsing fails, display: "Invalid JSON format in team data files. Please check members.json and projects.json."

**Data Storage:**
Store these values in variables for use in the next step (Jira query):
- `member_emails` - Array of email addresses
- `member_map` - Map of email to member data
- `jira_project_ids` - Array of Jira board/project IDs

### Step 7: Query Jira via MCP

Fetch active tasks from Jira using MCP.

**Instructions:**

1. **Build JQL query:**
   - Construct a JQL query that combines:
     - Search by assignee emails (from `member_emails` in Step 6)
     - Search by Jira project keys (from `jira_project_ids` in Step 6)
     - Exclude completed statuses: Done, Closed, Resolved
   - Example JQL:
     ```
     assignee in (john@example.com, sarah@example.com)
     AND status not in (Done, Closed, Resolved)
     OR project in (PROJ, AUTH)
     AND status not in (Done, Closed, Resolved)
     ```
   - JQL construction logic:
     - If both `member_emails` and `jira_project_ids` exist, use OR to combine them:
       ```
       (assignee in (emails) AND status not in (Done, Closed, Resolved))
       OR (project in (projects) AND status not in (Done, Closed, Resolved))
       ```
     - If only `member_emails` exist (no projects.json or no jira_board_id):
       ```
       assignee in (emails) AND status not in (Done, Closed, Resolved)
       ```
     - If only `jira_project_ids` exist (no member emails):
       ```
       project in (projects) AND status not in (Done, Closed, Resolved)
       ```

2. **Execute Jira MCP search_issues:**
   - Use the Jira MCP `search_issues` tool (or equivalent tool name if different)
   - Pass the constructed JQL query
   - Request all relevant fields: key, summary, status, assignee, updated
   - Handle API errors gracefully

3. **Parse Jira response:**
   For each issue in the response, extract:
   - `key` - Issue key (e.g., "PROJ-123")
   - `fields.summary` - Issue title
   - `fields.status.name` - Current status
   - `fields.assignee.emailAddress` - Assignee email (may be null for unassigned)
   - `fields.assignee.displayName` - Assignee name from Jira (may be null)
   - `fields.updated` - Last updated timestamp

4. **Enrich with team member data:**
   - Use the `member_map` from Step 6 to match assignee emails
   - If assignee email exists in `member_map`, use the team member's name from the map
   - If assignee email not in `member_map` but Jira has displayName, use Jira's displayName (external contributor)
   - If no assignee (null), set assignee to "Unassigned"

5. **Build task list:**
   - Create a data structure containing all tasks with:
     - Member name (enriched from `member_map` or Jira, or "Unassigned")
     - Task ID (Jira key)
     - Title (summary)
     - Status
     - Last Updated (formatted from timestamp)
     - Source: "Jira"
   - Store as an array/list for table rendering in the next step

**Error Handling:**
- API rate limit (429): Display "Jira API rate limit reached. Please wait and retry."
- Authentication error (401): Display "Jira authentication failed. Check MCP credentials."
- Invalid JQL: Display "JQL query error. Check team configuration."
- Network timeout: Display "Jira request timed out. Check network connection."
- No results: Continue to next step (empty task list is valid - display "No active tasks found for team")
- Malformed response: Display "Error parsing Jira response. Please try again."

**Data Storage:**
Store the task list in a variable for the next step (table rendering):
- `jira_tasks` - Array of task objects with structure:
  ```json
  [
    {
      "assignee": "John Doe",
      "task_id": "PROJ-123",
      "title": "Implement login feature",
      "status": "In Progress",
      "last_updated": "2026-02-26 14:30",
      "source": "Jira"
    }
  ]
  ```

### Step 8: Render Task Table

Display the fetched tasks in a formatted CLI table.

**Instructions:**

1. **Sort tasks:**
   - Primary sort: Member name (alphabetical order)
   - Secondary sort: Status (prioritize Blocked, then In Progress, then others)

2. **Build table structure:**
   - Header row: `Member | Task ID | Title | Status`
   - Separator row: `------|-------|-----|------`
   - Data rows: One row per task from `jira_tasks` (from Step 7)

3. **Format table using `column` command:**
   ```bash
   # Build table data
   echo "Member|Task ID|Title|Status"
   echo "------|-------|-----|------"

   # For each task in jira_tasks:
   for task in jira_tasks:
     echo "$task.assignee|$task.task_id|$task.title|$task.status"

   # Pipe to column for formatting
   column -t -s '|'
   ```

4. **Handle long values:**
   - If member name > 20 chars: truncate with "..."
   - If title > 40 chars: truncate with "..."
   - Task ID and Status: display as-is

5. **Handle empty results:**
   - If `jira_tasks` is empty (no tasks found), display:
     ```
     No active tasks found for [team-name]. All clear!
     ```

**Alternative Implementation (printf):**

If `column` command is unavailable, use `printf` for manual formatting:
```bash
printf "%-20s | %-12s | %-40s | %-15s\n" "Member" "Task ID" "Title" "Status"
printf "%-20s-+-%-12s-+-%-40s-+-%-15s\n" "----" "-------" "-----" "------"

for task in jira_tasks:
  member=$(truncate "$task.assignee" 20)
  title=$(truncate "$task.title" 40)
  printf "%-20s | %-12s | %-40s | %-15s\n" \
    "$member" "$task.task_id" "$title" "$task.status"
```

**Display Notes:**
- Use the enriched member names from Step 7 (team member names or Jira displayName)
- Show Jira issue keys as-is (e.g., "PROJ-123")
- Truncate long values to maintain table readability

**Column Widths:**
- Member: 20 characters (truncate with "...")
- Task ID: 12 characters
- Title: 40 characters (truncate with "...")
- Status: 15 characters

### Step 9: Query GitLab via MCP (Optional)

Fetch GitLab issues and merge requests if GitLab MCP is available.

**Instructions:**

1. **Check GitLab availability:**
   - If `gitlab_mcp_available = false` (from Step 5), skip this step entirely
   - Set `gitlab_tasks = []` (empty array)
   - Proceed to next step (merge task lists)
   - If `gitlab_mcp_available = true`, proceed with GitLab queries

2. **Extract GitLab project IDs:**
   - From `projects.json` (loaded in Step 6)
   - Filter for projects with `gitlab_project_id` field:
     ```bash
     jq -r '.[] | select(.gitlab_project_id != null) | .gitlab_project_id' .team/<team-id>/projects.json
     ```
   - Create list of GitLab project IDs
   - Extract `git_email` addresses from `members.json` (loaded in Step 6):
     ```bash
     jq -r '.[] | select(.git_email != null) | .git_email' .team/<team-id>/members.json
     ```
   - Create list of git emails for assignee queries

3. **Query GitLab issues:**
   - For each GitLab project ID: Call GitLab MCP `get_project_issues`
     - Filter: `state = opened`
     - Request fields: `iid`, `title`, `state`, `assignee`, `assignees`, `updated_at`
   - For each git_email: Query issues assigned to that email
     - Use GitLab MCP search/query functions for assignee filtering
     - Filter: `state = opened`
   - Combine results from both queries
   - Deduplicate by issue `iid` (remove duplicates if same issue appears multiple times)

4. **Query GitLab merge requests:**
   - For each GitLab project ID: Call GitLab MCP `get_project_merge_requests`
     - Filter: `state = opened` (not merged or closed)
     - Request fields: `iid`, `title`, `state`, `draft`, `work_in_progress`, `assignee`, `assignees`, `updated_at`
   - For each git_email: Query MRs assigned to that email
     - Use GitLab MCP search/query functions for assignee filtering
     - Filter: `state = opened`
   - Include draft and work-in-progress MRs
   - Combine results from both queries
   - Deduplicate by MR `iid`

5. **Parse GitLab responses:**

   For each issue, extract:
   - `iid` - Issue ID (prefix with "#", e.g., "#123")
   - `title` - Issue title
   - `state` - Current state
   - `assignee.email` or `assignees[0].email` - Assignee email (may be null)
   - `assignee.name` or `assignees[0].name` - Assignee name from GitLab (may be null)
   - `updated_at` - Last updated timestamp

   For each merge request, extract:
   - `iid` - MR ID (prefix with "!", e.g., "!456")
   - `title` - MR title
   - `state` - Current state
   - `draft` - Boolean flag (true/false)
   - `work_in_progress` - Boolean flag (true/false)
   - `assignee.email` or `assignees[0].email` - Assignee email (may be null)
   - `assignee.name` or `assignees[0].name` - Assignee name from GitLab (may be null)
   - `updated_at` - Last updated timestamp

6. **Enrich with team member data:**
   - Use `member_map` from Step 6 to match assignee emails
   - For issues/MRs with assignee email:
     - If email exists in `member_map`, use team member's name from the map
     - If email not in `member_map` but GitLab has assignee name, use GitLab's name (external contributor)
   - For issues/MRs without assignee (null), set assignee to "Unassigned"

7. **Build GitLab task list:**
   - Create array containing all issues and MRs with:
     - Member name (enriched from `member_map` or GitLab, or "Unassigned")
     - Task ID (with "#" prefix for issues, "!" prefix for MRs)
     - Title
     - Status:
       - For draft MRs: "Draft"
       - For work-in-progress MRs: "WIP"
       - Otherwise: state value
     - Last Updated (formatted from timestamp)
     - Source: "GitLab"
   - Store as an array/list for merging with Jira tasks

**Error Handling:**
- API rate limit (429): Display warning "GitLab API rate limit reached. Showing partial results.", continue with partial data
- Authentication error (401): Display warning "GitLab authentication failed. Check MCP credentials.", skip GitLab data
- Network timeout: Display warning "GitLab request timed out. Showing Jira data only.", continue with Jira-only
- No results: Continue (empty GitLab list is valid)
- No GitLab project IDs in projects.json: Continue with assignee-only queries (if git_emails exist)
- No git_emails in members.json: Continue with project-only queries (if gitlab_project_ids exist)
- Malformed response: Display warning "Error parsing GitLab response.", skip GitLab data

**Data Storage:**
Store the GitLab task list in a variable:
- `gitlab_tasks` - Array of task objects with structure:
  ```json
  [
    {
      "assignee": "Sarah Johnson",
      "task_id": "#123",
      "title": "Fix login bug",
      "status": "opened",
      "last_updated": "2026-02-26 10:15",
      "source": "GitLab"
    },
    {
      "assignee": "John Doe",
      "task_id": "!456",
      "title": "Add authentication feature",
      "status": "Draft",
      "last_updated": "2026-02-26 09:30",
      "source": "GitLab"
    }
  ]
  ```

**Important Notes:**
- Only run if `gitlab_mcp_available = true`
- Prefix issue IDs with "#" and MR IDs with "!"
- Handle cases where projects.json has no GitLab project IDs (assignee-only search is valid)
- Handle cases where members.json has no git_email fields (project-only search is valid)
- Store results separately from Jira tasks (will be merged in next step)
- Graceful error handling - don't block the command if GitLab fails
- GitLab data enhances the output but is not required for the command to succeed

## Implementation Notes

### Working Directory

All commands should be run from the repository root. Team data is stored in `.team/<team-id>/` directory.

### Data Sources

- **Jira MCP** (required): Primary source for task status data
- **GitLab MCP** (optional): Additional context for merge requests and pipeline status
- **Slack MCP** (optional): Team communication and activity insights

### Output Format

Results will be displayed in a CLI table format using bash `column` or `printf` commands for clean, readable output.

## Success Criteria

The skill is successful when:
1. Team parameter is validated (exists in repository)
2. Data is fetched from available MCP sources (Jira required, GitLab/Slack optional)
3. Results are filtered based on member or query parameters if provided
4. Output is formatted as a clean table with relevant columns
5. Errors are handled gracefully (MCP unavailable, team not found, etc.)

## Related Skills

- `/list-teams` - View all teams
- `/team-init` - Create a new team
- `/add-team-members` - Add members to a team
