---
name: list-teams
description: List all initialized teams with their details (members count, projects count)
user-invocable: true
---

# List Teams Skill

This skill lists all initialized teams in the repository-based team management system.

## Usage

```
/list-teams
```

No parameters required.

## Instructions

When this skill is invoked, follow these steps:

### Step 1: Get All Team IDs

Call the `list_teams` function from the file operations utility:

```bash
bash -c 'source scripts/utils/file-ops.sh && list_teams'
```

This returns a JSON array of team IDs, for example:
```json
["team-001", "team-002"]
```

**Error Handling:**
- If the output is `[]` (empty array), skip to Step 5 (empty state handling)
- If the command fails, report the error to the user

### Step 2: Parse Team IDs

Parse the JSON array to extract individual team IDs. Use `jq` for JSON parsing:

```bash
echo '[team-ids-json]' | jq -r '.[]'
```

This will output one team ID per line.

### Step 3: Collect Team Details

For each team ID, read the following files:

1. **Team Config**: `.team/[team-id]/team-config.json`
   - Extract: `name` field

2. **Members**: `.team/[team-id]/members.json`
   - Count: Number of objects in array

3. **Projects**: `.team/[team-id]/projects.json`
   - Count: Number of objects in array

**Example bash commands:**

```bash
# Get team name
jq -r '.name' .team/[team-id]/team-config.json

# Count members
jq '. | length' .team/[team-id]/members.json

# Count projects
jq '. | length' .team/[team-id]/projects.json
```

**Error Handling:**
- If `team-config.json` is missing or invalid, use "Unknown" as the name
- If `members.json` is missing or invalid, use "?" for member count
- If `projects.json` is missing or invalid, use "?" for project count
- Note any errors but continue processing other teams

### Step 4: Format and Display Results

Display the results in a clean, formatted table. Use this format:

```
Found [N] team(s):

ID          | Name                | Members | Projects
------------|---------------------|---------|----------
team-001    | Engineering Team    | 5       | 3
team-002    | Product Team        | 3       | 1
```

**Formatting Guidelines:**
- Left-align all columns
- Use `|` as column separator
- Add a separator line under the header
- Pad columns for readability (ID: 12 chars, Name: 20 chars, Members: 8 chars, Projects: 10 chars)
- Show counts as numbers
- If any value is unknown/error, show "?" for that field

**Alternative Format** (if table is too complex):

```
Found [N] team(s):

1. Engineering Team (team-001)
   Members: 5 | Projects: 3

2. Product Team (team-002)
   Members: 3 | Projects: 1
```

### Step 5: Handle Empty State

If no teams exist (empty array from Step 1), display:

```
No teams initialized. Run /team-init to create your first team.
```

## Implementation Notes

### Working Directory

All commands should be run from the repository root. The `.team/` directory contains all team data.

### JSON Parsing Best Practices

- Always use `jq` for JSON parsing (reliable and safe)
- Use `-r` flag for raw output (removes quotes)
- Use `. | length` to count array elements
- Handle parse errors gracefully

### Performance Considerations

- For many teams (>10), consider showing a progress indicator
- Read all files in sequence (no need for parallel processing unless >50 teams)

### Example Complete Implementation

```bash
# Get team IDs
team_ids=$(bash -c 'source scripts/utils/file-ops.sh && list_teams')

# Check if empty
if [ "$team_ids" = "[]" ]; then
  echo "No teams initialized. Run /team-init to create your first team."
  exit 0
fi

# Parse and display
echo "$team_ids" | jq -r '.[]' | while read -r team_id; do
  name=$(jq -r '.name // "Unknown"' ".team/$team_id/team-config.json" 2>/dev/null || echo "Unknown")
  members=$(jq '. | length' ".team/$team_id/members.json" 2>/dev/null || echo "?")
  projects=$(jq '. | length' ".team/$team_id/projects.json" 2>/dev/null || echo "?")

  echo "$team_id | $name | $members | $projects"
done
```

## Success Criteria

The skill is successful when:
1. All initialized teams are displayed
2. Team name, member count, and project count are shown for each team
3. Output is formatted clearly and readable
4. Empty state is handled with appropriate message
5. Errors are handled gracefully (missing/invalid files don't crash the skill)

## Related Skills

- `/team-init` - Create a new team
- `/add-member` - Add members to a team
- `/add-project` - Add projects to a team
