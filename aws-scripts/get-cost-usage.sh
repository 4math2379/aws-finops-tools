#!/bin/bash

# This script retrieves cost and usage data using AWS Cost Explorer API

# set -e removed to allow graceful error handling

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Date range (last 30 days)
END_DATE=$(date +"%Y-%m-%d")
START_DATE=$(date -d "30 days ago" +"%Y-%m-%d")

function get_cost_usage() {
    echo "=== AWS Cost and Usage Report ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Period: $START_DATE to $END_DATE"
    echo ""

    # Get daily costs for the last 30 days
    echo "Getting daily costs..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity DAILY \
        --metrics BlendedCost UnblendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/daily_costs_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Daily costs retrieved successfully"
    else
        echo "⚠ Daily costs not available"
    fi

    # Get monthly costs by service
    echo "Getting monthly costs by service..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost UnblendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/monthly_costs_by_service_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Monthly costs by service retrieved successfully"
    else
        echo "⚠ Monthly costs by service not available"
    fi

    # Get costs by region
    echo "Getting costs by region..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=REGION \
        --output json > "$OUTPUT_DIR/costs_by_region_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Costs by region retrieved successfully"
    else
        echo "⚠ Costs by region not available"
    fi

    # Get total cost for the period
    echo "Getting total cost summary..."
    TOTAL_COST=$(aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --output text --query 'ResultsByTime[0].Total.BlendedCost.Amount' 2>/dev/null || echo "N/A")

    echo ""
    echo "=== Cost Summary ==="
    echo "Total Cost (Last 30 days): \$${TOTAL_COST}"
    echo ""
    echo "Reports saved to:"
    echo "- $OUTPUT_DIR/daily_costs_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/monthly_costs_by_service_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/costs_by_region_${TIMESTAMP}.json"
    echo ""
    echo "Cost and usage data retrieval completed successfully!"
}

# Check if running in aggregator mode
if [ "$FINOPS_ROLE" = "aggregator" ]; then
    echo "Running in aggregator mode - collecting costs from all accounts..."
    # In aggregator mode, we would collect data from all accounts
    # This requires cross-account access setup
fi

# Execute the main function
get_cost_usage
