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

### Step 5: Check Jira MCP Availability

Verify that Jira MCP is available before proceeding.

**Instructions:**

1. **Check for Jira MCP tools:**
   - Attempt to detect Jira MCP by checking if Jira-related tools are available
   - Look for tools like `jira_search_issues` or similar Jira MCP functions

2. **If Jira MCP is unavailable:**
   - Display error message:
     ```
     Jira MCP not configured. Team status requires Jira integration.
     See docs/setup-jira-mcp.md for setup instructions.
     ```
   - Exit the command (do not proceed)

3. **If Jira MCP is available:**
   - Proceed to the next step

**Error Handling:**
- Jira MCP is REQUIRED for team status functionality
- Unlike GitLab and Slack MCPs (which are optional), the command cannot proceed without Jira MCP
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
