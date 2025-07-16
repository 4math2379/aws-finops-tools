#!/bin/bash

# This script identifies cost optimization opportunities using AWS Cost Explorer and other services

# set -e removed to allow graceful error handling

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Date range (last 30 days)
END_DATE=$(date +"%Y-%m-%d")
START_DATE=$(date -d "30 days ago" +"%Y-%m-%d")

function get_cost_optimization_recommendations() {
    echo "=== AWS Cost Optimization Analysis ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Analysis Period: $START_DATE to $END_DATE"
    echo ""

    # Get rightsizing recommendations
    echo "Getting rightsizing recommendations..."
    if aws ce get-rightsizing-recommendation \
        --service EC2-Instance \
        --configuration '{"RecommendationTarget":"SAME_INSTANCE_FAMILY","BenefitsConsidered":true}' \
        --output json > "$OUTPUT_DIR/rightsizing_recommendations_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Rightsizing recommendations retrieved successfully"
    else
        echo "⚠ Rightsizing recommendations not available (may require EC2 instances to analyze)"
    fi

    # Get Reserved Instance recommendations
    echo "Getting Reserved Instance recommendations..."
    if aws ce get-reservation-purchase-recommendation \
        --service EC2-Instance \
        --output json > "$OUTPUT_DIR/ri_purchase_recommendations_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Reserved Instance recommendations retrieved successfully"
    else
        echo "⚠ Reserved Instance recommendations not available"
    fi

    # Get Savings Plans recommendations
    echo "Getting Savings Plans recommendations..."
    if aws ce get-savings-plans-purchase-recommendation \
        --savings-plans-type COMPUTE_SP \
        --term-in-years ONE_YEAR \
        --payment-option NO_UPFRONT \
        --output json > "$OUTPUT_DIR/savings_plans_recommendations_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Savings Plans recommendations retrieved successfully"
    else
        echo "⚠ Savings Plans recommendations not available"
    fi

    # Get usage-based recommendations
    echo "Getting usage-based cost recommendations..."
    if aws ce get-usage-forecast \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metric USAGE_QUANTITY \
        --output json > "$OUTPUT_DIR/usage_forecast_optimization_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Usage forecast retrieved successfully"
    else
        echo "⚠ Usage forecast not available"
    fi

    # Analyze top cost drivers
    echo "Analyzing top cost drivers..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/top_cost_drivers_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Top cost drivers analysis completed successfully"
    else
        echo "⚠ Top cost drivers analysis failed"
    fi

    # Get cost anomaly detection
    echo "Checking for cost anomalies..."
    if aws ce get-anomalies \
        --date-interval StartDate="$START_DATE",EndDate="$END_DATE" \
        --output json > "$OUTPUT_DIR/cost_anomalies_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Cost anomaly detection completed successfully"
    else
        echo "⚠ Cost anomaly detection not available (may need to be enabled first)"
    fi

    echo ""
    echo "=== Cost Optimization Summary ==="
    echo "Reports generated:"
    echo "- $OUTPUT_DIR/rightsizing_recommendations_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/ri_purchase_recommendations_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/savings_plans_recommendations_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/usage_forecast_optimization_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/top_cost_drivers_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/cost_anomalies_${TIMESTAMP}.json"
    echo ""
    echo "Cost optimization analysis completed successfully!"
}

# Execute the main function
get_cost_optimization_recommendations
