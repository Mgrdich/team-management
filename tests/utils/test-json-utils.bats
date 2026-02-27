#!/usr/bin/env bats

# Test suite for json-utils.sh
# Tests JSON manipulation operations for team management

# Setup: Create temporary directory for tests and load script
setup() {
    # Create a unique temp directory for each test
    export TEST_TEMP_DIR="$(mktemp -d)"

    # Change to temp directory
    cd "$TEST_TEMP_DIR"

    # Load the json-utils script
    source "${BATS_TEST_DIRNAME}/../../scripts/utils/json-utils.sh"

    # Also load file-ops for creating team structures
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
# Tests for get_timestamp function
# =============================================================================

@test "get_timestamp: returns ISO 8601 formatted timestamp" {
    run get_timestamp
    [ "$status" -eq 0 ]
    # Check format: YYYY-MM-DDTHH:MM:SSZ
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "get_timestamp: returns timestamp ending with Z" {
    run get_timestamp
    [ "$status" -eq 0 ]
    [[ "$output" =~ Z$ ]]
}

# =============================================================================
# Tests for validate_json function
# =============================================================================

@test "validate_json: accepts valid JSON object" {
    run validate_json '{"name": "test"}'
    [ "$status" -eq 0 ]
}

@test "validate_json: accepts valid JSON array" {
    run validate_json '[1, 2, 3]'
    [ "$status" -eq 0 ]
}

@test "validate_json: accepts empty JSON object" {
    run validate_json '{}'
    [ "$status" -eq 0 ]
}

@test "validate_json: accepts empty JSON array" {
    run validate_json '[]'
    [ "$status" -eq 0 ]
}

@test "validate_json: rejects invalid JSON" {
    run validate_json '{"name": invalid}'
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid JSON content" ]]
}

@test "validate_json: rejects malformed JSON with trailing comma" {
    run validate_json '{"name": "test",}'
    [ "$status" -eq 1 ]
}

@test "validate_json: rejects empty string" {
    run validate_json ''
    [ "$status" -eq 1 ]
}

# =============================================================================
# Tests for write_initial_files function
# =============================================================================

@test "write_initial_files: creates all three JSON files" {
    # Create team directory first
    create_team_structure "engineering"

    run write_initial_files "engineering" "Engineering Team"
    [ "$status" -eq 0 ]

    # Check all files exist
    [ -f ".team/engineering/team-config.json" ]
    [ -f ".team/engineering/members.json" ]
    [ -f ".team/engineering/projects.json" ]
}

@test "write_initial_files: creates valid team-config.json" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Validate JSON
    run jq empty ".team/engineering/team-config.json"
    [ "$status" -eq 0 ]

    # Check required fields
    run jq -r '.team_id' ".team/engineering/team-config.json"
    [ "$output" = "engineering" ]

    run jq -r '.team_name' ".team/engineering/team-config.json"
    [ "$output" = "Engineering Team" ]

    run jq -r '.current_projects' ".team/engineering/team-config.json"
    [ "$output" = "[]" ]
}

@test "write_initial_files: team-config.json contains timestamps" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Check created_at exists and is ISO 8601 format
    run jq -r '.created_at' ".team/engineering/team-config.json"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]

    # Check updated_at exists
    run jq -r '.updated_at' ".team/engineering/team-config.json"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]
}

@test "write_initial_files: creates empty members.json array" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Validate JSON
    run jq empty ".team/engineering/members.json"
    [ "$status" -eq 0 ]

    # Check it's an empty array
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "0" ]
}

@test "write_initial_files: creates empty projects.json array" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Validate JSON
    run jq empty ".team/engineering/projects.json"
    [ "$status" -eq 0 ]

    # Check it's an empty array
    run jq -r '. | length' ".team/engineering/projects.json"
    [ "$output" = "0" ]
}

@test "write_initial_files: fails with invalid team ID format" {
    run write_initial_files "team name" "Team Name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid team ID format" ]]
}

@test "write_initial_files: fails when team directory doesn't exist" {
    run write_initial_files "nonexistent" "Nonexistent Team"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team directory not found" ]]
}

@test "write_initial_files: fails when team ID is empty" {
    run write_initial_files "" "Team Name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team ID required" ]]
}

@test "write_initial_files: fails when team name is empty" {
    create_team_structure "engineering"
    run write_initial_files "engineering" ""
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team name required" ]]
}

@test "write_initial_files: uses atomic write with temp files" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Temp files should not exist after successful write
    [ ! -f ".team/engineering/team-config.json.temp" ]
    [ ! -f ".team/engineering/members.json.temp" ]
    [ ! -f ".team/engineering/projects.json.temp" ]
}

# =============================================================================
# Tests for append_member function
# =============================================================================

@test "append_member: adds member to empty members.json" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'

    run append_member "engineering" "$member_json"
    [ "$status" -eq 0 ]

    # Check member was added
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "1" ]

    run jq -r '.[0].email' ".team/engineering/members.json"
    [ "$output" = "john@example.com" ]
}

@test "append_member: adds multiple members" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member1='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    local member2='{"member_id":"mem-1234567891-def","name":"Jane Smith","email":"jane@example.com"}'

    append_member "engineering" "$member1"
    append_member "engineering" "$member2"

    # Check both members were added
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "2" ]
}

@test "append_member: rejects duplicate email" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member1='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    local member2='{"member_id":"mem-1234567891-def","name":"John Smith","email":"john@example.com"}'

    # Add first member
    run append_member "engineering" "$member1"
    [ "$status" -eq 0 ]

    # Try to add duplicate email
    run append_member "engineering" "$member2"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "already exists" ]]

    # Should still have only 1 member
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "1" ]
}

@test "append_member: fails with invalid JSON" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run append_member "engineering" '{"name": invalid}'
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid member JSON" ]]
}

@test "append_member: fails when member JSON missing email field" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe"}'

    run append_member "engineering" "$member_json"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "must contain 'email' field" ]]
}

@test "append_member: fails when members.json doesn't exist" {
    create_team_structure "engineering"

    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'

    run append_member "engineering" "$member_json"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Members file not found" ]]
}

@test "append_member: fails with invalid team ID format" {
    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'

    run append_member "team name" "$member_json"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid team ID format" ]]
}

@test "append_member: preserves existing members when adding new one" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member1='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    local member2='{"member_id":"mem-1234567891-def","name":"Jane Smith","email":"jane@example.com"}'

    append_member "engineering" "$member1"
    append_member "engineering" "$member2"

    # Check first member still exists
    run jq -r '.[0].email' ".team/engineering/members.json"
    [ "$output" = "john@example.com" ]

    # Check second member exists
    run jq -r '.[1].email' ".team/engineering/members.json"
    [ "$output" = "jane@example.com" ]
}

@test "append_member: uses atomic write (temp file)" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    append_member "engineering" "$member_json"

    # Temp file should not exist after successful write
    [ ! -f ".team/engineering/members.json.temp" ]
}

# =============================================================================
# Tests for append_project function
# =============================================================================

@test "append_project: adds project to empty projects.json" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local project_json='{"project_id":"proj-1234567890-abc","name":"Website Redesign"}'

    run append_project "engineering" "$project_json"
    [ "$status" -eq 0 ]

    # Check project was added
    run jq -r '. | length' ".team/engineering/projects.json"
    [ "$output" = "1" ]

    run jq -r '.[0].name' ".team/engineering/projects.json"
    [ "$output" = "Website Redesign" ]
}

@test "append_project: adds multiple projects" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local project1='{"project_id":"proj-1234567890-abc","name":"Project A"}'
    local project2='{"project_id":"proj-1234567891-def","name":"Project B"}'

    append_project "engineering" "$project1"
    append_project "engineering" "$project2"

    # Check both projects were added
    run jq -r '. | length' ".team/engineering/projects.json"
    [ "$output" = "2" ]
}

@test "append_project: fails with invalid JSON" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run append_project "engineering" '{"name": invalid}'
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid project JSON" ]]
}

@test "append_project: fails when projects.json doesn't exist" {
    create_team_structure "engineering"

    local project_json='{"project_id":"proj-1234567890-abc","name":"Project A"}'

    run append_project "engineering" "$project_json"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Projects file not found" ]]
}

# =============================================================================
# Tests for remove_member function
# =============================================================================

@test "remove_member: removes member by email" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    append_member "engineering" "$member_json"

    # Remove the member
    run remove_member "engineering" "john@example.com"
    [ "$status" -eq 0 ]

    # Check member was removed
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "0" ]
}

@test "remove_member: removes only specified member" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member1='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    local member2='{"member_id":"mem-1234567891-def","name":"Jane Smith","email":"jane@example.com"}'

    append_member "engineering" "$member1"
    append_member "engineering" "$member2"

    # Remove first member
    run remove_member "engineering" "john@example.com"
    [ "$status" -eq 0 ]

    # Check only one member remains
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "1" ]

    # Check remaining member is Jane
    run jq -r '.[0].email' ".team/engineering/members.json"
    [ "$output" = "jane@example.com" ]
}

@test "remove_member: fails when email not found" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run remove_member "engineering" "nonexistent@example.com"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
}

@test "remove_member: fails when members.json doesn't exist" {
    create_team_structure "engineering"

    run remove_member "engineering" "john@example.com"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Members file not found" ]]
}

@test "remove_member: uses atomic write (temp file)" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    append_member "engineering" "$member_json"
    remove_member "engineering" "john@example.com"

    # Temp file should not exist after successful write
    [ ! -f ".team/engineering/members.json.temp" ]
}

# =============================================================================
# Tests for update_current_projects function
# =============================================================================

@test "update_current_projects: adds project to current_projects array" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run update_current_projects "engineering" "proj-1234567890-abc"
    [ "$status" -eq 0 ]

    # Check project was added
    run jq -r '.current_projects | length' ".team/engineering/team-config.json"
    [ "$output" = "1" ]

    run jq -r '.current_projects[0]' ".team/engineering/team-config.json"
    [ "$output" = "proj-1234567890-abc" ]
}

@test "update_current_projects: updates the updated_at timestamp" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Get original timestamp
    local original_timestamp=$(jq -r '.updated_at' ".team/engineering/team-config.json")

    # Wait a moment to ensure timestamp changes
    sleep 1

    update_current_projects "engineering" "proj-1234567890-abc"

    # Get new timestamp
    local new_timestamp=$(jq -r '.updated_at' ".team/engineering/team-config.json")

    # Timestamps should be different
    [ "$original_timestamp" != "$new_timestamp" ]
}

@test "update_current_projects: adds multiple projects" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    update_current_projects "engineering" "proj-1234567890-abc"
    update_current_projects "engineering" "proj-1234567891-def"

    # Check both projects were added
    run jq -r '.current_projects | length' ".team/engineering/team-config.json"
    [ "$output" = "2" ]
}

@test "update_current_projects: fails when config file doesn't exist" {
    create_team_structure "engineering"

    run update_current_projects "engineering" "proj-1234567890-abc"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team config file not found" ]]
}

# =============================================================================
# Tests for read_team_config function
# =============================================================================

@test "read_team_config: reads team config file" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run read_team_config "engineering"
    [ "$status" -eq 0 ]

    # Output should be valid JSON
    echo "$output" | jq empty
}

@test "read_team_config: returns correct team data" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run read_team_config "engineering"
    [ "$status" -eq 0 ]

    # Check team_id
    local team_id=$(echo "$output" | jq -r '.team_id')
    [ "$team_id" = "engineering" ]

    # Check team_name
    local team_name=$(echo "$output" | jq -r '.team_name')
    [ "$team_name" = "Engineering Team" ]
}

@test "read_team_config: fails when config file doesn't exist" {
    create_team_structure "engineering"

    run read_team_config "engineering"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Team config file not found" ]]
}

@test "read_team_config: fails with invalid team ID" {
    run read_team_config "team name"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid team ID format" ]]
}

# =============================================================================
# Tests for read_members function
# =============================================================================

@test "read_members: reads empty members array" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run read_members "engineering"
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

@test "read_members: reads members after adding them" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    append_member "engineering" "$member_json"

    run read_members "engineering"
    [ "$status" -eq 0 ]

    # Check member data
    local email=$(echo "$output" | jq -r '.[0].email')
    [ "$email" = "john@example.com" ]
}

@test "read_members: fails when members file doesn't exist" {
    create_team_structure "engineering"

    run read_members "engineering"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Members file not found" ]]
}

# =============================================================================
# Tests for read_projects function
# =============================================================================

@test "read_projects: reads empty projects array" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    run read_projects "engineering"
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

@test "read_projects: reads projects after adding them" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    local project_json='{"project_id":"proj-1234567890-abc","name":"Project A"}'
    append_project "engineering" "$project_json"

    run read_projects "engineering"
    [ "$status" -eq 0 ]

    # Check project data
    local name=$(echo "$output" | jq -r '.[0].name')
    [ "$name" = "Project A" ]
}

@test "read_projects: fails when projects file doesn't exist" {
    create_team_structure "engineering"

    run read_projects "engineering"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Projects file not found" ]]
}

# =============================================================================
# Tests for malformed JSON handling
# =============================================================================

@test "json-utils: handles malformed team-config.json gracefully" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Corrupt the JSON
    echo "invalid json {" > ".team/engineering/team-config.json"

    # read_team_config should still work but output invalid JSON
    run bash -c "source ${BATS_TEST_DIRNAME}/../../scripts/utils/json-utils.sh && read_team_config engineering 2>&1"
    # It will output the corrupted content, not fail
    [ "$status" -eq 0 ]
}

@test "json-utils: validates JSON before writing to members.json" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Corrupt members.json
    echo "invalid json" > ".team/engineering/members.json"

    # Try to append member - jq should fail on invalid input
    local member_json='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com"}'
    run append_member "engineering" "$member_json"
    # Should fail because jq can't parse the corrupted file
    [ "$status" -eq 1 ]
}

# =============================================================================
# Integration tests
# =============================================================================

@test "integration: complete team setup workflow" {
    # Create team structure
    create_team_structure "engineering"

    # Initialize files
    write_initial_files "engineering" "Engineering Team"

    # Add members
    local member1='{"member_id":"mem-1234567890-abc","name":"John Doe","email":"john@example.com","role":"engineer"}'
    local member2='{"member_id":"mem-1234567891-def","name":"Jane Smith","email":"jane@example.com","role":"manager"}'

    append_member "engineering" "$member1"
    append_member "engineering" "$member2"

    # Add project
    local project='{"project_id":"proj-1234567890-xyz","name":"Website Redesign","status":"active"}'
    append_project "engineering" "$project"

    # Update current projects
    update_current_projects "engineering" "proj-1234567890-xyz"

    # Read and verify all data
    run read_team_config "engineering"
    [ "$status" -eq 0 ]

    run read_members "engineering"
    [ "$status" -eq 0 ]
    local member_count=$(echo "$output" | jq -r '. | length')
    [ "$member_count" = "2" ]

    run read_projects "engineering"
    [ "$status" -eq 0 ]
    local project_count=$(echo "$output" | jq -r '. | length')
    [ "$project_count" = "1" ]

    # Verify current_projects in config
    run jq -r '.current_projects[0]' ".team/engineering/team-config.json"
    [ "$output" = "proj-1234567890-xyz" ]
}

@test "integration: member removal workflow" {
    create_team_structure "engineering"
    write_initial_files "engineering" "Engineering Team"

    # Add three members
    append_member "engineering" '{"member_id":"mem-1","name":"Alice","email":"alice@example.com"}'
    append_member "engineering" '{"member_id":"mem-2","name":"Bob","email":"bob@example.com"}'
    append_member "engineering" '{"member_id":"mem-3","name":"Charlie","email":"charlie@example.com"}'

    # Verify 3 members
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "3" ]

    # Remove middle member
    remove_member "engineering" "bob@example.com"

    # Verify 2 members remain
    run jq -r '. | length' ".team/engineering/members.json"
    [ "$output" = "2" ]

    # Verify correct members remain
    run jq -r '.[0].email' ".team/engineering/members.json"
    [ "$output" = "alice@example.com" ]

    run jq -r '.[1].email' ".team/engineering/members.json"
    [ "$output" = "charlie@example.com" ]
}
