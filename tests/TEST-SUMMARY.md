# Test Suite Summary

## Overview

Comprehensive unit test suite for bash utility scripts in the Repository-Based Infrastructure feature.

## Test Statistics

| Test File | Tests | Lines | Coverage |
|-----------|-------|-------|----------|
| test-id-generator.bats | 38 | 331 | ID generation functions |
| test-file-ops.bats | 40 | 407 | File & directory operations |
| test-json-utils.bats | 55 | 729 | JSON manipulation operations |
| **TOTAL** | **133** | **1,467** | **All utility functions** |

## Quick Start

### Install bats (if not already installed)

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Fedora
sudo dnf install bats
```

### Run All Tests

```bash
# Using bats directly
bats tests/utils/

# Using the test runner script
./tests/run-tests.sh
```

### Run Specific Test File

```bash
# ID Generator tests
bats tests/utils/test-id-generator.bats
./tests/run-tests.sh --id-generator

# File Operations tests
bats tests/utils/test-file-ops.bats
./tests/run-tests.sh --file-ops

# JSON Utils tests
bats tests/utils/test-json-utils.bats
./tests/run-tests.sh --json-utils
```

## Test Coverage Details

### test-id-generator.bats (38 tests)

**Function: team_name_to_id (29 tests)**
- ✓ Simple name conversion to kebab-case
- ✓ Multiple/consecutive spaces handling
- ✓ Mixed case to lowercase conversion
- ✓ Special character stripping (#, $, %, @, etc.)
- ✓ Unicode character handling (Café → caf)
- ✓ Emoji stripping (🚀 removed)
- ✓ Truncation at 63 characters
- ✓ Leading/trailing hyphen removal
- ✓ Multiple consecutive hyphen collapsing
- ✓ Edge cases (numbers only, single word, underscores)
- ✓ Error handling (empty, special chars only, no arguments)

**Function: generate_member_id (7 tests)**
- ✓ Format validation: `mem-[10-digit-timestamp]-[3-lowercase-chars]`
- ✓ Correct prefix: `mem-`
- ✓ Valid timestamp (10 digits, numeric)
- ✓ Random characters (exactly 3, lowercase a-z)
- ✓ Uniqueness across multiple calls
- ✓ Length validation (exactly 18 characters)

**Function: generate_project_id (6 tests)**
- ✓ Format validation: `proj-[10-digit-timestamp]-[3-lowercase-chars]`
- ✓ Correct prefix: `proj-`
- ✓ Valid timestamp (10 digits, numeric)
- ✓ Random characters (exactly 3, lowercase a-z)
- ✓ Uniqueness across multiple calls
- ✓ Length validation (exactly 19 characters)

### test-file-ops.bats (40 tests)

**Function: create_team_structure (16 tests)**
- ✓ Creates team directory with valid team IDs
- ✓ Handles hyphens, underscores, numbers in team IDs
- ✓ Creates parent .team directory if missing
- ✓ Idempotent operation (succeeds if already exists)
- ✓ Rejects empty team ID
- ✓ Prevents path traversal attacks (..)
- ✓ Rejects special characters (spaces, slashes, *, ?)
- ✓ Error messages for invalid inputs

**Function: validate_team_exists (9 tests)**
- ✓ Returns 0 for existing team directories
- ✓ Returns 1 for non-existing teams
- ✓ Returns 1 when .team directory missing
- ✓ Rejects empty team ID
- ✓ Prevents path traversal
- ✓ Distinguishes files from directories
- ✓ Works with hyphens and underscores

**Function: list_teams (13 tests)**
- ✓ Returns empty output for no teams
- ✓ Lists single team
- ✓ Lists multiple teams (one per line)
- ✓ Ignores files in .team directory
- ✓ Ignores hidden directories
- ✓ Does not list nested subdirectories
- ✓ Returns sorted output
- ✓ Handles special characters in names

**Integration Tests (3 tests)**
- ✓ Create and validate team workflow
- ✓ Create multiple teams and list them
- ✓ Validate existence checks

### test-json-utils.bats (55 tests)

**Function: get_timestamp (2 tests)**
- ✓ Returns ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
- ✓ Ends with 'Z' (UTC indicator)

**Function: validate_json (7 tests)**
- ✓ Accepts valid JSON objects
- ✓ Accepts valid JSON arrays
- ✓ Accepts empty objects/arrays
- ✓ Rejects invalid JSON
- ✓ Rejects malformed JSON (trailing commas)
- ✓ Rejects empty strings

**Function: write_initial_files (10 tests)**
- ✓ Creates all three JSON files (team-config.json, members.json, projects.json)
- ✓ Creates valid team-config.json with all required fields
- ✓ Includes ISO 8601 timestamps (created_at, updated_at)
- ✓ Creates empty members.json array
- ✓ Creates empty projects.json array
- ✓ Validates team ID format
- ✓ Checks team directory exists
- ✓ Requires team ID and team name
- ✓ Uses atomic writes (temp files)

**Function: append_member (9 tests)**
- ✓ Adds member to empty members.json
- ✓ Adds multiple members
- ✓ Rejects duplicate email addresses
- ✓ Validates member JSON format
- ✓ Requires email field
- ✓ Checks members.json exists
- ✓ Validates team ID format
- ✓ Preserves existing members
- ✓ Uses atomic writes

**Function: append_project (4 tests)**
- ✓ Adds project to empty projects.json
- ✓ Adds multiple projects
- ✓ Validates project JSON format
- ✓ Checks projects.json exists

**Function: remove_member (5 tests)**
- ✓ Removes member by email
- ✓ Removes only specified member
- ✓ Returns error for non-existent email
- ✓ Checks members.json exists
- ✓ Uses atomic writes

**Function: update_current_projects (4 tests)**
- ✓ Adds project to current_projects array
- ✓ Updates updated_at timestamp
- ✓ Adds multiple projects
- ✓ Checks config file exists

**Function: read_team_config (4 tests)**
- ✓ Reads team config file
- ✓ Returns correct team data
- ✓ Handles missing config file
- ✓ Validates team ID format

**Function: read_members (3 tests)**
- ✓ Reads empty members array
- ✓ Reads members after adding
- ✓ Handles missing members file

**Function: read_projects (3 tests)**
- ✓ Reads empty projects array
- ✓ Reads projects after adding
- ✓ Handles missing projects file

**Malformed JSON Handling (2 tests)**
- ✓ Handles corrupted team-config.json
- ✓ Validates before writing to prevent corruption

**Integration Tests (2 tests)**
- ✓ Complete team setup workflow
- ✓ Member removal workflow

## Test Principles

All tests follow these principles:

1. **Isolation**: Each test runs in a unique temporary directory
2. **Cleanup**: Automatic teardown removes test artifacts
3. **Independence**: Tests can run in any order
4. **Clarity**: Descriptive test names explain what is being tested
5. **AAA Pattern**: Arrange-Act-Assert structure
6. **Comprehensive**: Cover happy path, edge cases, and error conditions

## Test Isolation

```bash
setup() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR"
    source <script-under-test>
}

teardown() {
    cd /
    rm -rf "$TEST_TEMP_DIR"
}
```

## Exit Codes

Tests verify both exit codes and output:
- `[ "$status" -eq 0 ]` - Success
- `[ "$status" -eq 1 ]` - Error/Failure
- `[[ "$output" =~ "pattern" ]]` - Output contains expected text

## Running Tests in CI/CD

```bash
#!/bin/bash
set -e

# Install dependencies
brew install bats-core jq  # or apt-get install bats jq

# Run tests with TAP output
bats --tap tests/utils/ > test-results.tap

# Check exit code
if [ $? -eq 0 ]; then
    echo "✓ All tests passed"
else
    echo "✗ Tests failed"
    exit 1
fi
```

## Dependencies

- **bats-core**: Testing framework
- **jq**: JSON processor (for json-utils tests)
- **bash**: 4.0+

## Files

```
tests/
├── README.md                      # Detailed documentation
├── TEST-SUMMARY.md               # This file - quick reference
├── run-tests.sh                  # Test runner script
└── utils/
    ├── test-id-generator.bats    # ID generation tests (38 tests)
    ├── test-file-ops.bats        # File operations tests (40 tests)
    └── test-json-utils.bats      # JSON operations tests (55 tests)
```

## Next Steps

After running tests successfully:

1. Review any failures and fix issues
2. Add tests for new functionality
3. Integrate into CI/CD pipeline
4. Monitor test coverage over time
5. Update tests when scripts change

## Contributing

When modifying bash utility scripts:

1. ✓ Write tests first (TDD)
2. ✓ Run tests before committing: `bats tests/utils/`
3. ✓ Ensure all tests pass
4. ✓ Add tests for new functions/features
5. ✓ Update documentation as needed

## Support

For issues or questions:
- Review test output for specific failure details
- Check `tests/README.md` for detailed documentation
- Verify bats and jq are installed correctly
- Ensure scripts are executable: `chmod +x scripts/utils/*.sh`
