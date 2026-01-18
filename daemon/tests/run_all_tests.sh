#!/bin/bash

echo "=========================================="
echo "Shell Assistant Daemon - Test Suite"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

total_tests=0
passed_tests=0
failed_tests=0

run_test() {
    local test_name=$1
    local test_script=$2
    
    total_tests=$((total_tests + 1))
    echo ""
    echo "Running: $test_name"
    echo "----------------------------------------"
    
    if bash "$test_script"; then
        echo -e "${GREEN}✅ PASSED${NC}: $test_name"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}❌ FAILED${NC}: $test_name"
        failed_tests=$((failed_tests + 1))
    fi
}

# Check if daemon is running
if ! curl -s http://localhost:5738/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Daemon is not running!${NC}"
    echo "Please start the daemon first:"
    echo "  python -m shell_assistant.cli start"
    echo "Or:"
    echo "  shell-assistant-daemon start"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run all tests
run_test "Health Check" "$SCRIPT_DIR/test_health.sh"
run_test "Complete Endpoint" "$SCRIPT_DIR/test_complete.sh"
run_test "Error Handling" "$SCRIPT_DIR/test_errors.sh"

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total:  $total_tests"
echo -e "${GREEN}Passed: $passed_tests${NC}"
if [ $failed_tests -gt 0 ]; then
    echo -e "${RED}Failed: $failed_tests${NC}"
else
    echo -e "${GREEN}Failed: $failed_tests${NC}"
fi
echo ""

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
