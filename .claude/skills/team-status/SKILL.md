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

### Step 4C: Parse Natural Language Query (Optional)

Extract and parse natural language query for filtering results.

**Instructions:**

1. **Extract query string:**
   - Look for text in command arguments after `--team` and `--member` parameters
   - This is typically quoted text: `"blocked tasks"`, `"sarah's work"`, etc.
   - If no query string, set `query = null` (no query-based filtering)

2. **Parse query patterns:**
   Analyze the query string to identify filters:

   **Status Filters:**
   - If query contains "blocked" or "blockers": set `status_filter = "Blocked"`
   - If query contains "in progress": set `status_filter = "In Progress"`

   **Member Filters:**
   - If query contains a member's first name or full name: set `query_member_filter = member`
   - Search members.json for name matches (case-insensitive)
   - Note: This is additional to `--member` parameter from Step 4A

   **Keyword Filters:**
   - Extract keywords that aren't status/member references
   - Examples: "auth", "payment", "feature"
   - Set `keyword_filter = extracted keyword`
   - Will be used to search task titles and descriptions

   **Source Filters:**
   - If query contains "jira only": set `source_filter = "Jira"`
   - If query contains "gitlab only": set `source_filter = "GitLab"`
   - If query contains "merge requests" or "MRs": set `source_filter = "GitLab_MRs"`

   **Column Requests:**
   - Detect keywords requesting additional columns (case-insensitive):
     - "source" → add "source" to `additional_columns[]`
     - "updated" or "last updated" → add "updated" to `additional_columns[]`
     - "detail" or "details" → add "description" to `additional_columns[]`
     - "email" → add "email" to `additional_columns[]`
     - "show more" or "all columns" → add all available columns: `["source", "updated", "description", "email"]`
   - Initialize `additional_columns = []` as empty array
   - Add each detected column keyword to the array (avoid duplicates)
   - Note: Column rendering happens in Step 11; this step only parses the request

3. **Combine with existing filters:**
   - If both `--member` parameter (Step 4A) and query member filter exist, use `--member` parameter (more specific)
   - Query filters are additive (can combine status + keyword)

4. **Track query parsing success:**
   - Set `query_parsed = true` if any filters were extracted from the query
   - Set `query_parsed = false` if query string exists but no recognizable patterns were found
   - Set `original_query` to the raw query string for display in fallback message

5. **Handle unparseable queries:**
   - If query cannot be parsed (no filters extracted), set `query_parsed = false`
   - The query fallback logic (before Step 11) will handle displaying the helper message
   - Continue execution with no query filters (show default view)

**Data Storage:**
Store these filter variables for use in later steps:
- `status_filter` - Status to filter by (or null)
- `query_member_filter` - Member name from query (or null)
- `keyword_filter` - Keyword to search (or null)
- `source_filter` - Source to filter by (or null)
- `query_parsed` - Boolean flag: true if filters extracted, false if query provided but not parsed
- `original_query` - Original query string (for fallback message display)
- `additional_columns` - Array of requested column names (e.g., ["source", "updated", "email"])

**Important Notes:**
- Query parsing happens early (before data fetching)
- The actual filtering happens later (after data is fetched)
- Queries are flexible and can combine multiple filters
- Example: "sarah's blocked tasks" → member filter + status filter

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
     Error: Jira MCP not configured. Team status requires Jira integration.

     See docs/setup-jira-mcp.md for configuration instructions.
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
   - Request all relevant fields: key, summary, status, assignee, updated, description
   - Handle API errors gracefully

3. **Parse Jira response:**
   For each issue in the response, extract:
   - `key` - Issue key (e.g., "PROJ-123")
   - `fields.summary` - Issue title
   - `fields.status.name` - Current status
   - `fields.assignee.emailAddress` - Assignee email (may be null for unassigned)
   - `fields.assignee.displayName` - Assignee name from Jira (may be null)
   - `fields.updated` - Last updated timestamp (store as `last_updated`)
   - `fields.description` - Task description (store as `description`)

4. **Enrich with team member data:**
   - Use the `member_map` from Step 6 to match assignee emails
   - If assignee email exists in `member_map`, use the team member's name from the map
   - If assignee email not in `member_map` but Jira has displayName, use Jira's displayName (external contributor)
   - If no assignee (null), set assignee to "Unassigned"

   **External Assignee Handling:**
   - Tasks assigned to emails NOT in members.json are VALID and should be displayed
   - Use the assignee's displayName from Jira API response for external users
   - DO NOT filter out or skip tasks with external assignees
   - DO NOT throw errors when assignee email is not found in member_map
   - External assignees should appear in the table the same as team members
   - Optional: Mark external assignees by appending " (external)" to their name for clarity

5. **Build task list:**
   - Create a data structure containing all tasks with:
     - `assignee` - Member name (enriched from `member_map` or Jira, or "Unassigned")
     - `assignee_email` - Assignee email address (from Jira API, may be null)
     - `task_id` - Task ID (Jira key)
     - `title` - Title (summary)
     - `status` - Status
     - `last_updated` - Last Updated (formatted from timestamp)
     - `description` - Task description (from Jira API, may be empty)
     - `source` - Source: "jira"
   - Store as an array/list for table rendering in the next step

**Error Handling:**
- **API rate limit (429):**
  - Display: "API rate limit reached. Please wait and retry."
  - Troubleshooting: Rate limits reset periodically. Wait a few minutes before retrying.
- **Authentication error (401):**
  - Display: "Jira authentication failed. Check your Jira MCP credentials."
  - Troubleshooting: Verify API token is valid and has not expired. Re-authenticate in MCP settings.
- **Permission error (403):**
  - Display: "Jira access denied. Your account lacks permission to view these projects."
  - Troubleshooting: Contact your Jira administrator to grant access to the required projects.
- **Server error (500, 502, 503):**
  - Display: "Jira server error. The Jira service may be temporarily unavailable."
  - Troubleshooting: Check Jira status page or try again later. Contact support if the issue persists.
- **Invalid JQL:**
  - Display: "JQL query error. Check team configuration (members.json or projects.json)."
  - Troubleshooting: Verify email addresses and project keys are correctly formatted.
- **Network timeout:**
  - Display: "Jira request timed out. Check network connection."
  - Troubleshooting: Verify internet connectivity and firewall settings.
- **No results:**
  - Continue to next step (empty task list is valid - display "No active tasks found for team")
- **Malformed response:**
  - Display: "Error parsing Jira response. Please try again."
  - Troubleshooting: If the issue persists, check Jira API version compatibility.

**Data Storage:**
Store the task list in a variable for the next step (table rendering):
- `jira_tasks` - Array of task objects with structure:
  ```json
  [
    {
      "assignee": "John Doe",
      "assignee_email": "john@example.com",
      "task_id": "PROJ-123",
      "title": "Implement login feature",
      "status": "In Progress",
      "last_updated": "2026-02-26 14:30",
      "description": "Add OAuth2 authentication flow to login page",
      "source": "jira"
    }
  ]
  ```

### Step 8: Query GitLab via MCP (Optional)

Fetch GitLab issues and merge requests if GitLab MCP is available.

**Note:** This step occurs before merging and filtering. GitLab data will be combined with Jira data in Step 9.

**Instructions:**

1. **Check GitLab availability:**
   - If `gitlab_mcp_available = false` (from Step 5):
     - Display warning message:
       ```
       Warning: GitLab MCP not configured. Showing Jira data only.

       See docs/setup-gitlab-mcp.md for configuration instructions.
       ```
     - Set `gitlab_tasks = []` (empty array)
     - Proceed to next step (Slack MCP check)
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
     - Request fields: `iid`, `title`, `state`, `assignee`, `assignees`, `updated_at`, `description`
   - For each git_email: Query issues assigned to that email
     - Use GitLab MCP search/query functions for assignee filtering
     - Filter: `state = opened`
   - Combine results from both queries
   - Deduplicate by issue `iid` (remove duplicates if same issue appears multiple times)

4. **Query GitLab merge requests:**
   - For each GitLab project ID: Call GitLab MCP `get_project_merge_requests`
     - Filter: `state = opened` (not merged or closed)
     - Request fields: `iid`, `title`, `state`, `draft`, `work_in_progress`, `assignee`, `assignees`, `updated_at`, `description`
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
   - `updated_at` - Last updated timestamp (store as `last_updated`)
   - `description` - Issue description (store as `description`)

   For each merge request, extract:
   - `iid` - MR ID (prefix with "!", e.g., "!456")
   - `title` - MR title
   - `state` - Current state (one of: "opened", "merged", "closed")
   - `draft` - Boolean flag (true/false)
   - `work_in_progress` - Boolean flag (true/false)
   - `assignee.email` or `assignees[0].email` - Assignee email (may be null)
   - `assignee.name` or `assignees[0].name` - Assignee name from GitLab (may be null)
   - `updated_at` - Last updated timestamp (store as `last_updated`)
   - `description` - MR description (store as `description`)
   - Compute `mr_status` based on state and flags:
     - If `draft = true` or `work_in_progress = true`: "Draft"
     - If `state = "merged"`: "Merged"
     - If `state = "opened"` and not draft: "Ready"
     - Otherwise: Use `state` value

6. **Enrich with team member data:**
   - Use `member_map` from Step 6 to match assignee emails
   - For issues/MRs with assignee email:
     - If email exists in `member_map`, use team member's name from the map
     - If email not in `member_map` but GitLab has assignee name, use GitLab's name (external contributor)
   - For issues/MRs without assignee (null), set assignee to "Unassigned"

   **External Assignee Handling:**
   - Tasks assigned to emails NOT in members.json are VALID and should be displayed
   - Use the assignee's name from GitLab API response for external users
   - DO NOT filter out or skip tasks with external assignees
   - DO NOT throw errors when assignee email is not found in member_map
   - External assignees should appear in the table the same as team members
   - Optional: Mark external assignees by appending " (external)" to their name for clarity

7. **Build GitLab task list:**
   - Create array containing all issues and MRs with:
     - `assignee` - Member name (enriched from `member_map` or GitLab, or "Unassigned")
     - `assignee_email` - Assignee email address (from GitLab API, may be null)
     - `task_id` - Task ID (with "#" prefix for issues, "!" prefix for MRs)
     - `title` - Title
     - `status` - Status:
       - For draft MRs: "Draft"
       - For work-in-progress MRs: "WIP"
       - Otherwise: state value
     - `last_updated` - Last Updated (formatted from timestamp)
     - `description` - Task description (from GitLab API, may be empty)
     - `source` - Source: "gitlab"
     - `type` - Type:
       - For issues: "issue"
       - For merge requests: "merge_request"
     - `mr_status` - (For MRs only) Computed status: "Draft", "Ready", or "Merged"
   - Store as an array/list for merging with Jira tasks

**Error Handling:**
- **API rate limit (429):**
  - Display warning: "API rate limit reached. Showing partial results from Jira only."
  - Continue with Jira data (GitLab is optional)
  - Troubleshooting: Rate limits reset hourly. Wait and retry, or reduce query frequency.
- **Authentication error (401):**
  - Display warning: "GitLab authentication failed. Check your GitLab MCP credentials. Showing Jira data only."
  - Skip GitLab data, continue with Jira-only
  - Troubleshooting: Verify personal access token is valid. Re-authenticate in MCP settings.
- **Permission error (403):**
  - Display warning: "GitLab access denied. Your account lacks permission to view these projects. Showing Jira data only."
  - Skip GitLab data, continue with Jira-only
  - Troubleshooting: Contact GitLab administrator to grant project access.
- **Server error (500, 502, 503):**
  - Display warning: "GitLab server error. The GitLab service may be temporarily unavailable. Showing Jira data only."
  - Skip GitLab data, continue with Jira-only
  - Troubleshooting: Check GitLab status or try again later.
- **Network timeout:**
  - Display warning: "GitLab request timed out. Showing Jira data only."
  - Continue with Jira-only
  - Troubleshooting: Verify network connectivity and firewall settings.
- **No results:**
  - Continue (empty GitLab list is valid - team may not use GitLab)
- **No GitLab project IDs in projects.json:**
  - Continue with assignee-only queries (if git_emails exist)
- **No git_emails in members.json:**
  - Continue with project-only queries (if gitlab_project_ids exist)
- **Malformed response:**
  - Display warning: "Error parsing GitLab response. Showing Jira data only."
  - Skip GitLab data
  - Troubleshooting: If the issue persists, check GitLab API version compatibility.

**Data Storage:**
Store the GitLab task list in a variable:
- `gitlab_tasks` - Array of task objects with structure:
  ```json
  [
    {
      "assignee": "Sarah Johnson",
      "assignee_email": "sarah@example.com",
      "task_id": "#123",
      "title": "Fix login bug",
      "status": "opened",
      "last_updated": "2026-02-26 10:15",
      "description": "Users cannot log in with OAuth2",
      "source": "gitlab",
      "type": "issue"
    },
    {
      "assignee": "John Doe",
      "assignee_email": "john@example.com",
      "task_id": "!456",
      "title": "Add authentication feature",
      "status": "Draft",
      "last_updated": "2026-02-26 09:30",
      "description": "Implement JWT-based auth",
      "source": "gitlab",
      "type": "merge_request",
      "mr_status": "Draft"
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

### Step 8A: Check Slack MCP Availability (Optional)

Check if Slack MCP is available for enriching member display names.

**Instructions:**

1. **Check for Slack MCP tools:**
   - Attempt to detect Slack MCP by checking if Slack-related tools are available
   - Look for tools like `users.info` or similar Slack MCP functions
   - This can be done using ToolSearch or by attempting to call a Slack MCP tool

2. **Handle Slack MCP availability:**

   **If Slack MCP is unavailable:**
   - Set `slack_mcp_available = false`
   - DO NOT display any error or warning message
   - Silently proceed to next step
   - Member names will fall back to values from `members.json`

   **If Slack MCP is available:**
   - Set `slack_mcp_available = true`
   - Slack names will be used to enrich member display names later
   - Proceed to next step

3. **Store availability flag:**
   - Store `slack_mcp_available` flag (true/false) for use in future steps
   - This flag will be used when rendering the task table to determine if Slack names should be fetched

**Error Handling:**
- Slack MCP is OPTIONAL - completely silent fallback
- No error messages or warnings should be displayed
- If Slack MCP is unavailable, use names from `members.json` without any notification
- This is graceful degradation - users won't even know Slack was checked

**Data Storage:**
Store the availability flag for later use:
- `slack_mcp_available` - Boolean (true/false)

**Important Notes:**
- This is a silent check - no user-facing messages regardless of availability
- Unlike GitLab (which shows a warning), Slack is completely transparent
- Slack MCP enhances the output but is not required
- The actual Slack name fetching will happen in the next step
- This step only checks availability and sets a flag

### Step 8B: Fetch Slack Display Names (Optional)

If Slack MCP is available, fetch display names for team members with Slack user IDs.

**Instructions:**

1. **Check if Slack fetching should proceed:**
   - If `slack_mcp_available = false` (from Step 8A), skip this entire step
   - If `slack_mcp_available = true`, proceed with fetching

2. **Initialize Slack name map:**
   - Create an empty map to store Slack display names
   - Structure: `slack_names[email] = display_name`
   - This map will be used when rendering the task table

3. **Loop through team members:**
   - Use the members array loaded in Step 6
   - For each member in the members array:
     ```
     for member in members:
       # Check if member has slack_user_id field
       if member has "slack_user_id" field and it is not null:
         # Proceed to fetch Slack name
       else:
         # Skip this member (no Slack user ID)
     ```

4. **Fetch Slack user info:**
   - For each member with `slack_user_id`, call Slack MCP:
   - Use the Slack MCP `users.info` tool or API
   - Pass the `slack_user_id` as the user parameter
   - Example call structure:
     ```
     Slack MCP users.info:
       user: <member.slack_user_id>
     ```

5. **Extract display name from response:**
   - The Slack API response contains user profile data
   - Extract display name with this priority:
     1. `profile.display_name` (if not empty)
     2. `profile.real_name` (if display_name is empty)
     3. Fallback to members.json name if both are empty

   Example response structure:
   ```json
   {
     "ok": true,
     "user": {
       "id": "U123456",
       "profile": {
         "display_name": "Sarah",
         "real_name": "Sarah Johnson"
       }
     }
   }
   ```

6. **Store in name map:**
   - Add the Slack display name to the map:
     ```
     slack_names[member.email] = extracted_display_name
     ```
   - Use the member's email as the key (same key used in task assignee lookups)

7. **Handle API errors gracefully:**
   - If Slack API call fails for a specific user:
     - DO NOT display an error message
     - DO NOT stop processing other users
     - Simply skip that user and continue
     - That user will fall back to their members.json name when rendering

   - Common error scenarios:
     - Invalid or expired `slack_user_id`
     - User not found in Slack workspace
     - Slack API rate limits
     - Network errors

   - All errors should be silently handled (graceful degradation)

8. **Complete the map:**
   - After looping through all members, the `slack_names` map is complete
   - Members without `slack_user_id` will not be in this map (expected)
   - Members with failed API calls will not be in this map (error fallback)
   - Only successfully fetched Slack names are in the map

**Error Handling:**
- All errors are silent - no error messages displayed to user
- Failed Slack lookups for individual users do not stop processing
- Members without Slack names will fall back to members.json names in rendering
- If Slack MCP becomes unavailable during fetching, stop and proceed to next step
- Partial results are OK - use whatever names were successfully fetched

**Data Storage:**
Store the Slack name map for use in Step 11 (table rendering):
- `slack_names` - Map of email → display_name (e.g., `{"sarah@example.com": "Sarah"}`)
- Empty map if Slack MCP unavailable or no members have `slack_user_id`

**Important Notes:**
- Only runs if `slack_mcp_available = true`
- Only fetches for members with `slack_user_id` field in members.json
- Completely silent - no user-facing messages regardless of success/failure
- Graceful degradation - partial results are acceptable
- The fetched names will be used in Step 11 when rendering the task table
- Names from this map take precedence over members.json names


### Step 9: Merge Task Lists

Combine Jira and GitLab tasks into a single unified list.

**Instructions:**

1. **Merge task arrays:**
   - Take `jira_tasks` from Step 7
   - Take `gitlab_tasks` from Step 8 (may be empty array if GitLab unavailable)
   - Concatenate both arrays into `all_tasks`
   - Example: `all_tasks = jira_tasks + gitlab_tasks`

2. **Sort merged list:**
   - Primary sort: Member name (alphabetical order)
   - Secondary sort: Status (prioritize "Blocked" first, then "In Progress", then others)
   - Tertiary sort: Last updated (most recent first)

3. **Store merged list:**
   - Store in `all_tasks` variable for use in filtering and rendering steps

**Important Notes:**
- The merged list includes tasks assigned to both team members AND external assignees
- External assignees (not in members.json) were already handled in Steps 7/8
- All tasks should be included regardless of whether assignee is internal or external

**Data Storage:**
- `all_tasks` - Combined array of all task objects from both sources

**Example merged data:**
```json
[
  {
    "assignee": "John Doe",
    "task_id": "PROJ-123",
    "title": "Implement login feature",
    "status": "In Progress",
    "last_updated": "2026-02-26 14:30",
    "source": "Jira"
  },
  {
    "assignee": "John Doe",
    "task_id": "!456",
    "title": "Add authentication feature",
    "status": "Draft",
    "last_updated": "2026-02-26 09:30",
    "source": "GitLab"
  },
  {
    "assignee": "Sarah Johnson",
    "task_id": "#123",
    "title": "Fix login bug",
    "status": "opened",
    "last_updated": "2026-02-26 10:15",
    "source": "GitLab"
  },
  {
    "assignee": "Alex Chen (external)",
    "task_id": "PROJ-456",
    "title": "External contractor work",
    "status": "In Progress",
    "last_updated": "2026-02-26 11:00",
    "source": "Jira"
  }
]
```

### Step 10: Apply Member Filter (If Provided)

Filter the task list to show only tasks for the selected member (if `--member` parameter was provided).

**Instructions:**

1. **Check if member filter was provided:**
   - Check if `selected_member` exists (from Steps 4A-4B)
   - If `selected_member` is null (no --member parameter provided), skip this step
   - If `selected_member` exists, proceed with filtering

2. **Apply filter to task list:**
   - Take `all_tasks` array (from Step 9)
   - Filter tasks where `task.assignee` matches `selected_member.email`
   - Use email for matching (more accurate than name)
   - Store filtered results back in `all_tasks`

   **Matching Logic:**
   - Compare `task.assignee` (enriched name from Steps 7/8) with the member's email
   - Since tasks use enriched names (from `member_map`), match by looking up the email from `member_map`
   - For each task:
     - If task assignee name matches any member name in `member_map` whose email is `selected_member.email`, include it
     - Otherwise, exclude it

   **Alternative simpler approach:**
   - Store assignee email in task objects during Steps 7/8 (alongside assignee name)
   - Filter by comparing `task.assignee_email` with `selected_member.email`

3. **Handle empty results:**
   - If filtered list is empty (no tasks found for member):
     - Display message:
       ```
       [Member Name] has no active tasks.
       ```
     - Do not proceed to table rendering
     - Exit successfully

4. **Handle non-empty results:**
   - If filtered list has tasks, proceed to Step 11 (table rendering)
   - Display message before table:
     ```
     Showing tasks for [Member Name]:
     ```

**Data Storage:**
- Update `all_tasks` with filtered results (only if filter was applied)

**Important Notes:**
- This step is optional - only runs if `--member` parameter was provided
- Match by email address for accuracy (names can be ambiguous)
- Use member's name (not email) in display messages
- Filter applies to merged task list (both Jira and GitLab tasks)
- Empty results are valid - user should know if member has no tasks

**Example:**
If user ran `/team-status --team=team-alpha --member=sarah`:
- `selected_member` = `{"name": "Sarah Johnson", "email": "sarah@example.com", "role": "Engineer"}`
- Filter `all_tasks` to only include tasks where assignee is "Sarah Johnson"
- If no tasks: Display "Sarah Johnson has no active tasks."
- If tasks found: Display "Showing tasks for Sarah Johnson:" followed by table

### Step 10A: Apply Status Filter (If Provided)

Filter the task list to show only tasks with a specific status (if status filter was parsed from query).

**Instructions:**

1. **Check if status filter was provided:**
   - Check if `status_filter` exists (from Step 4C)
   - If `status_filter` is null (no status filter in query), skip this step
   - If `status_filter` exists, proceed with filtering

2. **Apply filter to task list:**
   - Take `all_tasks` array (from Step 9 or Step 10 if member filter was applied)
   - Filter tasks where `task.status` matches `status_filter`
   - Use case-insensitive matching to handle status variations
   - Store filtered results back in `all_tasks`

   **Matching Logic:**
   - **For "Blocked" status:**
     - Match if task status contains "Blocked" or "Block" (case-insensitive)
     - Examples: "Blocked", "BLOCKED", "blocked", "Block"

   - **For "In Progress" status:**
     - Match if task status contains "In Progress", "In Development", or "InProgress" (case-insensitive)
     - Examples: "In Progress", "IN PROGRESS", "in progress", "In Development"

   - **Exact match for other statuses:**
     - If `status_filter` is not "Blocked" or "In Progress", use exact match (case-insensitive)

3. **Handle empty results:**
   - If filtered list is empty (no tasks found with that status):
     - Display message:
       ```
       No tasks found with status: [Status Filter]
       ```
     - Do not proceed to table rendering
     - Exit successfully

4. **Handle non-empty results:**
   - If filtered list has tasks, proceed to Step 11 (table rendering)
   - Display message before table:
     ```
     Showing [status_filter] tasks:
     ```

**Data Storage:**
- Update `all_tasks` with filtered results (only if filter was applied)

**Important Notes:**
- This step is optional - only runs if query contains status keywords (Step 4C)
- Applies after member filtering (Step 10), so can combine both filters
- Use case-insensitive matching to handle status variations from different systems (Jira, GitLab)
- Handle common status synonyms (e.g., "In Progress" = "In Development")
- Filter applies to merged task list (both Jira and GitLab tasks)
- Empty results are valid - user should know if no tasks match the status

**Example:**
If user ran `/team-status --team=team-alpha "blocked tasks"`:
- `status_filter` = `"Blocked"` (from Step 4C)
- Filter `all_tasks` to only include tasks where status matches "Blocked"
- If no tasks: Display "No tasks found with status: Blocked"
- If tasks found: Display "Showing Blocked tasks:" followed by table

If user ran `/team-status --team=team-alpha --member=sarah "in progress"`:
- Step 10 filters to Sarah's tasks
- This step (10A) filters Sarah's tasks to only "In Progress" status
- Display "Showing In Progress tasks for Sarah Johnson:" followed by table

### Step 10B: Apply Keyword Filter (If Provided)

Filter the task list by keyword if a keyword filter was set in Step 4C.

**Instructions:**

1. **Check if keyword filter was provided:**
   - Check if `keyword_filter` exists (from Step 4C)
   - If `keyword_filter` is null (no keyword in query), skip this step
   - If `keyword_filter` exists, proceed with filtering

2. **Apply filter to task list:**
   - Take `all_tasks` array (from Step 10A if status filter applied, Step 10 if member filter applied, or Step 9)
   - Filter tasks where the keyword appears in either:
     - `task.title` (case-insensitive partial match)
     - `task.description` (case-insensitive partial match, if available)
   - Support partial keyword matching (e.g., "auth" matches "authentication", "authorize", "OAuth")
   - Store filtered results back in `all_tasks`

   **Matching Logic:**
   - Convert both keyword and task fields to lowercase for comparison
   - Check if keyword appears anywhere in the title or description (substring search)
   - For each task:
     - If keyword is found in title OR description, include it
     - Otherwise, exclude it

   **Example Implementation:**
   ```bash
   # For each task:
   keyword_lower=$(echo "$keyword_filter" | tr '[:upper:]' '[:lower:]')
   title_lower=$(echo "$task.title" | tr '[:upper:]' '[:lower:]')

   # Check if keyword is in title
   if echo "$title_lower" | grep -iq "$keyword_lower"; then
     include_task=true
   fi

   # If description field exists, also check description
   if [ -n "$task.description" ]; then
     desc_lower=$(echo "$task.description" | tr '[:upper:]' '[:lower:]')
     if echo "$desc_lower" | grep -iq "$keyword_lower"; then
       include_task=true
     fi
   fi
   ```

3. **Handle empty results:**
   - If filtered list is empty (no tasks found matching keyword):
     - Display message:
       ```
       No tasks found matching keyword: [keyword_filter]
       ```
     - Do not proceed to table rendering
     - Exit successfully

4. **Handle non-empty results:**
   - If filtered list has tasks, proceed to Step 10C (source filtering)
   - Display message before table:
     ```
     Showing tasks matching "[keyword_filter]":
     ```

**Data Storage:**
- Update `all_tasks` with filtered results (only if filter was applied)

**Important Notes:**
- This step is optional - only runs if keyword filter was parsed from query in Step 4C
- Keyword matching should be case-insensitive
- Support partial matches (substring search, not exact word matching)
- Search both title and description fields when available
- If description field is not available in task data (common for Jira summaries), only search title
- Filter applies after status filtering (Step 10A) and member filtering (Step 10)
- Can combine with other filters (e.g., "sarah's auth tasks" → member + keyword filter)
- Empty results are valid - user should know if no tasks match the keyword

**Example Queries:**

If user ran `/team-status --team=team-alpha "auth feature"`:
- `keyword_filter` = "auth" (extracted from query in Step 4C)
- Filter `all_tasks` to only include tasks where title or description contains "auth"
- Matches tasks with titles like:
  - "Implement authentication"
  - "Fix auth bug in login"
  - "OAuth integration with Google"
  - "Add authorization middleware"
- If no tasks: Display "No tasks found matching keyword: auth"
- If tasks found: Display "Showing tasks matching 'auth':" followed by table

If user ran `/team-status --team=team-alpha "payment"`:
- `keyword_filter` = "payment"
- Matches tasks with titles like:
  - "Payment gateway integration"
  - "Fix payment processing bug"
  - "Update payment API endpoints"
- Display "Showing tasks matching 'payment':" followed by table

If user ran `/team-status --team=team-alpha --member=sarah "auth"`:
- Step 10 filters to Sarah's tasks
- This step (10B) filters Sarah's tasks to only those matching "auth"
- Display "Showing tasks matching 'auth' for Sarah Johnson:" followed by table

### Step 10C: Apply Source Filter (If Provided)

Filter the task list to show only tasks from specific sources (if source filter was parsed from query).

**Instructions:**

1. **Check if source filter was provided:**
   - Check if `source_filter` exists (from Step 4C)
   - If `source_filter` is null (no source filter in query), skip this step
   - If `source_filter` exists, proceed with filtering

2. **Apply filter to task list:**
   - Take `all_tasks` array (from Step 10B if keyword filter applied, Step 10A if status filter applied, Step 10 if member filter applied, or Step 9)
   - Filter tasks based on the `source_filter` value
   - Store filtered results back in `all_tasks`

   **Matching Logic:**

   - **For "Jira" source filter** (query contains "jira only"):
     - Filter tasks where `task.source == "Jira"`
     - Exclude all GitLab tasks (both issues and merge requests)
     - Example filter condition: `task.source == "Jira"`

   - **For "GitLab" source filter** (query contains "gitlab only"):
     - Filter tasks where `task.source == "GitLab"`
     - Exclude all Jira tasks
     - Example filter condition: `task.source == "GitLab"`

   - **For "GitLab_MRs" source filter** (query contains "merge requests" or "MRs"):
     - Filter tasks where `task.source == "GitLab"` AND `task.type == "merge_request"`
     - Exclude all Jira tasks and GitLab issues
     - Example filter condition: `task.source == "GitLab" AND task.type == "merge_request"`
     - Note: The task.type field should be set in Step 8 when parsing GitLab responses:
       - For merge requests: `task.type = "merge_request"`
       - For issues: `task.type = "issue"`

3. **Handle empty results:**
   - If filtered list is empty (no tasks found from that source):
     - Display appropriate message based on source_filter:
       - For "Jira": `No Jira tasks found.`
       - For "GitLab": `No GitLab tasks found.`
       - For "GitLab_MRs": `No merge requests found.`
     - Do not proceed to table rendering
     - Exit successfully

4. **Handle non-empty results:**
   - If filtered list has tasks, proceed to Step 10D (query fallback check)
   - Display message before table based on source_filter:
     - For "Jira": `Showing Jira tasks only:`
     - For "GitLab": `Showing GitLab tasks only:`
     - For "GitLab_MRs": `Showing merge requests only:`

**Data Storage:**
- Update `all_tasks` with filtered results (only if filter was applied)

**Important Notes:**
- This step is optional - only runs if query contains source keywords (Step 4C)
- Applies after keyword filtering (Step 10B), status filtering (Step 10A), and member filtering (Step 10)
- Can combine with other filters (e.g., "sarah's merge requests" → member + source filter)
- Requires `task.type` field to be set in Step 8 for distinguishing GitLab issues from merge requests
- Member + status filtering already works via existing steps combining naturally
- Empty results are valid - user should know if no tasks match the source filter

**Example Queries:**

If user ran `/team-status --team=team-alpha "jira only"`:
- `source_filter` = `"Jira"` (from Step 4C)
- Filter `all_tasks` to only include tasks where source is "Jira"
- Excludes all GitLab issues and merge requests
- If no tasks: Display "No Jira tasks found."
- If tasks found: Display "Showing Jira tasks only:" followed by table

If user ran `/team-status --team=team-alpha "gitlab only"`:
- `source_filter` = `"GitLab"` (from Step 4C)
- Filter `all_tasks` to only include tasks where source is "GitLab"
- Includes both GitLab issues and merge requests
- Excludes all Jira tasks
- If no tasks: Display "No GitLab tasks found."
- If tasks found: Display "Showing GitLab tasks only:" followed by table

If user ran `/team-status --team=team-alpha "merge requests"` or `"MRs"`:
- `source_filter` = `"GitLab_MRs"` (from Step 4C)
- Filter `all_tasks` to only include GitLab merge requests
- Excludes all Jira tasks and GitLab issues
- If no tasks: Display "No merge requests found."
- If tasks found: Display "Showing merge requests only:" followed by table

If user ran `/team-status --team=team-alpha --member=sarah "merge requests"`:
- Step 10 filters to Sarah's tasks
- This step (10C) filters Sarah's tasks to only merge requests
- Display "Showing merge requests only for Sarah Johnson:" followed by table

If user ran `/team-status --team=team-alpha "sarah's blocked tasks"`:
- Step 4C sets `query_member_filter = "sarah"` and `status_filter = "Blocked"`
- Step 10 filters to Sarah's tasks
- Step 10A filters to blocked status
- No source filter applied (source_filter is null)
- All sources (Jira and GitLab) are included

### Step 10D: Display Query Fallback (If Needed)

Check if a query was provided but could not be parsed, and display a helpful message.

**Instructions:**

1. **Check query parsing status:**
   - Check if `original_query` exists (a query string was provided in Step 4C)
   - Check if `query_parsed = false` (query was provided but no filters were extracted)
   - If both conditions are true, proceed with fallback message
   - If `query_parsed = true` or no query was provided, skip this step

2. **Display fallback message:**
   When a query cannot be parsed, display:
   ```
   Could not parse query: "[original_query]"

   Showing default view. Try queries like:
   - "blocked tasks"
   - "sarah's work"
   - "merge requests"
   - "jira only"
   - "auth feature"
   ```

3. **Continue to table rendering:**
   - After displaying the fallback message, proceed to Step 11
   - The table will show all tasks (default view) since no filters were applied

**Important Notes:**
- This step only runs when a query was provided but couldn't be parsed
- The original query string is preserved in `original_query` for display
- The example queries in the message should help users understand the expected format
- All tasks will be shown in the table (default view) since no filters were extracted
- This provides a good user experience by explaining why the query didn't work and showing helpful examples

**Example Scenarios:**

If user ran `/team-status --team=team-alpha "xyz123"`:
- `original_query` = "xyz123"
- `query_parsed` = false (no recognizable patterns)
- Display:
  ```
  Could not parse query: "xyz123"

  Showing default view. Try queries like:
  - "blocked tasks"
  - "sarah's work"
  - "merge requests"
  - "jira only"
  - "auth feature"
  ```
- Proceed to show all tasks in table

If user ran `/team-status --team=team-alpha "blocked tasks"`:
- `original_query` = "blocked tasks"
- `query_parsed` = true (status filter extracted)
- Skip this step (query was successfully parsed)
- Proceed directly to filtered table rendering

### Step 11: Render Combined Task Table

Display the merged and filtered task list in a formatted CLI table.

**Instructions:**

1. **Check for empty results and display appropriate message:**

   Before rendering the table, check if `all_tasks` is empty. If it is, determine the appropriate empty state message based on what filters were applied:

   **Empty State Logic:**

   a. **Check if member filter was applied (`selected_member` exists):**
      - Display: `[Member Name] has no active tasks.`
      - Use `selected_member.name` for the member name
      - Exit successfully (do not render table)

   b. **Check if query filter was applied (any of these exist: `status_filter`, `keyword_filter`, `source_filter`):**
      - Display: `No tasks match your query: '[original_query]'. Try a different search.`
      - Use `original_query` for the query text (from Step 4C)
      - Exit successfully (do not render table)

   c. **No filters applied (team view with zero tasks):**
      - Display: `No active tasks found for [team-name]. All clear!`
      - Use `team_name` from Step 2 or parameter
      - Exit successfully (do not render table)

   **Implementation Example:**
   ```
   if all_tasks is empty:
     if selected_member exists:
       echo "[selected_member.name] has no active tasks."
       exit 0
     elif status_filter exists OR keyword_filter exists OR source_filter exists:
       echo "No tasks match your query: '[original_query]'. Try a different search."
       exit 0
     else:
       echo "No active tasks found for [team_name]. All clear!"
       exit 0
   ```

   **Important Notes:**
   - Check filters in priority order: member filter first, then query filters, then default
   - Only one empty state message should be displayed
   - Exit gracefully after displaying message (do not attempt to render empty table)
   - Use the original query string (`original_query`) for the filtered query message

2. **Use merged task list:**
   - Use `all_tasks` from Step 9 (merged) or Step 10 (filtered if --member provided)
   - This list contains both Jira and GitLab tasks
   - Only proceed to this step if `all_tasks` is not empty

3. **Sort tasks (if not already sorted):**
   - Primary sort: Member name (alphabetical order)
   - Secondary sort: Status (prioritize Blocked, then In Progress, then others)

4. **Format task IDs for display:**
   Before rendering the table, ensure task IDs are formatted correctly based on their source:
   - **Jira tasks**: Display task ID as-is (e.g., "PROJ-123")
   - **GitLab issues**: Ensure ID has "#" prefix (e.g., "#123")
   - **GitLab merge requests**: Ensure ID has "!" prefix (e.g., "!456")

   Note: Task IDs should already be prefixed during Step 8 (GitLab query parsing).
   This step verifies the format is correct before rendering.

   For each task in `all_tasks`:
   ```
   if task.source == "GitLab":
     if task.type == "merge_request":
       # Ensure ID starts with "!"
       if not task.task_id.startswith("!"):
         task.task_id = "!" + task.task_id
     elif task.type == "issue":
       # Ensure ID starts with "#"
       if not task.task_id.startswith("#"):
         task.task_id = "#" + task.task_id
   # Jira tasks: no changes needed
   ```

5. **Build table structure dynamically based on additional columns:**

   Check the `additional_columns` array from Step 4C to determine which columns to include.

   **Default columns (always present):**
   - Member
   - Task ID
   - Title
   - Status

   **Additional columns (added after Status if requested):**
   Add columns in this order based on what's in `additional_columns[]`:
   1. **Source** (if "source" in additional_columns)
   2. **Last Updated** (if "updated" in additional_columns)
   3. **Description** (if "description" in additional_columns)
   4. **Email** (if "email" in additional_columns)
   5. **MR Status** (if task is GitLab MR and any additional columns requested)

   **Column order logic:**
   ```
   columns = ["Member", "Task ID", "Title", "Status"]

   if "source" in additional_columns:
     columns.append("Source")

   if "updated" in additional_columns:
     columns.append("Last Updated")

   if "description" in additional_columns:
     columns.append("Description")

   if "email" in additional_columns:
     columns.append("Email")

   # MR Status is automatically added for GitLab MRs when any additional columns are shown
   if len(additional_columns) > 0:
     # Will be conditionally added per row for MRs only
     pass
   ```

6. **Format table using `column` command:**
   ```bash
   # Build header row dynamically
   header="Member|Task ID|Title|Status"
   separator="------|-------|-----|------"

   if [[ " ${additional_columns[@]} " =~ " source " ]]; then
     header="$header|Source"
     separator="$separator|------"
   fi

   if [[ " ${additional_columns[@]} " =~ " updated " ]]; then
     header="$header|Last Updated"
     separator="$separator|----------------"
   fi

   if [[ " ${additional_columns[@]} " =~ " description " ]]; then
     header="$header|Description"
     separator="$separator|-----------"
   fi

   if [[ " ${additional_columns[@]} " =~ " email " ]]; then
     header="$header|Email"
     separator="$separator|-----"
   fi

   # For MR Status: will be added conditionally per row
   # (only for GitLab MRs when additional columns are present)

   echo "$header"
   echo "$separator"

   # For each task in all_tasks:
   for task in all_tasks:
     # Determine member name to display (priority: Slack name > members.json name > task assignee)
     if task.assignee_email exists and slack_names[task.assignee_email] exists:
       member_name = slack_names[task.assignee_email]
     elif task.assignee_email exists and member_map[task.assignee_email] exists:
       member_name = member_map[task.assignee_email].name
     else:
       member_name = task.assignee

     # Truncate member name and title
     member_name=$(truncate "$member_name" 20)
     title=$(truncate "$task.title" 40)

     # Build row starting with default columns
     row="$member_name|$task.task_id|$title|$task.status"

     # Add additional columns based on additional_columns array
     if [[ " ${additional_columns[@]} " =~ " source " ]]; then
       source_display="Jira"
       if [[ "$task.source" == "gitlab" ]]; then
         source_display="GitLab"
       fi
       row="$row|$source_display"
     fi

     if [[ " ${additional_columns[@]} " =~ " updated " ]]; then
       # Format timestamp as "YYYY-MM-DD HH:MM"
       if [ -n "$task.last_updated" ]; then
         formatted_time=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$task.last_updated" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$task.last_updated")
       else
         formatted_time="-"
       fi
       row="$row|$formatted_time"
     fi

     if [[ " ${additional_columns[@]} " =~ " description " ]]; then
       # Truncate description to ~50 chars
       if [ -n "$task.description" ]; then
         desc=$(truncate "$task.description" 50)
       else
         desc="N/A"
       fi
       row="$row|$desc"
     fi

     if [[ " ${additional_columns[@]} " =~ " email " ]]; then
       # Display assignee email or "-"
       if [ -n "$task.assignee_email" ]; then
         email="$task.assignee_email"
       else
         email="-"
       fi
       row="$row|$email"
     fi

     # Add MR Status for GitLab MRs (only when additional columns are requested)
     # This is added conditionally per row, not as a header column
     # Note: MR status is shown inline as part of Status column or can be separate
     # For now, we'll include it inline with Status for MRs when additional columns exist

     echo "$row"

   # Pipe to column for formatting
   column -t -s '|'
   ```

7. **Handle long values:**
   - If member name > 20 chars: truncate with "..."
   - If title > 40 chars: truncate with "..."
   - If description > 50 chars: truncate with "..."
   - Task ID, Status, Source: display as-is
   - Email: display as-is or "-" if not available
   - Last Updated: format as "YYYY-MM-DD HH:MM" or "-" if not available


**Alternative Implementation (printf):**

If `column` command is unavailable, use `printf` for manual formatting with dynamic columns:
```bash
# Build format string dynamically based on additional_columns
format_header="%-20s | %-12s | %-40s | %-15s"
format_sep="%-20s-+-%-12s-+-%-40s-+-%-15s"
format_data="%-20s | %-12s | %-40s | %-15s"

header_args=("Member" "Task ID" "Title" "Status")
sep_args=("----" "-------" "-----" "------")

if [[ " ${additional_columns[@]} " =~ " source " ]]; then
  format_header="$format_header | %-8s"
  format_sep="$format_sep-+-%-8s"
  format_data="$format_data | %-8s"
  header_args+=("Source")
  sep_args+=("------")
fi

if [[ " ${additional_columns[@]} " =~ " updated " ]]; then
  format_header="$format_header | %-16s"
  format_sep="$format_sep-+-%-16s"
  format_data="$format_data | %-16s"
  header_args+=("Last Updated")
  sep_args+=("----------------")
fi

if [[ " ${additional_columns[@]} " =~ " description " ]]; then
  format_header="$format_header | %-50s"
  format_sep="$format_sep-+-%-50s"
  format_data="$format_data | %-50s"
  header_args+=("Description")
  sep_args+=("-----------")
fi

if [[ " ${additional_columns[@]} " =~ " email " ]]; then
  format_header="$format_header | %-30s"
  format_sep="$format_sep-+-%-30s"
  format_data="$format_data | %-30s"
  header_args+=("Email")
  sep_args+=("-----")
fi

printf "$format_header\n" "${header_args[@]}"
printf "$format_sep\n" "${sep_args[@]}"

for task in all_tasks:
  # Determine member name to display (priority: Slack name > members.json name > task assignee)
  if task.assignee_email exists and slack_names[task.assignee_email] exists:
    member_name = slack_names[task.assignee_email]
  elif task.assignee_email exists and member_map[task.assignee_email] exists:
    member_name = member_map[task.assignee_email].name
  else:
    member_name = task.assignee

  member=$(truncate "$member_name" 20)
  title=$(truncate "$task.title" 40)

  row_args=("$member" "$task.task_id" "$title" "$task.status")

  if [[ " ${additional_columns[@]} " =~ " source " ]]; then
    source_display="Jira"
    if [[ "$task.source" == "gitlab" ]]; then
      source_display="GitLab"
    fi
    row_args+=("$source_display")
  fi

  if [[ " ${additional_columns[@]} " =~ " updated " ]]; then
    if [ -n "$task.last_updated" ]; then
      formatted_time=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$task.last_updated" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$task.last_updated")
    else
      formatted_time="-"
    fi
    row_args+=("$formatted_time")
  fi

  if [[ " ${additional_columns[@]} " =~ " description " ]]; then
    if [ -n "$task.description" ]; then
      desc=$(truncate "$task.description" 50)
    else
      desc="N/A"
    fi
    row_args+=("$desc")
  fi

  if [[ " ${additional_columns[@]} " =~ " email " ]]; then
    if [ -n "$task.assignee_email" ]; then
      email="$task.assignee_email"
    else
      email="-"
    fi
    row_args+=("$email")
  fi

  printf "$format_data\n" "${row_args[@]}"
```

**Display Notes:**
- Member names use priority lookup: Slack display name (Step 8B) > members.json name (Step 6) > Jira/GitLab displayName (Steps 7/8)
- Slack names are seamlessly integrated - no indication to user whether name is from Slack or members.json
- Show Jira issue keys as-is (e.g., "PROJ-123")
- Show GitLab issue IDs with "#" prefix (e.g., "#123")
- Show GitLab MR IDs with "!" prefix (e.g., "!456")
- Truncate long values to maintain table readability
- Task ID format verification (Step 3) ensures consistent display regardless of data source
- Additional columns are displayed dynamically based on user query (Step 4C)
- Column order: Default columns first, then additional columns in fixed order: Source, Last Updated, Description, Email
- The `column -t -s '|'` command automatically adjusts column widths based on content

**Additional Column Rendering:**
- **Source column**: Only shown if "source" is in `additional_columns[]`. Displays "Jira" or "GitLab".
- **Last Updated column**: Only shown if "updated" is in `additional_columns[]`. Formatted as "YYYY-MM-DD HH:MM". Shows "-" if timestamp unavailable.
- **Description column**: Only shown if "description" is in `additional_columns[]`. Truncated to 50 chars. Shows "N/A" if empty.
- **Email column**: Only shown if "email" is in `additional_columns[]`. Shows assignee email or "-" if not available.
- **MR Status**: For GitLab merge requests, the status field already includes Draft/Ready/Merged status (computed in Step 8). No separate column needed.

**External Assignee Handling:**
- Tasks assigned to external users (not in members.json) should be displayed normally
- Use the assignee name from Steps 7/8 which already enriched external assignee names from API responses
- DO NOT filter out, skip, or throw errors for external assignees
- All tasks should appear in the table regardless of whether assignee is internal or external
- External assignees were already handled in Steps 7/8 and their names are in task.assignee field

**Column Widths:**
Default columns:
- Member: 20 characters (truncate with "...")
- Task ID: 12 characters
- Title: 40 characters (truncate with "...")
- Status: 15 characters

Additional columns (when requested):
- Source: 8 characters
- Last Updated: 16 characters (format: "YYYY-MM-DD HH:MM")
- Description: 50 characters (truncate with "...")
- Email: 30 characters (or full email if shorter)

**Timestamp Formatting:**
- Last Updated timestamps should be parsed from ISO 8601 format (from API)
- Display format: "YYYY-MM-DD HH:MM" (e.g., "2026-02-26 14:30")
- Handle parsing errors gracefully: if timestamp cannot be parsed, display original value or "-"
- Example conversion:
  - Input: "2026-02-26T14:30:45Z" or "2026-02-26T14:30:45.123Z"
  - Output: "2026-02-26 14:30"

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
