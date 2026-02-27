#!/usr/bin/env bats

# Test suite for id-generator.sh
# Tests ID generation and validation functions

# Load the script under test
setup() {
    # Load the id-generator script
    source "${BATS_TEST_DIRNAME}/../../scripts/utils/id-generator.sh"
}

# =============================================================================
# Tests for team_name_to_id function
# =============================================================================

@test "team_name_to_id: converts simple name to lowercase kebab-case" {
    run team_name_to_id "Team Alpha"
    [ "$status" -eq 0 ]
    [ "$output" = "team-alpha" ]
}

@test "team_name_to_id: handles multiple spaces by collapsing to single hyphen" {
    run team_name_to_id "Team  Beta"
    [ "$status" -eq 0 ]
    [ "$output" = "team-beta" ]
}

@test "team_name_to_id: handles many consecutive spaces" {
    run team_name_to_id "Team     Gamma"
    [ "$status" -eq 0 ]
    [ "$output" = "team-gamma" ]
}

@test "team_name_to_id: converts mixed case to lowercase" {
    run team_name_to_id "TEAM gamma"
    [ "$status" -eq 0 ]
    [ "$output" = "team-gamma" ]
}

@test "team_name_to_id: handles all uppercase" {
    run team_name_to_id "ENGINEERING"
    [ "$status" -eq 0 ]
    [ "$output" = "engineering" ]
}

@test "team_name_to_id: strips special characters" {
    run team_name_to_id "Team #1!"
    [ "$status" -eq 0 ]
    [ "$output" = "team-1" ]
}

@test "team_name_to_id: strips various special characters" {
    run team_name_to_id "Team@#\$%^&*()+="
    [ "$status" -eq 0 ]
    [ "$output" = "team" ]
}

@test "team_name_to_id: handles unicode characters by stripping them" {
    run team_name_to_id "Team Café"
    [ "$status" -eq 0 ]
    [ "$output" = "team-caf" ]
}

@test "team_name_to_id: handles emoji by stripping them" {
    run team_name_to_id "Team 🚀 Rocket"
    [ "$status" -eq 0 ]
    [ "$output" = "team-rocket" ]
}

@test "team_name_to_id: truncates names longer than 63 characters" {
    local long_name="This is a very long team name that exceeds the maximum allowed length of sixty three characters"
    run team_name_to_id "$long_name"
    [ "$status" -eq 0 ]
    [ "${#output}" -le 63 ]
    # Check that it starts correctly
    [[ "$output" =~ ^this-is-a-very-long-team-name ]]
}

@test "team_name_to_id: truncates exactly at 63 characters" {
    local long_name="abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
    run team_name_to_id "$long_name"
    [ "$status" -eq 0 ]
    [ "${#output}" -eq 63 ]
}

@test "team_name_to_id: removes leading hyphens" {
    run team_name_to_id "---Team Name"
    [ "$status" -eq 0 ]
    [ "$output" = "team-name" ]
}

@test "team_name_to_id: removes trailing hyphens" {
    run team_name_to_id "Team Name---"
    [ "$status" -eq 0 ]
    [ "$output" = "team-name" ]
}

@test "team_name_to_id: removes both leading and trailing hyphens" {
    run team_name_to_id "---Team Name---"
    [ "$status" -eq 0 ]
    [ "$output" = "team-name" ]
}

@test "team_name_to_id: collapses multiple consecutive hyphens" {
    run team_name_to_id "Team---Name"
    [ "$status" -eq 0 ]
    [ "$output" = "team-name" ]
}

@test "team_name_to_id: handles name with only numbers" {
    run team_name_to_id "12345"
    [ "$status" -eq 0 ]
    [ "$output" = "12345" ]
}

@test "team_name_to_id: handles name with hyphen already present" {
    run team_name_to_id "team-alpha"
    [ "$status" -eq 0 ]
    [ "$output" = "team-alpha" ]
}

@test "team_name_to_id: handles single word name" {
    run team_name_to_id "Engineering"
    [ "$status" -eq 0 ]
    [ "$output" = "engineering" ]
}

@test "team_name_to_id: handles name with underscore" {
    run team_name_to_id "Team_Alpha"
    [ "$status" -eq 0 ]
    [ "$output" = "teamalpha" ]
}

@test "team_name_to_id: fails when name contains only special characters" {
    run team_name_to_id "###"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must contain at least one alphanumeric character" ]]
}

@test "team_name_to_id: fails when name contains only spaces" {
    run team_name_to_id "   "
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must contain at least one alphanumeric character" ]]
}

@test "team_name_to_id: fails when name is empty" {
    run team_name_to_id ""
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team name required" ]]
}

@test "team_name_to_id: fails when no argument provided" {
    run team_name_to_id
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team name required" ]]
}

@test "team_name_to_id: handles name with trailing hyphen after truncation" {
    # Create a name that will end with hyphen when truncated at 63 chars
    local name="This is a very long team name that will end with a space word"
    run team_name_to_id "$name"
    [ "$status" -eq 0 ]
    # Should not end with hyphen
    [[ ! "$output" =~ -$ ]]
}

# =============================================================================
# Tests for generate_member_id function
# =============================================================================

@test "generate_member_id: generates ID with correct format" {
    run generate_member_id
    [ "$status" -eq 0 ]
    # Check format: mem-[timestamp]-[3-lowercase-chars]
    [[ "$output" =~ ^mem-[0-9]{10}-[a-z]{3}$ ]]
}

@test "generate_member_id: generates ID starting with 'mem-'" {
    run generate_member_id
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^mem- ]]
}

@test "generate_member_id: generates IDs with valid timestamps" {
    run generate_member_id
    [ "$status" -eq 0 ]
    # Extract timestamp portion
    local timestamp=$(echo "$output" | cut -d'-' -f2)
    # Should be 10 digits
    [ "${#timestamp}" -eq 10 ]
    # Should be numeric
    [[ "$timestamp" =~ ^[0-9]+$ ]]
}

@test "generate_member_id: generates exactly 3 random lowercase characters" {
    run generate_member_id
    [ "$status" -eq 0 ]
    # Extract random chars portion
    local random_chars=$(echo "$output" | cut -d'-' -f3)
    # Should be exactly 3 characters
    [ "${#random_chars}" -eq 3 ]
    # Should be lowercase letters only
    [[ "$random_chars" =~ ^[a-z]{3}$ ]]
}

@test "generate_member_id: generates unique IDs across multiple calls" {
    run generate_member_id
    local id1="$output"

    # Small sleep to ensure different timestamp
    sleep 1

    run generate_member_id
    local id2="$output"

    # IDs should be different
    [ "$id1" != "$id2" ]
}

@test "generate_member_id: generates different random suffixes" {
    # Generate multiple IDs and check that at least some have different suffixes
    local -a ids
    local -a suffixes

    for i in {1..10}; do
        run generate_member_id
        [ "$status" -eq 0 ]
        ids+=("$output")
        suffixes+=($(echo "$output" | cut -d'-' -f3))
    done

    # Check that we got 10 IDs
    [ "${#ids[@]}" -eq 10 ]

    # At least one suffix should be different from the first one
    local first_suffix="${suffixes[0]}"
    local different_found=false

    for suffix in "${suffixes[@]:1}"; do
        if [ "$suffix" != "$first_suffix" ]; then
            different_found=true
            break
        fi
    done

    [ "$different_found" = true ]
}

@test "generate_member_id: total ID length is correct" {
    run generate_member_id
    [ "$status" -eq 0 ]
    # Format: mem-XXXXXXXXXX-XXX = 4 + 10 + 1 + 3 = 18 characters
    [ "${#output}" -eq 18 ]
}

# =============================================================================
# Tests for generate_project_id function
# =============================================================================

@test "generate_project_id: generates ID with correct format" {
    run generate_project_id
    [ "$status" -eq 0 ]
    # Check format: proj-[timestamp]-[3-lowercase-chars]
    [[ "$output" =~ ^proj-[0-9]{10}-[a-z]{3}$ ]]
}

@test "generate_project_id: generates ID starting with 'proj-'" {
    run generate_project_id
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^proj- ]]
}

@test "generate_project_id: generates IDs with valid timestamps" {
    run generate_project_id
    [ "$status" -eq 0 ]
    # Extract timestamp portion
    local timestamp=$(echo "$output" | cut -d'-' -f2)
    # Should be 10 digits
    [ "${#timestamp}" -eq 10 ]
    # Should be numeric
    [[ "$timestamp" =~ ^[0-9]+$ ]]
}

@test "generate_project_id: generates exactly 3 random lowercase characters" {
    run generate_project_id
    [ "$status" -eq 0 ]
    # Extract random chars portion
    local random_chars=$(echo "$output" | cut -d'-' -f3)
    # Should be exactly 3 characters
    [ "${#random_chars}" -eq 3 ]
    # Should be lowercase letters only
    [[ "$random_chars" =~ ^[a-z]{3}$ ]]
}

@test "generate_project_id: generates unique IDs across multiple calls" {
    run generate_project_id
    local id1="$output"

    # Small sleep to ensure different timestamp
    sleep 1

    run generate_project_id
    local id2="$output"

    # IDs should be different
    [ "$id1" != "$id2" ]
}

@test "generate_project_id: total ID length is correct" {
    run generate_project_id
    [ "$status" -eq 0 ]
    # Format: proj-XXXXXXXXXX-XXX = 5 + 10 + 1 + 3 = 19 characters
    [ "${#output}" -eq 19 ]
}

# =============================================================================
# Tests for ID uniqueness across different types
# =============================================================================

@test "member and project IDs have different prefixes" {
    run generate_member_id
    local member_id="$output"

    run generate_project_id
    local project_id="$output"

    # Should start with different prefixes
    [[ "$member_id" =~ ^mem- ]]
    [[ "$project_id" =~ ^proj- ]]
    [ "${member_id:0:4}" != "${project_id:0:5}" ]
}
