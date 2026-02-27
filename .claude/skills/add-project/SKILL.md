---
name: add-project
description: Add a project to a team
user-invocable: true
---

# Add Project Skill

This skill adds a project to an existing team in the repository-based team management system.

## Usage

```
/add-project --team=<team-id>
```

### Parameters

- `--team` (required): The team ID to add the project to (e.g., `team-alpha`, `engineering-team`)

## Instructions

When this skill is invoked, follow these steps:

### Step 1: Parse and Validate Team Parameter

Extract the `--team` parameter from the command arguments.

**Error Handling:**
- If `--team` is missing, ask the user: "Which team would you like to add a project to?"
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

### Step 4: Collect Project Information

Ask the user to provide project details in plain text:

**Prompt:**
```
Please provide the project details:

Required:
- Project name:

Optional (press Enter to skip):
- Repository URL:
- Description:
```

**Parse the response** to extract:
- **Project name** (required) - must not be empty
- **Repository URL** (optional) - can be empty
- **Description** (optional) - can be empty

**Validation:**
- Ensure project name is provided and not empty
- If project name is missing, ask again
- Repository URL and description can be empty/null

### Step 5: Select Project Status

**Use the `AskUserQuestion` tool** to ask for project status:

**IMPORTANT: Always use AskUserQuestion tool, never ask in plain text**

```
AskUserQuestion parameters:
- Question: "What is the status of this project?"
- Header: "Project status"
- Options:
  - Label: "Active"
    Description: "Currently being worked on"
  - Label: "Planned"
    Description: "Planned for future work"
  - Label: "On Hold"
    Description: "Temporarily paused"
  - Label: "Archived"
    Description: "Completed or no longer active"
- multiSelect: false
```

Map the user's selection to lowercase for storage:
- "Active" → "active"
- "Planned" → "planned"
- "On Hold" → "on-hold"
- "Archived" → "archived"

### Step 6: Ask About External Tool Linking

**Use the `AskUserQuestion` tool** to ask which external tools to link:

**IMPORTANT: Always use AskUserQuestion tool, never ask in plain text**

```
AskUserQuestion parameters:
- Question: "Would you like to link this project to external tools?"
- Header: "External tools"
- Options:
  - Label: "Yes, link to external tools"
    Description: "Connect to Jira, GitLab, or Confluence"
  - Label: "No, skip external linking"
    Description: "Create project without external tool links"
- multiSelect: false
```

**If user selects "No, skip external linking":**
- Skip to Step 11 (Generate Project ID)

**If user selects "Yes, link to external tools":**
- Continue to Step 7

### Step 7: Select External Tools to Link

**Use the `AskUserQuestion` tool** to select which tools to link:

```
AskUserQuestion parameters:
- Question: "Which external tools would you like to link?"
- Header: "Select tools"
- Options:
  - Label: "Jira"
    Description: "Link to a Jira board"
  - Label: "GitLab"
    Description: "Link to a GitLab project"
  - Label: "Confluence"
    Description: "Link to a Confluence space"
- multiSelect: true  # Allow selecting multiple tools
```

**Note:** User can select one, multiple, or all tools.

For each selected tool, proceed to the corresponding step:
- If "Jira" selected → Step 8
- If "GitLab" selected → Step 9
- If "Confluence" selected → Step 10

### Step 8: Link Jira Board (if selected)

**Step 8.1: Check Jira MCP Availability**

Check if Jira MCP (or Atlassian MCP) tools are available.

**Important:** The Jira connection is through MCP (Model Context Protocol), not direct API calls.

**Error Handling:**
- If Jira MCP not available, display:
  ```
  Warning: Jira MCP not configured.

  To link Jira boards, you need to configure Jira MCP integration.
  See documentation: docs/setup-jira-mcp.md

  Skipping Jira linking for this project.
  ```
- Continue to next selected tool (or Step 11 if no more tools)

**Step 8.2: Search for Jira Boards**

Ask for search keyword in plain text:
```
Please enter a keyword to search for Jira boards:
(e.g., "engineering", "team-alpha", "sprint")
```

**Step 8.3: Call Jira MCP to Search Boards**

Use Jira MCP to search for boards matching the keyword.

**Error Handling:**
- If MCP call fails, display error and skip Jira linking
- If no boards found, display: "No Jira boards found matching '<keyword>'. Skipping Jira linking."

**Step 8.4: Present Board Options**

**Use the `AskUserQuestion` tool**:
```
AskUserQuestion parameters:
- Question: "Which Jira board would you like to link?"
- Header: "Select board"
- Options: Present each board with format:
  - Label: "<board-name>"
  - Description: "<board-key> - <project-name>"
- Add option:
  - Label: "None"
  - Description: "Skip Jira linking"
- multiSelect: false
```

**If user selects a board:**
- Store the board ID in variable: `jira_board_id="<selected-board-id>"`

**If user selects "None":**
- Skip Jira linking

### Step 9: Link GitLab Project (if selected)

**Step 9.1: Check GitLab MCP Availability**

Check if GitLab MCP tools are available.

**Important:** The GitLab connection is through MCP (Model Context Protocol), not direct API calls.

**Error Handling:**
- If GitLab MCP not available, display warning and skip GitLab linking

**Step 9.2: Search for GitLab Projects**

Ask for search keyword in plain text:
```
Please enter a keyword to search for GitLab projects:
(e.g., "auth-service", "api", "frontend")
```

**Step 9.3: Call GitLab MCP to Search Projects**

Use GitLab MCP to search for projects matching the keyword.

**Error Handling:**
- If MCP call fails, display error and skip GitLab linking
- If no projects found, display: "No GitLab projects found matching '<keyword>'. Skipping GitLab linking."

**Step 9.4: Present Project Options**

**Use the `AskUserQuestion` tool**:
```
AskUserQuestion parameters:
- Question: "Which GitLab project would you like to link?"
- Header: "Select project"
- Options: Present each project with format:
  - Label: "<project-name>"
  - Description: "<namespace>/<project-path>"
- Add option:
  - Label: "None"
  - Description: "Skip GitLab linking"
- multiSelect: false
```

**If user selects a project:**
- Store the project ID in variable: `gitlab_project_id="<selected-project-id>"`

**If user selects "None":**
- Skip GitLab linking

### Step 10: Link Confluence Space (if selected)

**Step 10.1: Check Confluence MCP Availability**

Check if Confluence MCP (or Atlassian MCP) tools are available.

**Important:** The Confluence connection is through MCP (Model Context Protocol), not direct API calls.

**Error Handling:**
- If Confluence MCP not available, display warning and skip Confluence linking

**Step 10.2: Search for Confluence Spaces**

Ask for search keyword in plain text:
```
Please enter a keyword to search for Confluence spaces:
(e.g., "engineering", "docs", "team")
```

**Step 10.3: Call Confluence MCP to Search Spaces**

Use Confluence MCP to search for spaces matching the keyword.

**Error Handling:**
- If MCP call fails, display error and skip Confluence linking
- If no spaces found, display: "No Confluence spaces found matching '<keyword>'. Skipping Confluence linking."

**Step 10.4: Present Space Options**

**Use the `AskUserQuestion` tool**:
```
AskUserQuestion parameters:
- Question: "Which Confluence space would you like to link?"
- Header: "Select space"
- Options: Present each space with format:
  - Label: "<space-name>"
  - Description: "<space-key> - <space-type>"
- Add option:
  - Label: "None"
  - Description: "Skip Confluence linking"
- multiSelect: false
```

**If user selects a space:**
- Store the space key in variable: `confluence_space="<selected-space-key>"`

**If user selects "None":**
- Skip Confluence linking

### Step 11: Generate Project ID

Generate a unique project ID using the ID generator utility:

```bash
bash -c 'source ./scripts/utils/id-generator.sh && generate_project_id'
```

This returns a unique ID in the format: `proj-[timestamp]-[3-random-chars]`

Example: `proj-1709052123-x7m`

### Step 12: Build Project JSON Object

Construct the project JSON object safely using `jq`:

```bash
project_id="<generated-id>"
project_name="<project-name>"
repository_url="<repository-url>"  # Can be empty string
project_description="<description>"  # Can be empty string
project_status="<status>"  # lowercase: active, planned, on-hold, archived
team_id="<team-id>"
created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
updated_at="$created_at"

# Build base project object
project_json=$(jq -n \
  --arg project_id "$project_id" \
  --arg name "$project_name" \
  --arg status "$project_status" \
  --arg team_id "$team_id" \
  --arg created_at "$created_at" \
  --arg updated_at "$updated_at" \
  '{
    project_id: $project_id,
    name: $name,
    status: $status,
    team_id: $team_id,
    created_at: $created_at,
    updated_at: $updated_at
  }')

# Add optional basic fields if provided
if [[ -n "$repository_url" ]]; then
  project_json=$(echo "$project_json" | jq --arg repository_url "$repository_url" \
    '. + {repository_url: $repository_url}')
fi

if [[ -n "$project_description" ]]; then
  project_json=$(echo "$project_json" | jq --arg description "$project_description" \
    '. + {description: $description}')
fi

# Add external tool links if provided
if [[ -n "$jira_board_id" ]]; then
  project_json=$(echo "$project_json" | jq --arg jira_board_id "$jira_board_id" \
    '. + {jira_board_id: $jira_board_id}')
fi

if [[ -n "$gitlab_project_id" ]]; then
  project_json=$(echo "$project_json" | jq --arg gitlab_project_id "$gitlab_project_id" \
    '. + {gitlab_project_id: $gitlab_project_id}')
fi

if [[ -n "$confluence_space" ]]; then
  project_json=$(echo "$project_json" | jq --arg confluence_space "$confluence_space" \
    '. + {confluence_space: $confluence_space}')
fi
```

**Note:** External tool link fields are now supported (jira_board_id, gitlab_project_id, confluence_space). They are only included if linking was performed.

### Step 13: Add Project to Team

Call the JSON utilities to append the project:

```bash
bash -c 'source ./scripts/utils/json-utils.sh && append_project "<team-id>" '"'"'<project-json>'"'"''
```

**Error Handling:**
- If the command fails, display the error message and stop
- The `append_project` function adds the project to projects.json

### Step 14: Update Current Projects Array

Add the project ID to the team's current_projects array:

```bash
bash -c 'source ./scripts/utils/json-utils.sh && update_current_projects "<team-id>" "<project-id>"'
```

**Error Handling:**
- If the command fails, display the error message
- This updates the team-config.json file

### Step 15: Display Confirmation

Show success confirmation with project details:

```
✓ Added project to <team-name>

Project Details:
  ID: <project-id>
  Name: <project-name>
  Status: <status>
  Repository: <repository-url> (or "None" if not provided)
  Description: <description> (or "None" if not provided)
  External Links:
    - Jira Board: <jira_board_id> (or "None")
    - GitLab Project: <gitlab_project_id> (or "None")
    - Confluence Space: <confluence_space> (or "None")
  Created: <created-at>

View all projects: /list-teams
```

## Example Scenarios

### Example 1: Add Project with All Details

```
User: /add-project --team=team-alpha

Claude: [Validates team exists]

Claude: Please provide the project details:

Required:
- Project name:

Optional (press Enter to skip):
- Repository URL:
- Description:

User:
Project name: Authentication Service
Repository URL: https://github.com/company/auth-service
Description: OAuth2 authentication microservice

Claude: What is the status of this project?
[Shows options via AskUserQuestion:]
  - Active (Currently being worked on)
  - Planned (Planned for future work)
  - On Hold (Temporarily paused)
  - Archived (Completed or no longer active)

User: [Selects "Active"]

Claude: [Generates project ID]
Claude: [Builds project JSON]
Claude: [Adds project to projects.json]
Claude: [Updates current_projects array]

Claude:
✓ Added project to Team Alpha

Project Details:
  ID: proj-1709052123-x7m
  Name: Authentication Service
  Status: active
  Repository: https://github.com/company/auth-service
  Description: OAuth2 authentication microservice
  Created: 2026-02-27T17:45:30Z

View all projects: /list-teams
```

### Example 2: Add Project with Minimal Details

```
User: /add-project --team=engineering-team

Claude: Please provide the project details:

User:
Project name: Mobile App Redesign
Repository URL:
Description:

Claude: What is the status of this project?

User: [Selects "Planned"]

Claude:
✓ Added project to Engineering Team

Project Details:
  ID: proj-1709052456-y8n
  Name: Mobile App Redesign
  Status: planned
  Repository: None
  Description: None
  Created: 2026-02-27T17:50:15Z

View all projects: /list-teams
```

### Example 3: Add Archived Project

```
User: /add-project --team=team-beta

Claude: Please provide the project details:

User:
Project name: Legacy API Migration
Repository URL: https://github.com/company/legacy-api
Description: Migrated from monolith to microservices (completed Q4 2025)

Claude: What is the status of this project?

User: [Selects "Archived"]

Claude:
✓ Added project to Team Beta

Project Details:
  ID: proj-1709052789-z9p
  Name: Legacy API Migration
  Status: archived
  Repository: https://github.com/company/legacy-api
  Description: Migrated from monolith to microservices (completed Q4 2025)
  Created: 2026-02-27T17:55:45Z

View all projects: /list-teams
```

### Example 4: Team Not Found

```
User: /add-project --team=nonexistent

Claude:
Error: Team 'nonexistent' not found.

Run /list-teams to see available teams, or /team-init to create a new team.
```

### Example 5: Missing Project Name

```
User: /add-project --team=team-alpha

Claude: Please provide the project details:

User:
Project name:
Repository URL: https://github.com/example/repo

Claude: Error: Project name is required.

Claude: Please provide the project details:

User:
Project name: Example Project
Repository URL: https://github.com/example/repo

Claude: [Continues with status selection...]
```

## Implementation Notes

### Working Directory

All commands should be run from the repository root. Project data is stored in `.team/<team-id>/projects.json`.

### Project JSON Schema (Basic Version)

The basic project object includes:

**Required fields:**
- `project_id` - Unique identifier (generated)
- `name` - Project name
- `status` - One of: active, planned, on-hold, archived
- `team_id` - The team this project belongs to
- `created_at` - ISO 8601 timestamp
- `updated_at` - ISO 8601 timestamp

**Optional fields:**
- `repository_url` - Git repository URL (if provided)
- `description` - Project description (if provided)

**NOT included in basic version:**
- `jira_board_id` - Will be added in Slice 8
- `gitlab_project_id` - Will be added in Slice 8
- `confluence_space` - Will be added in Slice 8

### Status Values

Store status in lowercase:
- `active` - Currently being worked on
- `planned` - Planned for future work
- `on-hold` - Temporarily paused
- `archived` - Completed or no longer active

### Current Projects Tracking

The `update_current_projects` function adds the project ID to the `current_projects` array in team-config.json. This provides quick access to active/current project IDs without reading the full projects.json file.

### Timestamps

Use ISO 8601 format for timestamps:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Both `created_at` and `updated_at` are set to the same value when creating a project.

### JSON Construction Best Practices

Always use `jq -n` to construct JSON safely to prevent injection and ensure proper escaping:

```bash
# Build base object with required fields
project_json=$(jq -n \
  --arg project_id "$project_id" \
  --arg name "$name" \
  ... \
  '{...}')

# Add optional fields conditionally
if [[ -n "$repository_url" ]]; then
  project_json=$(echo "$project_json" | jq --arg repository_url "$repository_url" \
    '. + {repository_url: $repository_url}')
fi
```

### Optional Field Handling

- Check if optional fields (repository_url, description) are provided
- If empty/not provided, don't include them in the JSON
- This keeps the JSON clean and prevents storing empty strings

### User Input Parsing

When asking for project details in plain text:
- Accept flexible formats
- Trim whitespace
- Handle multi-line descriptions
- Allow empty values for optional fields

## Success Criteria

The skill is successful when:
1. Team existence is validated before proceeding
2. Project name is collected and validated (required)
3. Repository URL is collected (optional)
4. Description is collected (optional)
5. AskUserQuestion tool is used for status selection
6. Project ID is generated uniquely
7. Project JSON is built with correct schema (basic version only)
8. Project is added to projects.json
9. Project ID is added to current_projects array in team-config.json
10. Confirmation message displays all project details
11. All errors are handled gracefully with helpful messages

## Related Skills

- `/team-init` - Create a new team
- `/list-teams` - View all teams and their project counts
- `/add-team-members` - Add members to a team

## Script Dependencies

This skill depends on these utility scripts:
- `./scripts/utils/id-generator.sh` - For generating project IDs
- `./scripts/utils/file-ops.sh` - For validating team existence
- `./scripts/utils/json-utils.sh` - For appending projects and updating current_projects

Verify these exist before execution if troubleshooting is needed.

## External Tool Integration

This skill now supports linking projects to external tools via MCP:
- **Jira boards** (via Jira/Atlassian MCP)
- **GitLab projects** (via GitLab MCP)
- **Confluence spaces** (via Confluence/Atlassian MCP)

External tool linking is optional. Projects can be created without any external links. When MCPs are configured, the skill will search and present options from each tool for easy linking.

**MCP Requirements:**
- Jira linking requires Jira MCP or Atlassian MCP
- GitLab linking requires GitLab MCP
- Confluence linking requires Confluence MCP or Atlassian MCP

If an MCP is not configured, the skill will display a warning and skip linking for that tool.
