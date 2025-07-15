#!/bin/bash

# This script retrieves Reserved Instance utilization data

set -e

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
    aws ce get-reservation-utilization \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/ri_utilization_${TIMESTAMP}.json"

    # Get RI coverage
    echo "Getting Reserved Instance coverage..."
    aws ce get-reservation-coverage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/ri_coverage_${TIMESTAMP}.json"

    # Get RI recommendations
    echo "Getting Reserved Instance recommendations..."
    aws ce get-reservation-purchase-recommendation \
        --service EC2-Instance \
        --output json > "$OUTPUT_DIR/ri_recommendations_${TIMESTAMP}.json"

    # Calculate average utilization
    AVG_UTILIZATION=$(aws ce get-reservation-utilization \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --output text --query 'Total.UtilizationPercentage')

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
