#!/bin/bash

# This script retrieves Savings Plans utilization and coverage data

# set -e removed to allow graceful error handling

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Date range (last 30 days)
END_DATE=$(date +"%Y-%m-%d")
START_DATE=$(date -d "30 days ago" +"%Y-%m-%d")

function get_savings_plans() {
    echo "=== Savings Plans Utilization Report ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Period: $START_DATE to $END_DATE"
    echo ""

    # Get Savings Plans utilization
    echo "Getting Savings Plans utilization..."
    if aws ce get-savings-plans-utilization \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --output json > "$OUTPUT_DIR/savings_plans_utilization_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Savings Plans utilization retrieved successfully"
    else
        echo "⚠ Savings Plans utilization not available (no active Savings Plans found)"
        # Create empty JSON structure
        echo '{"Total": {"Utilization": {"UtilizationPercentage": "0"}}, "ResultsByTime": []}' > "$OUTPUT_DIR/savings_plans_utilization_${TIMESTAMP}.json"
    fi

    # Get Savings Plans coverage
    echo "Getting Savings Plans coverage..."
    if aws ce get-savings-plans-coverage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/savings_plans_coverage_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Savings Plans coverage retrieved successfully"
    else
        echo "⚠ Savings Plans coverage not available"
        echo '{"ResultsByTime": []}' > "$OUTPUT_DIR/savings_plans_coverage_${TIMESTAMP}.json"
    fi

    # Get Savings Plans purchase recommendations
    echo "Getting Savings Plans purchase recommendations..."
    if aws ce get-savings-plans-purchase-recommendation \
        --savings-plans-type COMPUTE_SP \
        --term-in-years ONE_YEAR \
        --payment-option NO_UPFRONT \
        --output json > "$OUTPUT_DIR/savings_plans_purchase_recommendations_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Savings Plans purchase recommendations retrieved successfully"
    else
        echo "⚠ Savings Plans purchase recommendations not available"
        echo '{"Recommendations": []}' > "$OUTPUT_DIR/savings_plans_purchase_recommendations_${TIMESTAMP}.json"
    fi

    # Get Savings Plans utilization summary
    echo "Getting Savings Plans utilization summary..."
    if SP_UTILIZATION=$(aws ce get-savings-plans-utilization \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --output text --query 'Total.Utilization.UtilizationPercentage' 2>/dev/null); then
        echo "✓ Utilization summary retrieved: ${SP_UTILIZATION}%"
    else
        SP_UTILIZATION="N/A"
        echo "⚠ Utilization summary not available"
    fi

    echo ""
    echo "=== Savings Plans Summary ==="
    echo "Average Utilization: ${SP_UTILIZATION}%"
    echo ""
    echo "Reports saved to:"
    echo "- $OUTPUT_DIR/savings_plans_utilization_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/savings_plans_coverage_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/savings_plans_purchase_recommendations_${TIMESTAMP}.json"
    echo ""
    echo "Savings Plans analysis completed successfully!"
}

# Execute the main function
get_savings_plans
