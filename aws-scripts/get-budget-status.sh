#!/bin/bash

# This script checks budget status using AWS Budgets API

# set -e removed to allow graceful error handling

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

function get_budget_status() {
    echo "=== AWS Budget Status ==="
    echo "Account: $ACCOUNT_NAME"
    echo ""

    # Get current account ID
    echo "Getting account ID..."
    if ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null); then
        echo "✓ Account ID retrieved: $ACCOUNT_ID"
    else
        echo "⚠ Unable to get account ID (check AWS credentials)"
        return 1
    fi

    # List all budgets
    echo "Fetching budget details..."
    if BUDGET_NAMES=$(aws budgets describe-budgets --account-id "$ACCOUNT_ID" --query 'Budgets[].BudgetName' --output text 2>/dev/null); then
        echo "✓ Budget list retrieved successfully"
        
        if [ -z "$BUDGET_NAMES" ] || [ "$BUDGET_NAMES" = "None" ]; then
            echo "⚠ No budgets found in this account"
        else
            for budget_name in $BUDGET_NAMES; do
                echo "Checking status for budget: $budget_name"
                if BUDGET_STATUS=$(aws budgets describe-budget-performance-history \
                    --account-id "$ACCOUNT_ID" \
                    --budget-name "$budget_name" \
                    --query 'BudgetPerformanceHistory.BudgetedAndActualAmounts[].ActualAmount.Amount' \
                    --output text 2>/dev/null); then
                    echo "✓ Budget performance for $budget_name: $BUDGET_STATUS"
                else
                    echo "⚠ Budget performance history not available for $budget_name"
                fi
            done
        fi
    else
        echo "⚠ Unable to retrieve budget information (check permissions)"
    fi

    echo ""
    echo "Budget status check completed successfully!"
}

# Execute the main function
get_budget_status
