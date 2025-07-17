#!/bin/bash

# AWS Cost Explorer Setup Script
# This script checks and enables necessary AWS Cost Explorer features

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== AWS Cost Explorer Setup and Verification ==="
echo "Account: $ACCOUNT_NAME"
echo "Timestamp: $TIMESTAMP"
echo ""

# Function to check if Cost Explorer is enabled
check_cost_explorer() {
    echo -e "${YELLOW}Checking Cost Explorer status...${NC}"
    
    # Try to get cost and usage data to check if Cost Explorer is enabled
    # Use a more recent date range (last 7 days)
    END_DATE=$(date +"%Y-%m-%d")
    START_DATE=$(date -d "7 days ago" +"%Y-%m-%d")
    
    aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity DAILY \
        --metrics "BlendedCost" \
        --output json > /tmp/ce_test.json 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Cost Explorer is enabled${NC}"
        return 0
    else
        echo -e "${RED}✗ Cost Explorer is not enabled or accessible${NC}"
        cat /tmp/ce_test.json
        return 1
    fi
}

# Function to check account permissions
check_permissions() {
    echo -e "${YELLOW}Checking AWS permissions...${NC}"
    
    # Check if we can access Cost Explorer
    aws ce describe-cost-category-definition --cost-category-arn "test" > /dev/null 2>&1
    if [ $? -eq 254 ]; then
        echo -e "${GREEN}✓ Cost Explorer API is accessible${NC}"
    else
        echo -e "${RED}✗ Cost Explorer API access issues${NC}"
    fi
    
    # Check basic AWS access
    aws sts get-caller-identity > /tmp/caller_identity.json 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ AWS credentials are valid${NC}"
        echo "Account ID: $(cat /tmp/caller_identity.json | grep -o '"Account": "[^"]*' | cut -d'"' -f4)"
        echo "User/Role: $(cat /tmp/caller_identity.json | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)"
    else
        echo -e "${RED}✗ AWS credentials issue${NC}"
        cat /tmp/caller_identity.json
        return 1
    fi
}

# Function to test Cost Explorer APIs
test_cost_explorer_apis() {
    echo -e "${YELLOW}Testing Cost Explorer APIs...${NC}"
    
    # Test basic cost and usage API
    echo "Testing get-cost-and-usage..."
    END_DATE=$(date +"%Y-%m-%d")
    START_DATE=$(date -d "7 days ago" +"%Y-%m-%d")
    
    aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity DAILY \
        --metrics "BlendedCost" \
        --output json > "$OUTPUT_DIR/test_cost_usage_${TIMESTAMP}.json" 2>&1
    
    if [ $? -eq 0 ] && [ -s "$OUTPUT_DIR/test_cost_usage_${TIMESTAMP}.json" ]; then
        echo -e "${GREEN}✓ get-cost-and-usage API works${NC}"
    else
        echo -e "${RED}✗ get-cost-and-usage API failed${NC}"
        cat "$OUTPUT_DIR/test_cost_usage_${TIMESTAMP}.json"
    fi
    
    # Test rightsizing recommendations
    echo "Testing rightsizing recommendations..."
    aws ce get-rightsizing-recommendation \
        --service "AmazonEC2" \
        --output json > "$OUTPUT_DIR/test_rightsizing_${TIMESTAMP}.json" 2>&1
    
    if [ $? -eq 0 ]; then
        if [ -s "$OUTPUT_DIR/test_rightsizing_${TIMESTAMP}.json" ]; then
            echo -e "${GREEN}✓ Rightsizing recommendations API works${NC}"
        else
            echo -e "${YELLOW}⚠ Rightsizing API accessible but no recommendations available${NC}"
            echo "This might mean:"
            echo "  - Rightsizing recommendations are not enabled"
            echo "  - No EC2 instances to analyze"
            echo "  - Data is still being processed (can take 24 hours)"
        fi
    else
        echo -e "${RED}✗ Rightsizing recommendations API failed${NC}"
        cat "$OUTPUT_DIR/test_rightsizing_${TIMESTAMP}.json"
    fi
    
    # Test reservation recommendations
    echo "Testing reservation recommendations..."
    aws ce get-reservation-purchase-recommendation \
        --service "Amazon Elastic Compute Cloud - Compute" \
        --output json > "$OUTPUT_DIR/test_ri_recommendations_${TIMESTAMP}.json" 2>&1
    
    if [ $? -eq 0 ]; then
        if [ -s "$OUTPUT_DIR/test_ri_recommendations_${TIMESTAMP}.json" ]; then
            echo -e "${GREEN}✓ RI recommendations API works${NC}"
        else
            echo -e "${YELLOW}⚠ RI recommendations API accessible but no recommendations${NC}"
        fi
    else
        echo -e "${RED}✗ RI recommendations API failed${NC}"
        cat "$OUTPUT_DIR/test_ri_recommendations_${TIMESTAMP}.json"
    fi
    
    # Test Savings Plans recommendations
    echo "Testing Savings Plans recommendations..."
    aws ce get-savings-plans-purchase-recommendation \
        --savings-plans-type "COMPUTE_SP" \
        --term-in-years "ONE_YEAR" \
        --payment-option "PARTIAL_UPFRONT" \
        --output json > "$OUTPUT_DIR/test_sp_recommendations_${TIMESTAMP}.json" 2>&1
    
    if [ $? -eq 0 ]; then
        if [ -s "$OUTPUT_DIR/test_sp_recommendations_${TIMESTAMP}.json" ]; then
            echo -e "${GREEN}✓ Savings Plans recommendations API works${NC}"
        else
            echo -e "${YELLOW}⚠ Savings Plans API accessible but no recommendations${NC}"
        fi
    else
        echo -e "${RED}✗ Savings Plans recommendations API failed${NC}"
        cat "$OUTPUT_DIR/test_sp_recommendations_${TIMESTAMP}.json"
    fi
}

# Function to provide setup instructions
provide_setup_instructions() {
    echo ""
    echo -e "${YELLOW}=== SETUP INSTRUCTIONS ===${NC}"
    echo ""
    echo "To enable AWS Cost Explorer features, follow these steps:"
    echo ""
    echo "1. Enable Cost Explorer:"
    echo "   - Open: https://console.aws.amazon.com/costmanagement/"
    echo "   - Click 'Cost Explorer' in the navigation pane"
    echo "   - Click 'Launch Cost Explorer' if not already enabled"
    echo ""
    echo "2. Enable Rightsizing Recommendations:"
    echo "   - Go to: https://console.aws.amazon.com/costmanagement/preferences"
    echo "   - Under 'Rightsizing - legacy' section"
    echo "   - Check 'Enable Rightsizing recommendations'"
    echo "   - Click 'Save preferences'"
    echo ""
    echo "3. Wait for data processing:"
    echo "   - Initial data preparation can take up to 24 hours"
    echo "   - Recommendations are updated daily"
    echo ""
    echo "4. Required permissions:"
    echo "   - ce:GetCostAndUsage"
    echo "   - ce:GetRightsizingRecommendation"
    echo "   - ce:GetReservationPurchaseRecommendation"
    echo "   - ce:GetSavingsPlansUtilization"
    echo ""
    echo "5. Billing requirements:"
    echo "   - Must be the account owner or have billing access"
    echo "   - For Organizations: Management account must enable features"
    echo ""
}

# Function to generate a summary report
generate_summary() {
    echo ""
    echo -e "${YELLOW}=== SUMMARY REPORT ===${NC}"
    echo "Test files generated in: $OUTPUT_DIR"
    echo "- test_cost_usage_${TIMESTAMP}.json"
    echo "- test_rightsizing_${TIMESTAMP}.json"
    echo "- test_ri_recommendations_${TIMESTAMP}.json"
    echo "- test_sp_recommendations_${TIMESTAMP}.json"
    echo ""
    echo "Check these files to see detailed API responses and error messages."
    echo ""
}

# Main execution
main() {
    check_permissions
    echo ""
    
    check_cost_explorer
    echo ""
    
    test_cost_explorer_apis
    echo ""
    
    provide_setup_instructions
    generate_summary
    
    echo -e "${GREEN}Cost Explorer setup verification completed!${NC}"
}

# Execute main function
main
