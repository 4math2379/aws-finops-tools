#!/bin/bash

# This script retrieves Reserved Instance utilization data

# set -e removed to allow graceful error handling

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Date range (last 30 days)
END_DATE=$(date +"%Y-%m-%d")
START_DATE=$(date -d "30 days ago" +"%Y-%m-%d")

function get_ri_utilization() {
    echo "=== Reserved Instance Utilization Report ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Period: $START_DATE to $END_DATE"
    echo ""

    # Get RI utilization
    echo "Getting Reserved Instance utilization..."
    if aws ce get-reservation-utilization \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --group-by Type=DIMENSION,Key=SUBSCRIPTION_ID \
        --output json > "$OUTPUT_DIR/ri_utilization_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Reserved Instance utilization retrieved successfully"
        
        # Calculate average utilization
        AVG_UTILIZATION=$(aws ce get-reservation-utilization \
            --time-period Start="$START_DATE",End="$END_DATE" \
            --granularity MONTHLY \
            --output text --query 'Total.UtilizationPercentage' 2>/dev/null || echo "N/A")
    else
        echo "⚠ Reserved Instance utilization not available (no active RIs found)"
        AVG_UTILIZATION="N/A"
    fi

    # Get RI coverage
    echo "Getting Reserved Instance coverage..."
    if aws ce get-reservation-coverage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/ri_coverage_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Reserved Instance coverage retrieved successfully"
    else
        echo "⚠ Reserved Instance coverage not available"
    fi

    # Get RI recommendations
    echo "Getting Reserved Instance recommendations..."
    if aws ce get-reservation-purchase-recommendation \
        --service EC2-Instance \
        --output json > "$OUTPUT_DIR/ri_recommendations_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Reserved Instance recommendations retrieved successfully"
    else
        echo "⚠ Reserved Instance recommendations not available"
    fi

    echo ""
    echo "=== RI Utilization Summary ==="
    echo "Average Utilization: ${AVG_UTILIZATION}%"
    echo ""
    echo "Reports saved to:"
    echo "- $OUTPUT_DIR/ri_utilization_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/ri_coverage_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/ri_recommendations_${TIMESTAMP}.json"
    echo ""
    echo "Reserved Instance analysis completed successfully!"
}

# Execute the main function
get_ri_utilization
