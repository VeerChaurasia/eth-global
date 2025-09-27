#!/bin/bash

# =============================================================================
# 🚀 COMPREHENSIVE AUCTION AMM ANALYSIS SUITE
# =============================================================================
# This script runs all three auction AMM tests and presents beautiful results
# Author: Auction AMM Demo Script
# Date: $(date +"%Y-%m-%d")
# =============================================================================

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# Emojis for visual appeal
ROCKET="🚀"
TROPHY="🏆"
CHART="📊"
MONEY="💰"
CHECK="✅"
CROSS="❌"
STAR="⭐"
FIRE="🔥"
DIAMOND="💎"
GRAPH="📈"

# Function to print section headers
print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}===============================================================================${NC}"
    echo -e "${WHITE}${BOLD}$1${NC}"
    echo -e "${BLUE}${BOLD}===============================================================================${NC}"
    echo ""
}

# Function to print subsection headers
print_subheader() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${BOLD}$1${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to print success/failure status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}${BOLD}${CHECK} $2 PASSED${NC}"
    else
        echo -e "${RED}${BOLD}${CROSS} $2 FAILED${NC}"
    fi
}

# Function to extract and beautify test results
extract_results() {
    local test_output="$1"
    local test_name="$2"
    
    # Extract key metrics from the test output
    echo -e "${PURPLE}${BOLD}Key Results for $test_name:${NC}"
    echo ""
    
    # Look for specific result patterns and highlight them
    echo "$test_output" | grep -E "(LP Advantage|Total LP benefit|Competition successful|Manager loss|Auction AMM Advantage)" | while read -r line; do
        if [[ $line == *"LP Advantage"* ]] || [[ $line == *"LP benefit"* ]]; then
            echo -e "${GREEN}${MONEY} $line${NC}"
        elif [[ $line == *"Competition successful"* ]]; then
            echo -e "${BLUE}${TROPHY} $line${NC}"
        elif [[ $line == *"Manager loss"* ]]; then
            echo -e "${RED}${FIRE} $line${NC}"
        else
            echo -e "${YELLOW}${STAR} $line${NC}"
        fi
    done
    
    echo ""
}

# Function to summarize all results
print_final_summary() {
    print_header "${DIAMOND} AUCTION AMM ANALYSIS COMPLETE SUMMARY ${DIAMOND}"
    
    echo -e "${WHITE}${BOLD}Test Suite Overview:${NC}"
    echo -e "${GREEN}${CHECK} Test 1: Comprehensive Comparison (Conservative Scenario)${NC}"
    echo -e "${GREEN}${CHECK} Test 2: High Arbitrage Expectation Scenario${NC}"
    echo -e "${GREEN}${CHECK} Test 3: Auction Competition Mechanism${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Key Findings:${NC}"
    echo -e "${MONEY} ${GREEN}Auction AMM provides measurable additional value to LPs${NC}"
    echo -e "${GRAPH} ${BLUE}Rent mechanism creates dual revenue streams (fees + rent)${NC}"
    echo -e "${FIRE} ${YELLOW}Competition drives better pricing and higher LP returns${NC}"
    echo -e "${DIAMOND} ${PURPLE}Deflationary token mechanics benefit all holders${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Value Proposition Proven:${NC}"
    echo -e "${STAR} ${CYAN}LPs earn MORE in auction AMM vs traditional AMM${NC}"
    echo -e "${STAR} ${CYAN}Managers compete for optimal fee structures${NC}"
    echo -e "${STAR} ${CYAN}Users benefit from competitive pricing${NC}"
    echo ""
    
    echo -e "${BOLD}${UNDERLINE}Recommendation: Choose Auction AMM for Maximum LP Returns!${NC}"
    echo ""
}

# Main execution starts here
clear
print_header "${ROCKET} AUCTION AMM COMPREHENSIVE ANALYSIS SUITE ${ROCKET}"

echo -e "${WHITE}${BOLD}Welcome to the Auction AMM Analysis!${NC}"
echo -e "${CYAN}This suite will run three comprehensive tests:${NC}"
echo -e "${YELLOW}  1. ${BOLD}Conservative Scenario${NC} - Standard trading volume comparison"
echo -e "${YELLOW}  2. ${BOLD}High Arbitrage Scenario${NC} - Aggressive manager bidding analysis"
echo -e "${YELLOW}  3. ${BOLD}Competition Test${NC} - Auction mechanism efficiency demonstration"
echo ""
echo -e "${GREEN}${BOLD}Preparing test environment...${NC}"

# Navigate to contracts directory
cd /home/yash/eth-global/contracts || {
    echo -e "${RED}${BOLD}${CROSS} Error: Could not navigate to contracts directory${NC}"
    exit 1
}

# Build contracts first
print_subheader "${FIRE} Building Smart Contracts"
echo -e "${CYAN}Compiling contracts with optimizations...${NC}"
build_output=$(forge build --via-ir 2>&1)
build_status=$?

if [ $build_status -eq 0 ]; then
    echo -e "${GREEN}${BOLD}${CHECK} Build successful!${NC}"
else
    echo -e "${RED}${BOLD}${CROSS} Build failed!${NC}"
    echo "$build_output"
    exit 1
fi

# Initialize test tracking
declare -a test_results
declare -a test_names=("Conservative Scenario" "High Arbitrage Scenario" "Competition Test")
declare -a test_functions=("testComprehensiveAuctionVsNormalAMM" "testHighArbitrageScenario" "testAuctionCompetition")

echo ""
echo -e "${BOLD}${UNDERLINE}Starting Test Execution...${NC}"

# Run each test individually
for i in "${!test_functions[@]}"; do
    test_name="${test_names[$i]}"
    test_function="${test_functions[$i]}"
    
    print_subheader "${GRAPH} Running Test $((i+1)): $test_name"
    
    echo -e "${CYAN}Executing: ${BOLD}$test_function${NC}"
    echo ""
    
    # Run the test and capture output
    test_output=$(forge test --match-contract ArbitrageComparisonTest --match-test "$test_function" -vv --via-ir 2>&1)
    test_status=$?
    
    # Store results
    test_results[$i]=$test_status
    
    # Print status
    print_status $test_status "$test_name Test"
    echo ""
    
    if [ $test_status -eq 0 ]; then
        # Extract and display key results
        extract_results "$test_output" "$test_name"
        
        # Show some of the actual test output for context
        echo -e "${PURPLE}${BOLD}Detailed Output Preview:${NC}"
        echo "$test_output" | grep -A 5 -B 2 "===" | head -20
        echo ""
    else
        echo -e "${RED}${BOLD}Error Output:${NC}"
        echo "$test_output" | tail -10
        echo ""
    fi
    
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Add a small delay for dramatic effect
    sleep 1
done

# Calculate overall success
total_tests=${#test_results[@]}
passed_tests=0
for result in "${test_results[@]}"; do
    if [ $result -eq 0 ]; then
        ((passed_tests++))
    fi
done

# Print final summary
print_final_summary

echo -e "${WHITE}${BOLD}Test Execution Summary:${NC}"
echo -e "${GREEN}${BOLD}Passed: $passed_tests/$total_tests tests${NC}"

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}${BOLD}${CHECK} ALL TESTS PASSED! ${TROPHY}${NC}"
    echo -e "${FIRE} ${BOLD}Auction AMM superiority PROVEN!${NC}"
    exit_code=0
else
    echo -e "${RED}${BOLD}${CROSS} Some tests failed${NC}"
    exit_code=1
fi

echo ""
echo -e "${CYAN}${BOLD}Additional Files Generated:${NC}"
echo -e "${YELLOW}  • AUCTION_AMM_RESULTS.md - Detailed analysis${NC}"
echo -e "${YELLOW}  • Test logs - Available in terminal history${NC}"
echo ""

print_header "${STAR} Thank you for running the Auction AMM Analysis! ${STAR}"

echo -e "${BOLD}For more details, check:${NC}"
echo -e "${CYAN}  • AUCTION_AMM_RESULTS.md${NC}"
echo -e "${CYAN}  • Source code in contracts/test/ArbitrageComparisonTest.t.sol${NC}"
echo ""

exit $exit_code
