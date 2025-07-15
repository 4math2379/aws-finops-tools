#!/bin/bash

# This script forecasts future costs using AWS Cost Explorer API

set -e

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
    aws ce get-cost-forecast \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metric BlendedCost \
        --prediction-interval-level 80 \
        --output json > "$OUTPUT_DIR/cost_forecast_${TIMESTAMP}.json"

    # Get usage forecast
    echo "Generating usage forecast..."
    aws ce get-usage-forecast \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metric UsageQuantity \
        --prediction-interval-level 80 \
        --output json > "$OUTPUT_DIR/usage_forecast_${TIMESTAMP}.json"

    # Get forecast summary
    FORECAST_AMOUNT=$(aws ce get-cost-forecast \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metric BlendedCost \
        --output text --query 'Total.Amount')

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
