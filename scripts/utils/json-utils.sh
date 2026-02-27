#!/usr/bin/env bash
set -euo pipefail

# json-utils.sh - JSON operations utility for team management
# All JSON read/write operations using jq for parsing and manipulation

# Get current ISO 8601 timestamp
# Returns: ISO 8601 formatted timestamp (e.g., 2026-02-27T10:00:00Z)
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Validate JSON content
# Arguments:
#   $1 - JSON content to validate
# Returns: 0 if valid JSON, 1 otherwise
validate_json() {
    local json_content="$1"

    if ! echo "$json_content" | jq empty 2>/dev/null; then
        echo "Error: Invalid JSON content" >&2
        return 1
    fi

    return 0
}

# Write initial JSON files for a new team
# Arguments:
#   $1 - team-id (identifier for the team)
#   $2 - team-name (display name for the team)
# Creates:
#   - .team/[team-id]/team-config.json
#   - .team/[team-id]/members.json
#   - .team/[team-id]/projects.json
# Returns: 0 on success, 1 on failure
write_initial_files() {
    local team_id="${1:?Team ID required}"
    local team_name="${2:?Team name required}"
    local team_dir=".team/${team_id}"
    local timestamp
    timestamp="$(get_timestamp)"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format. Use alphanumeric, underscore, or hyphen only." >&2
        return 1
    fi

    # Check if directory exists
    if [[ ! -d "$team_dir" ]]; then
        echo "Error: Team directory not found: $team_dir" >&2
        return 1
    fi

    # Create team-config.json
    local config_file="${team_dir}/team-config.json"
    local config_json
    config_json=$(jq -n \
        --arg team_id "$team_id" \
        --arg team_name "$team_name" \
        --arg created_at "$timestamp" \
        --arg updated_at "$timestamp" \
        '{
            team_id: $team_id,
            team_name: $team_name,
            created_at: $created_at,
            updated_at: $updated_at,
            current_projects: []
        }')

    if ! validate_json "$config_json"; then
        echo "Error: Failed to create valid team-config.json" >&2
        return 1
    fi

    echo "$config_json" > "${config_file}.temp"
    mv "${config_file}.temp" "$config_file"

    # Create empty members.json
    local members_file="${team_dir}/members.json"
    echo "[]" > "${members_file}.temp"
    mv "${members_file}.temp" "$members_file"

    # Create empty projects.json
    local projects_file="${team_dir}/projects.json"
    echo "[]" > "${projects_file}.temp"
    mv "${projects_file}.temp" "$projects_file"

    return 0
}

# Append a member to members.json
# Arguments:
#   $1 - team-id
#   $2 - member-json (complete JSON object as string)
# Returns: 0 if added, 1 if duplicate email exists
append_member() {
    local team_id="${1:?Team ID required}"
    local member_json="${2:?Member JSON required}"
    local members_file=".team/${team_id}/members.json"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format." >&2
        return 1
    fi

    # Check if members file exists
    if [[ ! -f "$members_file" ]]; then
        echo "Error: Members file not found: $members_file" >&2
        return 1
    fi

    # Validate input JSON
    if ! validate_json "$member_json"; then
        echo "Error: Invalid member JSON provided" >&2
        return 1
    fi

    # Extract email from member JSON
    local member_email
    member_email=$(echo "$member_json" | jq -r '.email')

    if [[ -z "$member_email" || "$member_email" == "null" ]]; then
        echo "Error: Member JSON must contain 'email' field" >&2
        return 1
    fi

    # Check for duplicate email
    if jq -e --arg email "$member_email" '.[] | select(.email == $email)' "$members_file" > /dev/null 2>&1; then
        echo "Error: Member with email '$member_email' already exists" >&2
        return 1
    fi

    # Append member to array
    jq --argjson new "$member_json" '. += [$new]' "$members_file" > "${members_file}.temp"

    # Validate the result
    if ! validate_json "$(cat "${members_file}.temp")"; then
        rm -f "${members_file}.temp"
        echo "Error: Failed to create valid members.json after append" >&2
        return 1
    fi

    mv "${members_file}.temp" "$members_file"
    return 0
}

# Append a project to projects.json
# Arguments:
#   $1 - team-id
#   $2 - project-json (complete JSON object as string)
# Returns: 0 on success, 1 on failure
append_project() {
    local team_id="${1:?Team ID required}"
    local project_json="${2:?Project JSON required}"
    local projects_file=".team/${team_id}/projects.json"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format." >&2
        return 1
    fi

    # Check if projects file exists
    if [[ ! -f "$projects_file" ]]; then
        echo "Error: Projects file not found: $projects_file" >&2
        return 1
    fi

    # Validate input JSON
    if ! validate_json "$project_json"; then
        echo "Error: Invalid project JSON provided" >&2
        return 1
    fi

    # Append project to array
    jq --argjson new "$project_json" '. += [$new]' "$projects_file" > "${projects_file}.temp"

    # Validate the result
    if ! validate_json "$(cat "${projects_file}.temp")"; then
        rm -f "${projects_file}.temp"
        echo "Error: Failed to create valid projects.json after append" >&2
        return 1
    fi

    mv "${projects_file}.temp" "$projects_file"
    return 0
}

# Update current_projects array in team-config.json
# Arguments:
#   $1 - team-id
#   $2 - project-id (to add to current_projects)
# Returns: 0 on success, 1 on failure
update_current_projects() {
    local team_id="${1:?Team ID required}"
    local project_id="${2:?Project ID required}"
    local config_file=".team/${team_id}/team-config.json"
    local timestamp
    timestamp="$(get_timestamp)"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format." >&2
        return 1
    fi

    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Team config file not found: $config_file" >&2
        return 1
    fi

    # Add project_id to current_projects array and update timestamp
    jq --arg project_id "$project_id" \
       --arg updated_at "$timestamp" \
       '.current_projects += [$project_id] | .updated_at = $updated_at' \
       "$config_file" > "${config_file}.temp"

    # Validate the result
    if ! validate_json "$(cat "${config_file}.temp")"; then
        rm -f "${config_file}.temp"
        echo "Error: Failed to create valid team-config.json after update" >&2
        return 1
    fi

    mv "${config_file}.temp" "$config_file"
    return 0
}

# Remove a member from members.json by email
# Arguments:
#   $1 - team-id
#   $2 - member-email
# Returns: 0 if removed, 1 if not found or error
remove_member() {
    local team_id="${1:?Team ID required}"
    local member_email="${2:?Member email required}"
    local members_file=".team/${team_id}/members.json"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format." >&2
        return 1
    fi

    # Check if members file exists
    if [[ ! -f "$members_file" ]]; then
        echo "Error: Members file not found: $members_file" >&2
        return 1
    fi

    # Check if member exists
    if ! jq -e --arg email "$member_email" '.[] | select(.email == $email)' "$members_file" > /dev/null 2>&1; then
        echo "Error: Member with email '$member_email' not found" >&2
        return 1
    fi

    # Remove member from array
    jq --arg email "$member_email" 'map(select(.email != $email))' "$members_file" > "${members_file}.temp"

    # Validate the result
    if ! validate_json "$(cat "${members_file}.temp")"; then
        rm -f "${members_file}.temp"
        echo "Error: Failed to create valid members.json after removal" >&2
        return 1
    fi

    mv "${members_file}.temp" "$members_file"
    return 0
}

# Read team-config.json and output to stdout
# Arguments:
#   $1 - team-id
# Returns: 0 on success, 1 on failure
# Outputs: JSON content to stdout
read_team_config() {
    local team_id="${1:?Team ID required}"
    local config_file=".team/${team_id}/team-config.json"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format." >&2
        return 1
    fi

    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Team config file not found: $config_file" >&2
        return 1
    fi

    # Output file content
    cat "$config_file"
    return 0
}

# Read members.json and output to stdout
# Arguments:
#   $1 - team-id
# Returns: 0 on success, 1 on failure
# Outputs: JSON content to stdout
read_members() {
    local team_id="${1:?Team ID required}"
    local members_file=".team/${team_id}/members.json"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format." >&2
        return 1
    fi

    # Check if members file exists
    if [[ ! -f "$members_file" ]]; then
        echo "Error: Members file not found: $members_file" >&2
        return 1
    fi

    # Output file content
    cat "$members_file"
    return 0
}

# Read projects.json and output to stdout
# Arguments:
#   $1 - team-id
# Returns: 0 on success, 1 on failure
# Outputs: JSON content to stdout
read_projects() {
    local team_id="${1:?Team ID required}"
    local projects_file=".team/${team_id}/projects.json"

    # Validate team_id format
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format." >&2
        return 1
    fi

    # Check if projects file exists
    if [[ ! -f "$projects_file" ]]; then
        echo "Error: Projects file not found: $projects_file" >&2
        return 1
    fi

    # Output file content
    cat "$projects_file"
    return 0
}
