#!/bin/bash

# Cost Advisor Script
# Identifies inefficiencies and suggests recommendations for optimizing costs.

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Date range (last 30 days)
END_DATE=$(date +"%Y-%m-%d")
START_DATE=$(date -d "30 days ago" +"%Y-%m-%d")

# Function to check if a JSON file has meaningful content
check_json_content() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ $description: File not created${NC}"
        return 1
    elif [ ! -s "$file" ]; then
        echo -e "${YELLOW}⚠ $description: File empty (feature may not be enabled)${NC}"
        return 1
    else
        # Check if file contains meaningful JSON (not just error messages)
        if grep -q '"RecommendationDetails"\|"ResultsByTime"\|"RecommendationMetadata"' "$file" 2>/dev/null; then
            echo -e "${GREEN}✓ $description: Data retrieved successfully${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ $description: No recommendations available${NC}"
            return 1
        fi
    fi
}

function generate_cost_advisor_report() {
    echo "=== Cost Advisor Report ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Analysis Period: $START_DATE to $END_DATE"
    echo ""

    # Get rightsizing recommendations
    echo "Getting rightsizing recommendations..."
    aws ce get-rightsizing-recommendation \
        --service "AmazonEC2" \
        --output json > "$OUTPUT_DIR/rightsizing_recommendations_${TIMESTAMP}.json" 2>/dev/null

    # Get cost optimization recommendations
    echo "Getting cost optimization recommendations..."
    aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity DAILY \
        --metrics "BlendedCost" "UnblendedCost" "UsageQuantity" \
        --group-by Type="DIMENSION",Key="SERVICE" \
        --output json > "$OUTPUT_DIR/cost_by_service_${TIMESTAMP}.json" 2>/dev/null

    # Get Reserved Instance recommendations
    echo "Getting Reserved Instance recommendations..."
    aws ce get-reservation-purchase-recommendation \
        --service "Amazon Elastic Compute Cloud - Compute" \
        --output json > "$OUTPUT_DIR/ri_recommendations_${TIMESTAMP}.json" 2>/dev/null

    # Get Savings Plans recommendations
    echo "Getting Savings Plans recommendations..."
    aws ce get-savings-plans-purchase-recommendation \
        --savings-plans-type "COMPUTE_SP" \
        --term-in-years "ONE_YEAR" \
        --payment-option "PARTIAL_UPFRONT" \
        --output json > "$OUTPUT_DIR/savings_plans_recommendations_${TIMESTAMP}.json" 2>/dev/null

    echo ""
    echo "=== Validation Results ==="
    check_json_content "$OUTPUT_DIR/rightsizing_recommendations_${TIMESTAMP}.json" "Rightsizing Recommendations"
    check_json_content "$OUTPUT_DIR/cost_by_service_${TIMESTAMP}.json" "Cost by Service Analysis"
    check_json_content "$OUTPUT_DIR/ri_recommendations_${TIMESTAMP}.json" "Reserved Instance Recommendations"
    check_json_content "$OUTPUT_DIR/savings_plans_recommendations_${TIMESTAMP}.json" "Savings Plans Recommendations"
    
    echo ""
    echo "=== Cost Advisor Summary ==="
    echo "Reports generated:"
    echo "- $OUTPUT_DIR/rightsizing_recommendations_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/cost_by_service_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/ri_recommendations_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/savings_plans_recommendations_${TIMESTAMP}.json"
    echo ""
    echo -e "${YELLOW}If files are empty or contain no recommendations:${NC}"
    echo "1. Run setup-cost-explorer.sh to check your AWS setup"
    echo "2. Enable Cost Explorer and Rightsizing in AWS Console"
    echo "3. Wait 24 hours for data processing"
    echo "4. Ensure you have EC2 instances running for recommendations"
    echo ""
    echo "Cost advisor analysis completed!"
}

# Execute the main function
generate_cost_advisor_report

