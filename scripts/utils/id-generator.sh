#!/usr/bin/env bash
set -euo pipefail

# ID Generator Utility
#
# This script provides utility functions for generating consistent IDs used
# throughout the team management system.
#
# Functions:
#   team_name_to_id <name>  - Converts team name to kebab-case ID (max 63 chars)
#   generate_member_id      - Generates unique member ID: mem-[timestamp]-[3-random-chars]
#   generate_project_id     - Generates unique project ID: proj-[timestamp]-[3-random-chars]

# =============================================================================
# team_name_to_id - Convert team name to kebab-case ID
# =============================================================================
# Converts a human-readable team name to a filesystem-safe kebab-case ID.
# - Strips special characters
# - Converts to lowercase
# - Replaces spaces with hyphens
# - Limits to 63 characters
#
# Usage: team_name_to_id "Team Alpha"
# Output: team-alpha
#
team_name_to_id() {
    local name="${1:?Team name required}"
    local id

    # Step 1: Convert to lowercase
    id=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')

    # Step 2: Replace spaces with single hyphen (handle multiple spaces)
    id=$(printf '%s' "$id" | tr -s ' ' '-')

    # Step 3: Keep only alphanumeric characters and hyphens (strip special chars, unicode, emoji)
    id=$(printf '%s' "$id" | tr -cd 'a-z0-9-')

    # Step 4: Collapse multiple consecutive hyphens to single hyphen
    id=$(printf '%s' "$id" | tr -s '-')

    # Step 5: Trim leading hyphens
    id=$(printf '%s' "$id" | sed 's/^-*//')

    # Step 6: Trim trailing hyphens
    id=$(printf '%s' "$id" | sed 's/-*$//')

    # Step 7: Truncate to 63 characters (filesystem safe)
    id=$(printf '%s' "$id" | cut -c1-63)

    # Step 8: Trim trailing hyphens again (in case truncation left trailing hyphen)
    id=$(printf '%s' "$id" | sed 's/-*$//')

    # Step 9: Validate result is not empty
    if [[ -z "$id" ]]; then
        echo "Error: Team name must contain at least one alphanumeric character" >&2
        return 1
    fi

    printf '%s\n' "$id"
}

# =============================================================================
# generate_member_id - Generate unique member ID
# =============================================================================
# Generates a unique member identifier with format: mem-[timestamp]-[3-random-chars]
# - Uses current Unix timestamp for uniqueness
# - Appends 3 random lowercase characters
#
# Usage: generate_member_id
# Output: mem-1709123456-abc
#
generate_member_id() {
    local timestamp
    local random_chars

    # Get current Unix timestamp
    timestamp=$(date +%s)

    # Generate 3 random lowercase letters using /dev/urandom
    # - Read random bytes from /dev/urandom
    # - Filter to keep only lowercase letters a-z
    # - Take first 3 characters
    # Note: head causes SIGPIPE which is expected and harmless, so suppress it
    random_chars=$(LC_ALL=C tr -dc 'a-z' < /dev/urandom 2>/dev/null | head -c 3 2>/dev/null || true)

    # Validate that we got exactly 3 characters
    if [[ ${#random_chars} -ne 3 ]]; then
        echo "Error: Failed to generate random characters" >&2
        return 1
    fi

    # Output the generated ID
    printf 'mem-%s-%s\n' "$timestamp" "$random_chars"
}

# =============================================================================
# generate_project_id - Generate unique project ID
# =============================================================================
# Generates a unique project identifier with format: proj-[timestamp]-[3-random-chars]
# - Uses current Unix timestamp for uniqueness
# - Appends 3 random lowercase characters
#
# Usage: generate_project_id
# Output: proj-1709123456-xyz
#
generate_project_id() {
    local timestamp
    local random_chars

    # Get current Unix timestamp
    timestamp=$(date +%s)

    # Generate 3 random lowercase letters using /dev/urandom
    # - Read random bytes from /dev/urandom
    # - Filter to keep only lowercase letters a-z
    # - Take first 3 characters
    # Note: head causes SIGPIPE which is expected and harmless, so suppress it
    random_chars=$(LC_ALL=C tr -dc 'a-z' < /dev/urandom 2>/dev/null | head -c 3 2>/dev/null || true)

    # Validate that we got exactly 3 characters
    if [[ ${#random_chars} -ne 3 ]]; then
        echo "Error: Failed to generate random characters" >&2
        return 1
    fi

    # Output the generated ID
    printf 'proj-%s-%s\n' "$timestamp" "$random_chars"
}
