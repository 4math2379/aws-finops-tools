#!/bin/bash

# This script exports cost data to CSV format using AWS Cost Explorer API

set -e

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Date range (last 30 days)
END_DATE=$(date +"%Y-%m-%d")
START_DATE=$(date -d "30 days ago" +"%Y-%m-%d")

function export_cost_to_csv() {
    echo "=== AWS Cost Data Export to CSV ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Period: $START_DATE to $END_DATE"
    echo ""
    
    # Get daily costs for the last 30 days
    echo "Exporting daily costs to CSV..."
    aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity DAILY \
        --metrics BlendedCost UnblendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output table | tee "$OUTPUT_DIR/cost_report_${TIMESTAMP}.csv"

    echo ""
    echo "Cost data export to CSV completed successfully!"
}

# Execute the main function
export_cost_to_csv
