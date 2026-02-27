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

### Step 5: Display Placeholder Message

For now, display a placeholder message (will be replaced in subsequent slices).

**Instructions:**
Display: "Team status feature coming soon for [team-name]"

Replace `[team-name]` with the actual team name from Step 4.

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
