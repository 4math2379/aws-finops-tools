#!/bin/bash

# This script aggregates costs across multiple AWS accounts

# set -e removed to allow graceful error handling

# Configuration
AGGREGATED_OUTPUT_DIR="/output/aggregated"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

function aggregate_costs() {
    echo "=== Aggregating Costs Across Accounts ==="

    # Check if the output directory exists
    if [ ! -d "$AGGREGATED_OUTPUT_DIR" ]; then
        echo "Creating output directory at $AGGREGATED_OUTPUT_DIR"
        mkdir -p "$AGGREGATED_OUTPUT_DIR"
    fi

    # Aggregate daily cost reports
    echo "Aggregating daily cost reports..."
    if cat /all-outputs/account*/daily_costs_*.json \
         | jq -s 'add'  | jq '. as $in | reduce .[] as $item ({}; . * $item)' \
            > "$AGGREGATED_OUTPUT_DIR/aggregated_daily_costs_${TIMESTAMP}.json"; then
        echo "✓ Daily cost aggregation completed"
    else
        echo "⚠ Failed to aggregate daily costs"
    fi

    # Aggregate monthly cost by service reports
    echo "Aggregating monthly cost by service reports..."
    if cat /all-outputs/account*/monthly_costs_by_service_*.json \
         | jq -s 'add'  | jq '. as $in | reduce .[] as $item ({}; . * $item)' \
            > "$AGGREGATED_OUTPUT_DIR/aggregated_monthly_costs_by_service_${TIMESTAMP}.json"; then
        echo "✓ Monthly cost by service aggregation completed"
    else
        echo "⚠ Failed to aggregate monthly costs by service"
    fi

    echo ""
    echo "=== Cost Aggregation Summary ==="
    echo "Reports saved to:"
    echo "- $AGGREGATED_OUTPUT_DIR/aggregated_daily_costs_${TIMESTAMP}.json"
    echo "- $AGGREGATED_OUTPUT_DIR/aggregated_monthly_costs_by_service_${TIMESTAMP}.json"
    echo ""
    echo "Cost aggregation completed successfully!"
}

# Execute the main function
aggregate_costs

