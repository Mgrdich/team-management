# Test Suite for Team Management System

This directory contains comprehensive unit tests for the bash utility scripts used in the Repository-Based Infrastructure feature.

## Test Framework

The tests use [Bash Automated Testing System (bats)](https://github.com/bats-core/bats-core), a TAP-compliant testing framework for Bash.

## Installation

### macOS (using Homebrew)

```bash
brew install bats-core
```

### Linux (using package manager)

**Ubuntu/Debian:**
```bash
sudo apt-get install bats
```

**Fedora:**
```bash
sudo dnf install bats
```

### Manual Installation

```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run all tests

```bash
bats tests/utils/
```

### Run specific test file

```bash
bats tests/utils/test-id-generator.bats
bats tests/utils/test-file-ops.bats
bats tests/utils/test-json-utils.bats
```

### Run with verbose output

```bash
bats -t tests/utils/
```

### Run and display test timing

```bash
bats --timing tests/utils/
```

## Test Coverage

### test-id-generator.bats

Tests for `scripts/utils/id-generator.sh`:

- **team_name_to_id function** (29 tests)
  - Simple name conversion
  - Multiple spaces handling
  - Mixed case conversion
  - Special character stripping
  - Unicode and emoji handling
  - Truncation at 63 characters
  - Leading/trailing hyphen removal
  - Error handling for invalid inputs

- **generate_member_id function** (7 tests)
  - Format validation (mem-[timestamp]-[3-chars])
  - Timestamp generation
  - Random character generation
  - Uniqueness across calls
  - Length validation

- **generate_project_id function** (6 tests)
  - Format validation (proj-[timestamp]-[3-chars])
  - Timestamp generation
  - Random character generation
  - Uniqueness across calls
  - Length validation

**Total: 43 tests**

### test-file-ops.bats

Tests for `scripts/utils/file-ops.sh`:

- **create_team_structure function** (16 tests)
  - Valid team ID handling
  - Directory creation with various formats
  - Idempotent operation
  - Path traversal prevention
  - Special character validation
  - Error handling

- **validate_team_exists function** (9 tests)
  - Existing team detection
  - Non-existing team handling
  - Path traversal prevention
  - File vs directory distinction
  - Error handling

- **list_teams function** (13 tests)
  - Empty directory handling
  - Single and multiple team listing
  - File filtering
  - Hidden directory handling
  - Nested directory exclusion
  - Sorted output
  - Special character handling

- **Integration tests** (3 tests)
  - Complete workflows combining multiple functions

**Total: 41 tests**

### test-json-utils.bats

Tests for `scripts/utils/json-utils.sh`:

- **Utility functions** (10 tests)
  - get_timestamp format validation
  - validate_json with valid/invalid inputs

- **write_initial_files function** (10 tests)
  - File creation (team-config.json, members.json, projects.json)
  - JSON structure validation
  - Timestamp generation
  - Error handling
  - Atomic writes

- **append_member function** (9 tests)
  - Member addition
  - Duplicate email detection
  - JSON validation
  - Error handling
  - Atomic writes

- **append_project function** (4 tests)
  - Project addition
  - JSON validation
  - Error handling

- **remove_member function** (5 tests)
  - Member removal by email
  - Selective removal
  - Error handling
  - Atomic writes

- **update_current_projects function** (4 tests)
  - Project array updates
  - Timestamp updates
  - Error handling

- **Read functions** (9 tests)
  - read_team_config
  - read_members
  - read_projects
  - Error handling

- **Malformed JSON handling** (2 tests)
  - Graceful handling of corrupted JSON
  - Validation before writes

- **Integration tests** (2 tests)
  - Complete team setup workflow
  - Member removal workflow

**Total: 55 tests**

## Overall Test Statistics

- **Total Test Files:** 3
- **Total Tests:** 139
- **Lines of Test Code:** ~1,000+

## Test Structure

Each test follows the Arrange-Act-Assert pattern:

```bash
@test "description of what is being tested" {
    # Arrange: Set up test conditions
    setup_test_data

    # Act: Execute the function
    run function_under_test "arguments"

    # Assert: Verify expected outcomes
    [ "$status" -eq 0 ]
    [ "$output" = "expected_value" ]
}
```

## Test Isolation

- Each test runs in a unique temporary directory
- Tests are isolated and can run in any order
- Cleanup is performed automatically after each test
- No shared state between tests

## Continuous Integration

To integrate these tests into a CI/CD pipeline:

```bash
#!/bin/bash
set -e

# Install bats
brew install bats-core  # or appropriate package manager

# Run tests with TAP output
bats --tap tests/utils/ > test-results.tap

# Or run with JUnit XML output (requires bats-core with support)
bats --formatter junit tests/utils/ > test-results.xml
```

## Troubleshooting

### Tests fail with "command not found"

Ensure the scripts being tested are executable:

```bash
chmod +x scripts/utils/*.sh
```

### Tests fail with "No such file or directory"

Verify the script paths in the test files match your repository structure.

### Temporary directory cleanup issues

Tests automatically clean up temp directories. If you see leftover directories:

```bash
find /tmp -name "tmp.*" -type d -mtime +1 -delete
```

## Contributing

When adding new functionality to the bash scripts:

1. Write tests first (TDD approach recommended)
2. Ensure new tests follow existing patterns
3. Run all tests before committing
4. Update this README if adding new test categories

## Dependencies

The tests require:

- **bats-core** - Testing framework
- **jq** - JSON processing (for json-utils.sh tests)
- **bash** 4.0+ - Shell interpreter

## License

Tests are part of the Team Management System and follow the same license as the main project.
