---
name: add-team-members
description: Add one or more team members manually to a team
user-invocable: true
---

# Add Team Members Skill

This skill adds team members manually to an existing team in the repository-based team management system. You can add members one at a time, and optionally continue adding more in a loop.

## Usage

```
/add-team-members --team=<team-id>
```

### Parameters

- `--team` (required): The team ID to add members to (e.g., `team-alpha`, `engineering-team`)

## Instructions

When this skill is invoked, follow these steps:

### Step 1: Parse and Validate Team Parameter

Extract the `--team` parameter from the command arguments.

**Error Handling:**
- If `--team` is missing, ask the user: "Which team would you like to add members to?"
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

  Run /list-teams to see available teams, or /team-init to create a new team.
  ```
- Stop execution if team doesn't exist

### Step 3: Get Team Name

Read the team name for display purposes:

```bash
jq -r '.team_name' .team/<team-id>/team-config.json
```

### Step 4: Begin Member Addition Loop

Initialize a counter for tracking added members. Then start the member addition loop.

### Step 5: Collect Member Information

For each member, ask the user to provide the following information in plain text:

**Prompt the user:**
```
Please provide the member details (one per line):
- Name:
- Email:
- Role:
```

**Parse the response** to extract:
- Name (required)
- Email (required)
- Role/Title (required)

**Validation:**
- Ensure all three fields are provided
- Ensure email is not empty
- If any field is missing, ask again

### Step 6: Search GitLab for Member via MCP (Auto-populate Git Info)

Attempt to automatically find the member's GitLab account based on their name using the GitLab MCP (Model Context Protocol) integration.

**Step 6.1: Check GitLab MCP Availability**

Check if GitLab MCP tools are available by looking for the `gitlab_` tool prefix in the available MCP tools.

**Important:** The GitLab connection is through MCP (Model Context Protocol), not direct API calls.

**Step 6.2: Search GitLab by Name via MCP**

If GitLab MCP is available:

1. Extract first and last name from the member's full name
   - Example: "John Doe" → first: "John", last: "Doe"

2. Search for GitLab users matching the name via MCP:
   ```
   Use the GitLab MCP search_users tool/function if available
   Search query: "<first-name> <last-name>"

   Note: This calls GitLab through the MCP (Model Context Protocol) integration,
   not through direct API calls.
   ```

3. If results are found, **use the `AskUserQuestion` tool** to present options:

   **IMPORTANT: Always use AskUserQuestion tool, never ask in plain text**

   ```
   AskUserQuestion parameters:
   - Question: "Is this the correct GitLab account for <member-name>?"
   - Header: "GitLab user"
   - Options: Present each matching user from GitLab MCP with format:
     - Label: "<username>"
     - Description: "<full-name> - <email>"
   - Add final option:
     - Label: "None of these"
     - Description: "Skip GitLab integration or enter manually"
   - multiSelect: false
   ```

4. If user selects a GitLab user:
   - Extract `username` as `git_username`
   - Extract `email` as `git_email`
   - Display confirmation: "✓ Linked to GitLab: @<username>"

5. If user selects "None of these" or search returns no results:

   **Use the `AskUserQuestion` tool**:
   ```
   - Question: "Would you like to manually enter Git information for <member-name>?"
   - Header: "Manual Git"
   - Options:
     - Label: "Yes"
     - Description: "Manually enter git username and email"
     - Label: "No"
     - Description: "Skip git information"
   - multiSelect: false
   ```

   - If yes, prompt in plain text for git username and git email
   - If no, skip git information

**Step 6.3: Fallback (No GitLab MCP)**

If GitLab MCP is not available:

**Error Handling:**
- If GitLab MCP is not available, display error:
  ```
  Error: GitLab MCP not configured.

  To use this feature, configure GitLab MCP integration.
  See documentation: docs/setup-gitlab-mcp.md

  GitLab auto-detection unavailable. You can manually enter Git information.
  ```

**Use the `AskUserQuestion` tool**:
```
AskUserQuestion parameters:
- Question: "Would you like to manually add Git information for this member?"
- Header: "Git info"
- Options:
  - Label: "Yes"
    Description: "Manually enter git username and email"
  - Label: "No"
    Description: "Skip git information"
- multiSelect: false
```

If user selects "Yes", prompt in plain text for:
```
Please provide Git information:
- Git username:
- Git email:
```

**Error Handling:**
- If GitLab MCP call fails, fall back to manual entry option
- If search times out, notify user and offer manual entry

### Step 7: Generate Member ID

Generate a unique member ID using the ID generator utility:

```bash
bash -c 'source ./scripts/utils/id-generator.sh && generate_member_id'
```

This returns a unique ID in the format: `mem-[timestamp]-[3-random-chars]`

### Step 8: Build Member JSON Object

Construct the member JSON object safely using `jq`:

```bash
member_id="<generated-id>"
name="<name>"
email="<email>"
role="<role>"
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

member_json=$(jq -n \
  --arg member_id "$member_id" \
  --arg name "$name" \
  --arg email "$email" \
  --arg role "$role" \
  --arg added_at "$timestamp" \
  --arg source "manual" \
  '{
    member_id: $member_id,
    name: $name,
    email: $email,
    role: $role,
    added_at: $added_at,
    source: $source
  }')
```

**If git information was provided**, add it to the JSON:

```bash
member_json=$(echo "$member_json" | jq \
  --arg git_username "$git_username" \
  --arg git_email "$git_email" \
  '. + {git_username: $git_username, git_email: $git_email}')
```

### Step 9: Add Member to Team

Call the JSON utilities to append the member:

```bash
bash -c 'source ./scripts/utils/json-utils.sh && append_member "<team-id>" '"'"'<member-json>'"'"''
```

**Error Handling:**
- If the command fails with "already exists" message, display:
  ```
  Error: A member with email '<email>' already exists in this team.

  Each team member must have a unique email address.
  ```
  Then continue to Step 10 (ask about adding another)
- If the command fails for other reasons, display the error and stop

### Step 10: Display Confirmation for This Member

Show a brief confirmation:

```
✓ Added <member-name> (<member-email>) as <role>
```

Increment the added members counter.

### Step 11: Ask About Adding Another Member

**Use the `AskUserQuestion` tool**:

```
AskUserQuestion parameters:
- Question: "Would you like to add another member to <team-name>?"
- Header: "Add more"
- Options:
  - Label: "Yes"
    Description: "Add another team member"
  - Label: "No"
    Description: "Finish adding members"
- multiSelect: false
```

**If "Yes"**: Go back to Step 5 (collect next member information)

**If "No"**: Continue to Step 12 (final summary)

### Step 12: Display Final Summary

After the loop ends, display a summary:

```
✓ Member addition complete!

Added <count> member(s) to <team-name>

View all members: /list-teams
```

## Example Scenarios

### Example 1: Add Single Member (GitLab MCP Auto-Detection)

```
User: /add-team-members --team=team-alpha

Claude: Please provide the member details (one per line):
- Name:
- Email:
- Role:

User:
Name: John Doe
Email: john@example.com
Role: Senior Engineer

Claude: [Searches GitLab via MCP for "John Doe"]
Claude: Is this the correct GitLab account for John Doe?
[Shows options from GitLab MCP:]
  - jdoe (John Doe - jdoe@company.com)
  - johndoe (J. Doe - john.doe@company.com)
  - None of these

User: [Selects "jdoe"]

Claude: ✓ Linked to GitLab: @jdoe (via MCP)
Claude: ✓ Added John Doe (john@example.com) as Senior Engineer

Claude: Would you like to add another member to Team Alpha?
[Shows options: Yes / No]

User: [Selects "No"]

Claude:
✓ Member addition complete!

Added 1 member(s) to Team Alpha

View all members: /list-teams
```

### Example 2: Add Multiple Members in Loop

```
User: /add-team-members --team=engineering-team

Claude: [Asks for first member details]

User:
Name: Jane Smith
Email: jane@example.com
Role: Tech Lead

Claude: [Asks about git info - user says Yes]

User:
Git username: jsmith
Git email: jsmith@github.com

Claude: ✓ Added Jane Smith (jane@example.com) as Tech Lead

Claude: Would you like to add another member to Engineering Team?

User: [Selects "Yes"]

Claude: [Asks for second member details]

User:
Name: Bob Johnson
Email: bob@example.com
Role: Engineer

Claude: [Asks about git info - user says No]

Claude: ✓ Added Bob Johnson (bob@example.com) as Engineer

Claude: Would you like to add another member to Engineering Team?

User: [Selects "No"]

Claude:
✓ Member addition complete!

Added 2 member(s) to Engineering Team

View all members: /list-teams
```

### Example 3: Duplicate Email Error (Continue After Error)

```
User: /add-team-members --team=team-alpha

User: [Provides details with email: john@example.com]

Claude:
Error: A member with email 'john@example.com' already exists in this team.

Each team member must have a unique email address.

Claude: Would you like to add another member to Team Alpha?
[Shows options: Yes / No]

User: [Selects "Yes" to try with different email]

User: [Provides details with email: jane@example.com]

Claude: ✓ Added Jane Doe (jane@example.com) as Engineer

Claude: Would you like to add another member to Team Alpha?

User: [Selects "No"]

Claude:
✓ Member addition complete!

Added 1 member(s) to Team Alpha

View all members: /list-teams
```

## Implementation Notes

### Working Directory

All commands should be run from the repository root. Member data is stored in `.team/<team-id>/members.json`.

### Loop Management

- Track the number of successfully added members (not just attempts)
- Only increment the counter when `append_member` succeeds
- Continue the loop even after errors (duplicate email, etc.)
- The loop ends only when user explicitly chooses "No" to adding another member

### JSON Construction Best Practices

Always use `jq -n` to construct JSON safely:

```bash
# Base member object
member_json=$(jq -n \
  --arg member_id "$member_id" \
  --arg name "$name" \
  --arg email "$email" \
  --arg role "$role" \
  --arg added_at "$timestamp" \
  --arg source "manual" \
  '{
    member_id: $member_id,
    name: $name,
    email: $email,
    role: $role,
    added_at: $added_at,
    source: $source
  }')

# Add git info if provided
if [[ -n "$git_username" ]]; then
  member_json=$(echo "$member_json" | jq \
    --arg git_username "$git_username" \
    --arg git_email "$git_email" \
    '. + {git_username: $git_username, git_email: $git_email}')
fi
```

### Email Validation

The `append_member` bash utility handles duplicate email detection. You don't need to validate email format, but you should ensure the email is not empty before attempting to add.

### User Input Parsing

When asking for member details in plain text:
- Accept flexible formats (e.g., "Name: John" or "john" after "Name:")
- Trim whitespace
- Handle multi-line responses
- Ask for re-entry if parsing fails

### Error Recovery

- If duplicate email error occurs, don't stop the skill
- Ask if they want to add another member (giving them a chance to correct the email)
- Only fatal errors (team not found, script failures) should stop execution

## Success Criteria

The skill is successful when:
1. Team existence is validated before proceeding
2. Members can be added one at a time in a loop
3. All required information is collected for each member (name, email, role)
4. Optional git information can be added per member
5. Each member gets a unique ID generated
6. Members are added to members.json with correct schema
7. Duplicate emails are rejected but loop continues
8. User can choose to add another member or finish
9. Final summary shows total count of successfully added members
10. All errors are handled gracefully without breaking the loop

## Related Skills

- `/team-init` - Create a new team
- `/list-teams` - View all teams
- `/remove-team-member` - Remove a member from a team
- `/list-team-members` - View all members in a team (to be implemented)

## Script Dependencies

This skill depends on these utility scripts:
- `./scripts/utils/id-generator.sh` - For generating member IDs
- `./scripts/utils/file-ops.sh` - For validating team existence
- `./scripts/utils/json-utils.sh` - For appending members to members.json

Verify these exist before execution if troubleshooting is needed.
