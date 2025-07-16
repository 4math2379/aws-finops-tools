#!/bin/bash

# This script analyzes cost trends and patterns using AWS Cost Explorer

# set -e removed to allow graceful error handling

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Date ranges for trend analysis
END_DATE=$(date +"%Y-%m-%d")
START_DATE_90=$(date -d "90 days ago" +"%Y-%m-%d")
START_DATE_30=$(date -d "30 days ago" +"%Y-%m-%d")

function analyze_cost_trends() {
    echo "=== AWS Cost Trend Analysis ==="
    echo "Account: $ACCOUNT_NAME"
    echo "Analysis Period: $START_DATE_90 to $END_DATE"
    echo ""

    # Get daily cost trends for the last 90 days
    echo "Analyzing daily cost trends (last 90 days)..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE_90",End="$END_DATE" \
        --granularity DAILY \
        --metrics BlendedCost \
        --output json > "$OUTPUT_DIR/cost_trends_daily_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Daily cost trends retrieved successfully"
    else
        echo "⚠ Daily cost trends not available"
    fi

    # Get monthly cost trends for the last 90 days
    echo "Analyzing monthly cost trends..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE_90",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost UnblendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output json > "$OUTPUT_DIR/cost_trends_monthly_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Monthly cost trends retrieved successfully"
    else
        echo "⚠ Monthly cost trends not available"
    fi

    # Get cost trends by usage type
    echo "Analyzing cost trends by usage type..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE_30",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=USAGE_TYPE \
        --output json > "$OUTPUT_DIR/cost_trends_usage_type_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Cost trends by usage type retrieved successfully"
    else
        echo "⚠ Cost trends by usage type not available"
    fi

    # Get cost trends by region
    echo "Analyzing cost trends by region..."
    if aws ce get-cost-and-usage \
        --time-period Start="$START_DATE_30",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=REGION \
        --output json > "$OUTPUT_DIR/cost_trends_region_${TIMESTAMP}.json" 2>/dev/null; then
        echo "✓ Cost trends by region retrieved successfully"
    else
        echo "⚠ Cost trends by region not available"
    fi

    # Calculate cost change percentage
    echo "Calculating cost change trends..."
    if CURRENT_MONTH_COST=$(aws ce get-cost-and-usage \
        --time-period Start="$START_DATE_30",End="$END_DATE" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --output text --query 'ResultsByTime[0].Total.BlendedCost.Amount' 2>/dev/null); then
        
        PREVIOUS_MONTH_COST=$(aws ce get-cost-and-usage \
            --time-period Start="$(date -d "60 days ago" +"%Y-%m-%d")",End="$START_DATE_30" \
            --granularity MONTHLY \
            --metrics BlendedCost \
            --output text --query 'ResultsByTime[0].Total.BlendedCost.Amount' 2>/dev/null || echo "0")
        
        if [ "$PREVIOUS_MONTH_COST" != "0" ] && [ "$PREVIOUS_MONTH_COST" != "None" ]; then
            COST_CHANGE=$(echo "scale=2; (($CURRENT_MONTH_COST - $PREVIOUS_MONTH_COST) / $PREVIOUS_MONTH_COST) * 100" | bc -l 2>/dev/null || echo "N/A")
            echo "✓ Cost change analysis completed"
        else
            COST_CHANGE="N/A"
            echo "⚠ Cost change analysis not available (insufficient data)"
        fi
    else
        CURRENT_MONTH_COST="N/A"
        COST_CHANGE="N/A"
        echo "⚠ Cost change analysis not available"
    fi

    echo ""
    echo "=== Cost Trend Summary ==="
    echo "Current Month Cost: \$${CURRENT_MONTH_COST}"
    echo "Cost Change (Month-over-Month): ${COST_CHANGE}%"
    echo ""
    echo "Reports saved to:"
    echo "- $OUTPUT_DIR/cost_trends_daily_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/cost_trends_monthly_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/cost_trends_usage_type_${TIMESTAMP}.json"
    echo "- $OUTPUT_DIR/cost_trends_region_${TIMESTAMP}.json"
    echo ""
    echo "Cost trend analysis completed successfully!"
}

# Execute the main function
analyze_cost_trends
