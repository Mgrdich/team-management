#!/usr/bin/env bats

# Test suite for file-ops.sh
# Tests file and directory operations for team management

# Setup: Create temporary directory for tests and load script
setup() {
    # Create a unique temp directory for each test
    export TEST_TEMP_DIR="$(mktemp -d)"

    # Change to temp directory
    cd "$TEST_TEMP_DIR"

    # Load the file-ops script
    source "${BATS_TEST_DIRNAME}/../../scripts/utils/file-ops.sh"
}

# Teardown: Clean up temporary directory
teardown() {
    # Return to original directory
    cd /

    # Remove temp directory if it exists
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# =============================================================================
# Tests for create_team_structure function
# =============================================================================

@test "create_team_structure: creates team directory with valid team ID" {
    run create_team_structure "engineering"
    [ "$status" -eq 0 ]
    [ -d ".team/engineering" ]
}

@test "create_team_structure: creates directory with hyphenated team ID" {
    run create_team_structure "product-team"
    [ "$status" -eq 0 ]
    [ -d ".team/product-team" ]
}

@test "create_team_structure: creates directory with underscore in team ID" {
    run create_team_structure "dev_team"
    [ "$status" -eq 0 ]
    [ -d ".team/dev_team" ]
}

@test "create_team_structure: creates directory with mixed case team ID" {
    run create_team_structure "TeamAlpha"
    [ "$status" -eq 0 ]
    [ -d ".team/TeamAlpha" ]
}

@test "create_team_structure: creates directory with numeric team ID" {
    run create_team_structure "team123"
    [ "$status" -eq 0 ]
    [ -d ".team/team123" ]
}

@test "create_team_structure: creates .team parent directory if it doesn't exist" {
    # Ensure .team doesn't exist
    [ ! -d ".team" ]

    run create_team_structure "engineering"
    [ "$status" -eq 0 ]
    [ -d ".team" ]
    [ -d ".team/engineering" ]
}

@test "create_team_structure: succeeds when team directory already exists" {
    # Create directory first
    mkdir -p ".team/engineering"

    # Should succeed idempotently
    run create_team_structure "engineering"
    [ "$status" -eq 0 ]
    [ -d ".team/engineering" ]
}

@test "create_team_structure: fails with empty team ID" {
    run create_team_structure ""
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team ID is required" ]]
}

@test "create_team_structure: fails when no argument provided" {
    run create_team_structure
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team ID is required" ]]
}

@test "create_team_structure: fails with path traversal attempt (..)" {
    run create_team_structure "../etc"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Path traversal not allowed" ]]
}

@test "create_team_structure: fails with path traversal in middle of ID" {
    run create_team_structure "team/../etc"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Path traversal not allowed" ]]
}

@test "create_team_structure: fails with special characters (spaces)" {
    run create_team_structure "team name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid team ID format" ]]
}

@test "create_team_structure: fails with special characters (slashes)" {
    run create_team_structure "team/name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid team ID format" ]]
}

@test "create_team_structure: fails with special characters (asterisk)" {
    run create_team_structure "team*"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid team ID format" ]]
}

@test "create_team_structure: fails with special characters (question mark)" {
    run create_team_structure "team?"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid team ID format" ]]
}

# =============================================================================
# Tests for validate_team_exists function
# =============================================================================

@test "validate_team_exists: returns 0 for existing team directory" {
    # Create team directory first
    mkdir -p ".team/engineering"

    run validate_team_exists "engineering"
    [ "$status" -eq 0 ]
}

@test "validate_team_exists: returns 1 for non-existing team directory" {
    run validate_team_exists "nonexistent"
    [ "$status" -eq 1 ]
}

@test "validate_team_exists: returns 1 when .team directory doesn't exist" {
    # Ensure .team doesn't exist
    [ ! -d ".team" ]

    run validate_team_exists "engineering"
    [ "$status" -eq 1 ]
}

@test "validate_team_exists: fails with empty team ID" {
    run validate_team_exists ""
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team ID is required" ]]
}

@test "validate_team_exists: fails when no argument provided" {
    run validate_team_exists
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team ID is required" ]]
}

@test "validate_team_exists: fails with path traversal attempt" {
    run validate_team_exists "../etc"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Path traversal not allowed" ]]
}

@test "validate_team_exists: returns 1 when path exists but is not a directory" {
    # Create .team directory
    mkdir -p ".team"

    # Create a file instead of directory
    touch ".team/notadir"

    run validate_team_exists "notadir"
    [ "$status" -eq 1 ]
}

@test "validate_team_exists: works with hyphenated team ID" {
    mkdir -p ".team/product-team"

    run validate_team_exists "product-team"
    [ "$status" -eq 0 ]
}

@test "validate_team_exists: works with underscore in team ID" {
    mkdir -p ".team/dev_team"

    run validate_team_exists "dev_team"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Tests for list_teams function
# =============================================================================

@test "list_teams: returns empty output when no teams exist" {
    # .team directory doesn't exist
    run list_teams
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "list_teams: returns empty output when .team directory is empty" {
    # Create empty .team directory
    mkdir -p ".team"

    run list_teams
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "list_teams: lists single team" {
    mkdir -p ".team/engineering"

    run list_teams
    [ "$status" -eq 0 ]
    [ "$output" = "engineering" ]
}

@test "list_teams: lists multiple teams" {
    mkdir -p ".team/engineering"
    mkdir -p ".team/product"
    mkdir -p ".team/design"

    run list_teams
    [ "$status" -eq 0 ]

    # Output should contain all three teams
    echo "$output" | grep -q "engineering"
    echo "$output" | grep -q "product"
    echo "$output" | grep -q "design"

    # Should have exactly 3 lines
    [ "$(echo "$output" | wc -l)" -eq 3 ]
}

@test "list_teams: outputs one team per line" {
    mkdir -p ".team/team1"
    mkdir -p ".team/team2"

    run list_teams
    [ "$status" -eq 0 ]

    # Count lines
    local line_count=$(echo "$output" | wc -l)
    [ "$line_count" -eq 2 ]
}

@test "list_teams: ignores files in .team directory" {
    mkdir -p ".team"
    mkdir -p ".team/engineering"

    # Create a file in .team
    touch ".team/README.md"

    run list_teams
    [ "$status" -eq 0 ]

    # Should only list the directory, not the file
    [ "$output" = "engineering" ]
}

@test "list_teams: ignores hidden directories" {
    mkdir -p ".team/engineering"
    mkdir -p ".team/.hidden"

    run list_teams
    [ "$status" -eq 0 ]

    # Should not list hidden directory
    echo "$output" | grep -v ".hidden"
    [ "$output" = "engineering" ]
}

@test "list_teams: does not list nested subdirectories" {
    mkdir -p ".team/engineering"
    mkdir -p ".team/engineering/subteam"

    run list_teams
    [ "$status" -eq 0 ]

    # Should only list top-level directory
    [ "$output" = "engineering" ]
    echo "$output" | grep -v "subteam"
}

@test "list_teams: lists teams in sorted order" {
    # Create teams in non-alphabetical order
    mkdir -p ".team/zebra"
    mkdir -p ".team/alpha"
    mkdir -p ".team/beta"

    run list_teams
    [ "$status" -eq 0 ]

    # Check output is sorted
    local expected="alpha
beta
zebra"
    [ "$output" = "$expected" ]
}

@test "list_teams: handles team names with hyphens" {
    mkdir -p ".team/product-team"
    mkdir -p ".team/dev-ops"

    run list_teams
    [ "$status" -eq 0 ]

    echo "$output" | grep -q "product-team"
    echo "$output" | grep -q "dev-ops"
}

@test "list_teams: handles team names with underscores" {
    mkdir -p ".team/dev_team"
    mkdir -p ".team/qa_team"

    run list_teams
    [ "$status" -eq 0 ]

    echo "$output" | grep -q "dev_team"
    echo "$output" | grep -q "qa_team"
}

@test "list_teams: handles team names with numbers" {
    mkdir -p ".team/team1"
    mkdir -p ".team/team2"
    mkdir -p ".team/team10"

    run list_teams
    [ "$status" -eq 0 ]

    echo "$output" | grep -q "team1"
    echo "$output" | grep -q "team2"
    echo "$output" | grep -q "team10"
}

@test "list_teams: handles special directory names safely" {
    mkdir -p ".team/team-with-many-hyphens"
    mkdir -p ".team/team_with_underscores"
    mkdir -p ".team/UPPERCASE"

    run list_teams
    [ "$status" -eq 0 ]

    echo "$output" | grep -q "team-with-many-hyphens"
    echo "$output" | grep -q "team_with_underscores"
    echo "$output" | grep -q "UPPERCASE"
}

# =============================================================================
# Integration tests
# =============================================================================

@test "integration: create and validate team workflow" {
    # Create team
    run create_team_structure "engineering"
    [ "$status" -eq 0 ]

    # Validate it exists
    run validate_team_exists "engineering"
    [ "$status" -eq 0 ]

    # List teams
    run list_teams
    [ "$status" -eq 0 ]
    [ "$output" = "engineering" ]
}

@test "integration: create multiple teams and list them" {
    # Create multiple teams
    create_team_structure "engineering"
    create_team_structure "product"
    create_team_structure "design"

    # List all teams
    run list_teams
    [ "$status" -eq 0 ]

    # Verify all teams are listed
    echo "$output" | grep -q "engineering"
    echo "$output" | grep -q "product"
    echo "$output" | grep -q "design"

    # Verify count
    [ "$(echo "$output" | wc -l)" -eq 3 ]
}

@test "integration: validate nonexistent team after creating another" {
    # Create one team
    create_team_structure "engineering"

    # Validate existing team
    run validate_team_exists "engineering"
    [ "$status" -eq 0 ]

    # Validate non-existing team
    run validate_team_exists "product"
    [ "$status" -eq 1 ]
}
