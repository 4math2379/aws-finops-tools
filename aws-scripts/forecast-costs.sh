#!/bin/bash

# This script forecasts future costs using AWS Cost Explorer API

# set -e removed to allow graceful error handling

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Date range for forecast (next 90 days)
START_DATE=$(date +"%Y-%m-%d")
END_DATE=$(date -d "90 days" +"%Y-%m-%d")

function forecast_costs() {
    echo "=== AWS Cost Forecast ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Forecast Period: $START_DATE to $END_DATE"
    echo ""

    # Get cost forecast
    echo "Generating cost forecast..."
    if aws ce get-cost-forecast \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metric UNBLENDED_COST \
        --prediction-interval-level 80 \
        --output json > "$OUTPUT_DIR/cost_forecast_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Cost forecast generated successfully"
        
        # Get forecast summary
        FORECAST_AMOUNT=$(aws ce get-cost-forecast \
            --time-period Start="$START_DATE",End="$END_DATE" \
            --granularity MONTHLY \
            --metric UNBLENDED_COST \
            --output text --query 'Total.Amount' 2>/dev/null || echo "N/A")
    else
        echo "⚠ Cost forecast not available (requires historical data)"
        FORECAST_AMOUNT="N/A"
    fi

    # Get usage forecast
    echo "Generating usage forecast..."
    if aws ce get-usage-forecast \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metric USAGE_QUANTITY \
        --prediction-interval-level 80 \
        --output json > "$OUTPUT_DIR/usage_forecast_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Usage forecast generated successfully"
    else
        echo "⚠ Usage forecast not available (requires historical data)"
    fi

    echo ""
    echo "=== Forecast Summary ==="
    echo "Predicted Cost (Next 90 days): \$${FORECAST_AMOUNT}"
    echo ""
    echo "Reports saved to:"
    echo "- $OUTPUT_DIR/cost_forecast_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/usage_forecast_${TIMESTAMP}.json"
    echo ""
    echo "Cost forecasting completed successfully!"
}

# Execute the main function
forecast_costs
