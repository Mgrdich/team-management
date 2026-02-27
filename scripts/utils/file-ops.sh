#!/usr/bin/env bash
set -euo pipefail

# file-ops.sh - File and directory operations for team management system
#
# This script provides utilities for managing team directory structures
# under the .team/ directory.
#
# Functions:
#   create_team_structure <team-id> - Creates team directory structure
#   validate_team_exists <team-id>  - Validates team directory exists
#   list_teams                      - Lists all team IDs

# Base directory for all team configurations
readonly TEAM_BASE_DIR=".team"

# create_team_structure - Creates the directory structure for a team
#
# Usage: create_team_structure <team-id>
#
# Arguments:
#   team-id - The unique identifier for the team
#
# Returns:
#   0 - Success (directory created or already exists)
#   1 - Error (invalid input or creation failed)
#
# Examples:
#   create_team_structure "engineering"
#   create_team_structure "product-team"
create_team_structure() {
    local team_id="${1:-}"

    # Validate input
    if [[ -z "$team_id" ]]; then
        echo "Error: Team ID is required" >&2
        return 1
    fi

    # Validate team ID format (alphanumeric, dash, underscore only)
    if [[ ! "$team_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid team ID format. Use only alphanumeric, dash, and underscore characters." >&2
        return 1
    fi

    # Check for path traversal attempts
    if [[ "$team_id" == *".."* ]]; then
        echo "Error: Invalid team ID. Path traversal not allowed." >&2
        return 1
    fi

    local team_dir="${TEAM_BASE_DIR}/${team_id}"

    # Create directory with parent directories (-p flag)
    if ! mkdir -p "$team_dir" 2>/dev/null; then
        echo "Error: Failed to create directory: $team_dir" >&2
        return 1
    fi

    return 0
}

# validate_team_exists - Checks if a team directory exists
#
# Usage: validate_team_exists <team-id>
#
# Arguments:
#   team-id - The unique identifier for the team
#
# Returns:
#   0 - Team directory exists
#   1 - Team directory does not exist or is not a directory
#
# Examples:
#   if validate_team_exists "engineering"; then
#       echo "Team exists"
#   fi
validate_team_exists() {
    local team_id="${1:-}"

    # Validate input
    if [[ -z "$team_id" ]]; then
        echo "Error: Team ID is required" >&2
        return 1
    fi

    # Check for path traversal attempts
    if [[ "$team_id" == *".."* ]]; then
        echo "Error: Invalid team ID. Path traversal not allowed." >&2
        return 1
    fi

    local team_dir="${TEAM_BASE_DIR}/${team_id}"

    # Check if path exists and is a directory
    if [[ -d "$team_dir" ]]; then
        return 0
    else
        return 1
    fi
}

# list_teams - Lists all team IDs
#
# Usage: list_teams
#
# Outputs:
#   One team ID per line (to stdout)
#   Empty output if no teams exist
#
# Returns:
#   0 - Success (even if no teams found)
#
# Examples:
#   list_teams
#   team_count=$(list_teams | wc -l)
list_teams() {
    # If base directory doesn't exist, return silently
    if [[ ! -d "$TEAM_BASE_DIR" ]]; then
        return 0
    fi

    # Find all directories (depth 1) under .team/, extract basename
    # Use -mindepth/-maxdepth to only get immediate subdirectories
    # Use -type d to only get directories
    # Use -print0 and read -d '' for safe handling of special characters
    while IFS= read -r -d '' team_dir; do
        # Extract team ID (basename of the directory)
        local team_id
        team_id=$(basename "$team_dir")
        echo "$team_id"
    done < <(find "$TEAM_BASE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

    return 0
}

# If script is executed directly (not sourced), show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cat <<EOF
Usage: source ${0} or . ${0}

This script provides file operation utilities for team management.
Source this script to use the following functions:

  create_team_structure <team-id>  Create team directory structure
  validate_team_exists <team-id>   Check if team directory exists
  list_teams                       List all team IDs

Examples:
  source ${0}
  create_team_structure "engineering"
  validate_team_exists "engineering" && echo "Team exists"
  list_teams
EOF
fi
