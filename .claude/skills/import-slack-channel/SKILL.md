---
name: import-slack-channel
description: Import team members from a Slack channel via MCP
user-invocable: true
---

# Import Slack Channel Skill

This skill imports team members from a Slack channel using the Slack MCP (Model Context Protocol) integration.

## Usage

```
/import-slack-channel --team=<team-id>
```

### Parameters

- `--team` (required): The team ID to import members into (e.g., `team-alpha`, `engineering-team`)

## Instructions

When this skill is invoked, follow these steps:

### Step 1: Parse and Validate Team Parameter

Extract the `--team` parameter from the command arguments.

**Error Handling:**
- If `--team` is missing, ask the user: "Which team would you like to import Slack members into?"
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

### Step 3: Check Slack MCP Availability

Check if Slack MCP tools are available by looking for Slack-related MCP tools/functions.

**Important:** The Slack connection is through MCP (Model Context Protocol), not direct API calls.

**Error Handling:**
- If Slack MCP is not available, display error:
  ```
  Error: Slack MCP not configured.

  To use this feature, configure Slack MCP integration.
  See documentation: docs/setup-slack-mcp.md

  Alternative: Use /add-team-members to add members manually.
  ```
- Stop execution if Slack MCP is not available

### Step 4: Get Team Name

Read the team name for display purposes:

```bash
jq -r '.team_name' .team/<team-id>/team-config.json
```

### Step 5: Search for Slack Channels

Ask the user for a channel search keyword in plain text:

**Prompt:**
```
Please enter a keyword to search for Slack channels:
(e.g., "engineering", "team-alpha", "dev")
```

### Step 6: Call Slack MCP to List Channels

Use the Slack MCP to search for channels matching the keyword:

```
Use Slack MCP conversations.list or similar function
Search/filter by the keyword provided by user
```

**Note:** This calls Slack through the MCP (Model Context Protocol) integration.

**Error Handling:**
- If MCP call fails, display error with details
- If no channels found, display:
  ```
  No Slack channels found matching "<keyword>".

  Try a different search term or check your Slack workspace.
  ```
- Stop execution if no channels found

### Step 7: Present Channel Options

**Use the `AskUserQuestion` tool** to present channel options:

**IMPORTANT: Always use AskUserQuestion tool, never ask in plain text**

```
AskUserQuestion parameters:
- Question: "Which Slack channel would you like to import members from?"
- Header: "Select channel"
- Options: Present each matching channel with format:
  - Label: "#<channel-name>"
  - Description: "<member-count> members - <channel-description>"
- Add final option:
  - Label: "Cancel"
  - Description: "Don't import from any channel"
- multiSelect: false
```

**Example:**
```
Options:
  - Label: "#engineering-team"
    Description: "15 members - Engineering team discussions"
  - Label: "#team-alpha"
    Description: "8 members - Team Alpha workspace"
  - Label: "Cancel"
    Description: "Don't import from any channel"
```

**If user selects "Cancel":**
- Display: "Slack import cancelled."
- Stop execution

### Step 8: Get Channel Members

After user selects a channel, call Slack MCP to get all member IDs in that channel:

```
Use Slack MCP conversations.members function
Channel ID: <selected-channel-id>
```

This returns a list of Slack user IDs.

**Error Handling:**
- If MCP call fails, display error and stop
- If channel has no members, display:
  ```
  The selected channel has no members to import.
  ```
- Stop execution if no members

### Step 9: Fetch User Details for Each Member

For each member ID, call Slack MCP to get user profile information:

```
Use Slack MCP users.info function
User ID: <member-id>
```

Extract from the user profile:
- **Name**: user.real_name or user.profile.real_name
- **Email**: user.profile.email (if available)
- **Title/Role**: user.profile.title (if available, otherwise use "Team Member")

**Important:** Not all Slack users have email addresses in their profile. Handle missing emails gracefully.

### Step 10: Build Member JSON Objects

For each Slack user with a valid email:

1. Generate a unique member ID:
   ```bash
   bash -c 'source ./scripts/utils/id-generator.sh && generate_member_id'
   ```

2. Build member JSON object using `jq`:
   ```bash
   member_json=$(jq -n \
     --arg member_id "$member_id" \
     --arg name "$name" \
     --arg email "$email" \
     --arg role "$role" \
     --arg added_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
     --arg source "slack_import" \
     --arg slack_user_id "$slack_user_id" \
     '{
       member_id: $member_id,
       name: $name,
       email: $email,
       role: $role,
       added_at: $added_at,
       source: $source,
       slack_user_id: $slack_user_id
     }')
   ```

**Tracking:**
- Count total Slack users processed
- Count users with valid email addresses
- Count users without email addresses (skip these)

### Step 11: Import Members (with Duplicate Detection)

For each member JSON object, call the JSON utilities to append:

```bash
bash -c 'source ./scripts/utils/json-utils.sh && append_member "<team-id>" '"'"'<member-json>'"'"''
```

**Duplicate Handling:**
- The `append_member` function checks for duplicate emails
- If a member already exists (by email), it returns an error
- Catch these errors and count them as duplicates
- Continue processing remaining members even after duplicates

**Tracking:**
- Count successfully imported members
- Count duplicate members (already exist)

### Step 12: Display Import Summary

Show a comprehensive summary:

```
✓ Slack import complete!

Channel: #<channel-name>
Total Slack users: <total-count>
Successfully imported: <imported-count>
Duplicates skipped: <duplicate-count>
No email address: <no-email-count>

View all members: /list-teams
```

## Example Scenarios

### Example 1: Successful Import with Some Duplicates

```
User: /import-slack-channel --team=team-alpha

Claude: [Validates team exists]
Claude: [Checks Slack MCP - available]

Claude: Please enter a keyword to search for Slack channels:

User: engineering

Claude: [Searches Slack via MCP]
Claude: Which Slack channel would you like to import members from?
[Shows options via AskUserQuestion:]
  - #engineering-team (15 members - Engineering discussions)
  - #engineering-leads (5 members - Engineering leadership)
  - Cancel

User: [Selects "#engineering-team"]

Claude: [Fetches channel members via MCP]
Claude: [Fetches user details for each member via MCP]
Claude: [Imports members one by one]

Claude:
✓ Slack import complete!

Channel: #engineering-team
Total Slack users: 15
Successfully imported: 12
Duplicates skipped: 2
No email address: 1

View all members: /list-teams
```

### Example 2: All Duplicates (Re-importing Same Channel)

```
User: /import-slack-channel --team=team-alpha

Claude: Please enter a keyword to search for Slack channels:

User: engineering

Claude: Which Slack channel would you like to import members from?

User: [Selects "#engineering-team"]

Claude: [Processes members]

Claude:
✓ Slack import complete!

Channel: #engineering-team
Total Slack users: 15
Successfully imported: 0
Duplicates skipped: 14
No email address: 1

All members from this channel are already in the team.

View all members: /list-teams
```

### Example 3: Slack MCP Not Configured

```
User: /import-slack-channel --team=team-alpha

Claude: [Validates team exists]
Claude: [Checks Slack MCP - not available]

Claude:
Error: Slack MCP not configured.

To use this feature, you need to configure Slack MCP integration.
See documentation: docs/setup-slack-mcp.md

Alternative: Use /add-team-members to add members manually.
```

### Example 4: No Channels Found

```
User: /import-slack-channel --team=team-beta

Claude: Please enter a keyword to search for Slack channels:

User: nonexistent

Claude: [Searches Slack via MCP]

Claude:
No Slack channels found matching "nonexistent".

Try a different search term or check your Slack workspace.
```

### Example 5: Cancel During Channel Selection

```
User: /import-slack-channel --team=engineering-team

Claude: Please enter a keyword to search for Slack channels:

User: team

Claude: Which Slack channel would you like to import members from?
[Shows channel options]

User: [Selects "Cancel"]

Claude: Slack import cancelled.
```

## Implementation Notes

### Working Directory

All commands should be run from the repository root. Member data is stored in `.team/<team-id>/members.json`.

### Slack MCP Integration

**Connection:** All Slack operations go through MCP (Model Context Protocol), not direct API calls.

**Required MCP Functions:**
- `conversations.list` - Search/list channels
- `conversations.members` - Get member IDs for a channel
- `users.info` - Get user profile information

**MCP Configuration:** Users must have Slack MCP configured before using this skill. The configuration should be in `~/.claude/mcp.json` or similar.

### Email Handling

- Not all Slack users have email addresses in their profiles
- Only import users with valid email addresses
- Track and report users without email addresses in the summary
- Email is the unique identifier for team members

### Member Source Tracking

Set `source: "slack_import"` for all imported members. This helps distinguish manually added members from Slack imports.

### Slack User ID Storage

Store the Slack user ID (`slack_user_id` field) in the member JSON. This enables future features like syncing member updates from Slack.

### Batch Import Performance

For large channels (50+ members):
- Process members one at a time (don't try to batch)
- Show progress indicator: "Importing members... (<current>/<total>)"
- Handle rate limiting gracefully if Slack MCP has limits

### Duplicate Detection Strategy

The `append_member` bash utility checks for duplicates by email. When it detects a duplicate:
- It returns a non-zero exit code
- It outputs an error message
- Count this as a duplicate and continue

Don't stop the import if one member is a duplicate.

### Error Recovery

- If MCP call fails partway through, report how many members were successfully imported before the failure
- Provide clear error messages for common issues (network errors, permission errors, etc.)
- Allow partial imports to succeed (don't rollback if some members fail)

## Success Criteria

The skill is successful when:
1. Team existence is validated before proceeding
2. Slack MCP availability is checked before attempting import
3. Clear error message shown if Slack MCP not configured
4. Channel search keyword is collected from user
5. AskUserQuestion tool is used for channel selection
6. Cancel option allows user to exit
7. Channel members are fetched via Slack MCP
8. User details are fetched for each member via Slack MCP
9. Members with valid emails are imported
10. Members without emails are tracked and reported
11. Duplicate members are detected and counted (not errors)
12. Import summary shows: total, imported, duplicates, no-email
13. All errors are handled gracefully with helpful messages

## Related Skills

- `/team-init` - Create a new team
- `/list-teams` - View all teams
- `/add-team-members` - Add members manually
- `/remove-team-member` - Remove a member from a team

## Script Dependencies

This skill depends on these utility scripts:
- `./scripts/utils/id-generator.sh` - For generating member IDs
- `./scripts/utils/file-ops.sh` - For validating team existence
- `./scripts/utils/json-utils.sh` - For appending members to members.json

## External Dependencies

This skill requires:
- **Slack MCP** - Must be configured in user's MCP settings
- **Slack Workspace Access** - User must have access to the Slack workspace
- **Email Visibility** - Slack workspace must allow email visibility in user profiles (or users must have public emails)

## Documentation References

- Slack MCP Setup: `docs/setup-slack-mcp.md` (to be created in Phase 3)
- Slack API Documentation: For understanding user profile fields
- MCP Documentation: For understanding Model Context Protocol integration
