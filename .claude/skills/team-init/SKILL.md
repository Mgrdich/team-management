---
name: team-init
description: Initialize team management with a specific team name
argument-hint: --name="Team Name"
user-invocable: true
---

# Team Initialization Skill

This skill initializes the team management system for a new team by creating the necessary directory structure and initial JSON configuration files.

## Behavior

When invoked, you MUST follow these steps in order:

### Step 1: Get Team Name

If the user provided a `--name` parameter:
- Use that value as the team name
- Example: `/team-init --name="Engineering Team"`

If no `--name` parameter was provided:
- Use the `Bash` tool to prompt for the team name:
  ```bash
  read -p "Enter team name: " team_name && echo "$team_name"
  ```
- Store the response for use in subsequent steps

### Step 2: Generate Team ID

Convert the team name to a kebab-case ID using the ID generator utility:

```bash
./scripts/utils/id-generator.sh team_name_to_id "Team Name"
```

This will output a kebab-case ID like `team-name` or `engineering-team`.

**Error Handling**:
- If the script fails or returns empty output, inform the user and stop
- If the team name contains invalid characters, the script will handle sanitization

### Step 3: Validate Team Doesn't Exist

Check if a team with this ID already exists:

```bash
./scripts/utils/file-ops.sh validate_team_exists "team-id"
```

**Expected Behavior**:
- Exit code 0: Team does NOT exist (proceed to Step 4)
- Exit code 1: Team already exists (stop and inform user)

If team exists, display:
```
Error: Team with ID 'team-id' already exists at .team/team-id/
Use a different team name or manage the existing team.
```

### Step 4: Create Team Structure

Create the team directory structure:

```bash
./scripts/utils/file-ops.sh create_team_structure "team-id" "Team Name"
```

This creates the `.team/team-id/` directory.

**Error Handling**:
- If directory creation fails, display the error and stop
- Check exit code: 0 = success, non-zero = failure

### Step 5: Write Initial JSON Files

Write the three initial configuration files:

```bash
./scripts/utils/json-utils.sh write_initial_files "team-id" "Team Name"
```

This creates:
- `team-config.json` - Team metadata and settings
- `members.json` - Team members list (initially empty array)
- `projects.json` - Team projects list (initially empty array)

**Error Handling**:
- If file writing fails, display the error
- The script will create all three files or fail atomically

### Step 6: Display Summary

After successful completion, display a detailed summary:

```
Team initialization complete!

Team: Team Name
ID: team-id
Location: .team/team-id/

Created files:
  - team-config.json (team metadata and settings)
  - members.json (team members - empty)
  - projects.json (team projects - empty)

Next steps:
  1. Add team members: /team-member add
  2. Create first project: /team-project create
  3. Review team config: cat .team/team-id/team-config.json
```

## Error Scenarios

Handle these common error cases:

1. **Empty team name**: Prompt again or display error
2. **Team already exists**: Show existing team location, suggest alternatives
3. **Permission denied**: Check directory permissions for `.team/`
4. **Script not found**: Verify scripts exist in `scripts/utils/`
5. **Invalid characters in name**: The ID generator handles this, but inform user of the sanitized ID

## Usage Examples

### With team name parameter
```
/team-init --name="Engineering Team"
```

### Without parameter (prompts user)
```
/team-init
```

### Expected workflow
```
User: /team-init --name="Product Team Alpha"
Claude: [Executes scripts]
Claude: [Shows summary with team-product-team-alpha created]
```

## Important Notes

- Scripts are called using relative paths from the project root
- Check exit codes for each script call
- Display clear error messages if any step fails
- Do NOT continue to next step if current step fails
- The team ID is generated automatically from the name (kebab-case)
- All JSON files start with empty/minimal data structures
- The `.team/` directory is at the repository root

## Script Dependencies

This skill depends on these utility scripts:
- `./scripts/utils/id-generator.sh`
- `./scripts/utils/file-ops.sh`
- `./scripts/utils/json-utils.sh`

Verify these exist before execution if troubleshooting is needed.
