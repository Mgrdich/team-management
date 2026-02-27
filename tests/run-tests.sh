#!/usr/bin/env bash

# Test runner script for team management system
# This script checks for bats installation and runs the test suite

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for bats installation
check_bats() {
    if command_exists bats; then
        print_success "bats is installed: $(which bats)"
        bats --version
        return 0
    else
        print_error "bats is not installed"
        return 1
    fi
}

# Check for jq installation (required for json-utils tests)
check_jq() {
    if command_exists jq; then
        print_success "jq is installed: $(which jq)"
        return 0
    else
        print_warning "jq is not installed (required for json-utils tests)"
        return 1
    fi
}

# Function to install bats on macOS
install_bats_macos() {
    if command_exists brew; then
        print_info "Installing bats using Homebrew..."
        brew install bats-core
    else
        print_error "Homebrew not found. Please install bats manually:"
        echo "  Visit: https://github.com/bats-core/bats-core"
        return 1
    fi
}

# Function to install bats on Linux
install_bats_linux() {
    print_info "Attempting to install bats..."

    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y bats
    elif command_exists dnf; then
        sudo dnf install -y bats
    elif command_exists yum; then
        sudo yum install -y bats
    else
        print_error "Package manager not found. Please install bats manually:"
        echo "  Visit: https://github.com/bats-core/bats-core"
        return 1
    fi
}

# Function to prompt for bats installation
prompt_install_bats() {
    print_warning "bats is required to run tests"
    echo ""
    read -p "Would you like to install bats now? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        case "$(uname -s)" in
            Darwin*)
                install_bats_macos
                ;;
            Linux*)
                install_bats_linux
                ;;
            *)
                print_error "Unsupported operating system"
                return 1
                ;;
        esac
    else
        print_info "Installation cancelled"
        return 1
    fi
}

# Function to run tests
run_tests() {
    local test_path="${1:-tests/utils/}"
    local options="${2:-}"

    print_info "Running tests from: $test_path"
    echo ""

    if [[ -n "$options" ]]; then
        bats $options "$test_path"
    else
        bats "$test_path"
    fi
}

# Main script
main() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/.." && pwd)"

    # Change to project root
    cd "$project_root"

    print_info "Team Management System - Test Runner"
    echo ""

    # Check dependencies
    local deps_ok=true

    if ! check_bats; then
        if ! prompt_install_bats; then
            deps_ok=false
        fi
    fi

    echo ""
    check_jq || true  # jq is recommended but we continue anyway

    echo ""

    if [[ "$deps_ok" = false ]]; then
        print_error "Required dependencies not met. Exiting."
        exit 1
    fi

    # Parse command line arguments
    local test_target="tests/utils/"
    local bats_options=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                bats_options="--tap"
                shift
                ;;
            -t|--timing)
                bats_options="--timing"
                shift
                ;;
            --id-generator)
                test_target="tests/utils/test-id-generator.bats"
                shift
                ;;
            --file-ops)
                test_target="tests/utils/test-file-ops.bats"
                shift
                ;;
            --json-utils)
                test_target="tests/utils/test-json-utils.bats"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -v, --verbose       Run with TAP output format"
                echo "  -t, --timing        Show test timing information"
                echo "  --id-generator      Run only id-generator tests"
                echo "  --file-ops          Run only file-ops tests"
                echo "  --json-utils        Run only json-utils tests"
                echo "  -h, --help          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                  Run all tests"
                echo "  $0 --verbose        Run all tests with verbose output"
                echo "  $0 --id-generator   Run only id-generator tests"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Run the tests
    print_info "Starting test execution..."
    echo ""

    if run_tests "$test_target" "$bats_options"; then
        echo ""
        print_success "All tests passed!"
        exit 0
    else
        echo ""
        print_error "Some tests failed"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
