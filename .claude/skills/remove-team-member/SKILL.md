---
name: remove-team-member
description: Remove a team member from a team
user-invocable: true
---

# Remove Team Member Skill

This skill removes a team member from an existing team in the repository-based team management system.

## Usage

```
/remove-team-member --team=<team-id>
```

### Parameters

- `--team` (required): The team ID to remove a member from (e.g., `team-alpha`, `engineering-team`)

## Instructions

When this skill is invoked, follow these steps:

### Step 1: Parse and Validate Team Parameter

Extract the `--team` parameter from the command arguments.

**Error Handling:**
- If `--team` is missing, ask the user: "Which team would you like to remove a member from?"
- If the user provides a team name instead of ID, convert it using the ID generator utility

### Step 2: Validate Team Exists

Check if the team exists using the file operations utility:

```bash
bash -c 'source ./scripts/utils/file-ops.sh && validate_team_exists "<team-id>"'
```

**Error Handling:**
- If the command returns non-zero exit code, display error:
  ```
  Error: Team '<team-id>' not found.

  Run /list-teams to see available teams.
  ```
- Stop execution if team doesn't exist

### Step 3: Get Team Name

Read the team name for display purposes:

```bash
jq -r '.team_name' .team/<team-id>/team-config.json
```

### Step 4: Read Current Members

Read all members from the team's members.json file:

```bash
jq -c '.[]' .team/<team-id>/members.json
```

This outputs each member object on a separate line in compact JSON format.

**Error Handling:**
- If members.json is empty or doesn't exist, display:
  ```
  No members found in <team-name>.

  Use /add-team-members to add members first.
  ```
- Stop execution if no members exist

### Step 5: Present Members for Selection

Parse the member JSON objects and **use the `AskUserQuestion` tool** to present them:

**IMPORTANT: Always use AskUserQuestion tool, never ask in plain text**

```
AskUserQuestion parameters:
- Question: "Which member would you like to remove from <team-name>?"
- Header: "Select member"
- Options: Present each member with format:
  - Label: "<name>"
  - Description: "<email> - <role>"
- Add final option:
  - Label: "Cancel"
  - Description: "Don't remove anyone"
- multiSelect: false
```

**Example:**
```
Options:
  - Label: "John Doe"
    Description: "john@example.com - Engineer"
  - Label: "Jane Smith"
    Description: "jane@example.com - Designer"
  - Label: "Cancel"
    Description: "Don't remove anyone"
```

**If user selects "Cancel":**
- Display: "Member removal cancelled."
- Stop execution

### Step 6: Confirm Removal

After user selects a member, **use the `AskUserQuestion` tool** to confirm:

```
AskUserQuestion parameters:
- Question: "Are you sure you want to remove <member-name> (<member-email>) from <team-name>?"
- Header: "Confirm"
- Options:
  - Label: "Yes, remove"
    Description: "Remove this member from the team"
  - Label: "No, cancel"
    Description: "Keep this member in the team"
- multiSelect: false
```

**If user selects "No, cancel":**
- Display: "Member removal cancelled."
- Stop execution

### Step 7: Remove Member from Team

Extract the member's email from the selected member object and call the JSON utilities:

```bash
bash -c 'source ./scripts/utils/json-utils.sh && remove_member "<team-id>" "<member-email>"'
```

**Error Handling:**
- If the command fails, display the error message and stop
- The `remove_member` function removes the member by matching their email address

### Step 8: Display Confirmation

Show success confirmation:

```
✓ Removed <member-name> from <team-name>

Member Details:
  Name: <member-name>
  Email: <member-email>
  Role: <member-role>

Remaining members: <count>
```

Calculate the remaining member count by reading members.json:

```bash
jq '. | length' .team/<team-id>/members.json
```

## Example Scenarios

### Example 1: Remove Member Successfully

```
User: /remove-team-member --team=team-alpha

Claude: [Validates team exists]
Claude: [Reads members from team-alpha]

Claude: Which member would you like to remove from Team Alpha?
[Shows options via AskUserQuestion:]
  - John Doe (john@example.com - Engineer)
  - Jane Smith (jane@example.com - Designer)
  - Cancel

User: [Selects "John Doe"]

Claude: Are you sure you want to remove John Doe (john@example.com) from Team Alpha?
[Shows options via AskUserQuestion:]
  - Yes, remove
  - No, cancel

User: [Selects "Yes, remove"]

Claude: [Removes member via bash utility]

Claude:
✓ Removed John Doe from Team Alpha

Member Details:
  Name: John Doe
  Email: john@example.com
  Role: Engineer

Remaining members: 1
```

### Example 2: Cancel During Member Selection

```
User: /remove-team-member --team=engineering-team

Claude: Which member would you like to remove from Engineering Team?
[Shows options via AskUserQuestion:]
  - Alice Johnson (alice@example.com - Tech Lead)
  - Bob Smith (bob@example.com - Engineer)
  - Cancel

User: [Selects "Cancel"]

Claude: Member removal cancelled.
```

### Example 3: Cancel During Confirmation

```
User: /remove-team-member --team=team-beta

Claude: Which member would you like to remove from Team Beta?
[Shows member options]

User: [Selects "Jane Doe"]

Claude: Are you sure you want to remove Jane Doe (jane@example.com) from Team Beta?
[Shows confirmation options]

User: [Selects "No, cancel"]

Claude: Member removal cancelled.
```

### Example 4: No Members in Team

```
User: /remove-team-member --team=empty-team

Claude: [Validates team exists]
Claude: [Reads members - finds empty array]

Claude:
No members found in Empty Team.

Use /add-team-members to add members first.
```

### Example 5: Team Not Found

```
User: /remove-team-member --team=nonexistent

Claude:
Error: Team 'nonexistent' not found.

Run /list-teams to see available teams.
```

## Implementation Notes

### Working Directory

All commands should be run from the repository root. Member data is stored in `.team/<team-id>/members.json`.

### Member Identification

- Members are identified by their **email address** (unique per team)
- The `remove_member` bash utility uses email to find and remove the member
- Always extract the email from the selected member object before calling `remove_member`

### Reading Members with jq

To parse members for the AskUserQuestion options:

```bash
# Read all members as separate JSON objects
members=$(jq -c '.[]' .team/<team-id>/members.json)

# Loop through each member
while IFS= read -r member; do
  name=$(echo "$member" | jq -r '.name')
  email=$(echo "$member" | jq -r '.email')
  role=$(echo "$member" | jq -r '.role')

  # Build option: Label="$name", Description="$email - $role"
done <<< "$members"
```

### Cancel Option

Always provide a "Cancel" option in the member selection to allow users to exit without removing anyone.

### Confirmation Step

Always confirm the removal before executing it. This prevents accidental deletions.

### Display Member Details

After successful removal, display the removed member's details so the user has a record of what was deleted.

## Success Criteria

The skill is successful when:
1. Team existence is validated before proceeding
2. Current members are read and displayed correctly
3. AskUserQuestion tool is used for member selection (not plain text)
4. Cancel option allows user to exit at selection stage
5. AskUserQuestion tool is used for confirmation (not plain text)
6. Cancel option allows user to exit at confirmation stage
7. Member is removed from members.json by email
8. Confirmation message displays removed member details
9. Remaining member count is shown
10. All errors are handled gracefully with helpful messages

## Related Skills

- `/team-init` - Create a new team
- `/list-teams` - View all teams
- `/add-team-members` - Add members to a team

## Script Dependencies

This skill depends on these utility scripts:
- `./scripts/utils/file-ops.sh` - For validating team existence
- `./scripts/utils/json-utils.sh` - For removing members from members.json

Verify these exist before execution if troubleshooting is needed.
