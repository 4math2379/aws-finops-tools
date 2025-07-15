#!/bin/bash

# This script checks budget status using AWS Budgets API

set -e

# Configuration
ACCOUNT_NAME=${ACCOUNT_NAME:-"unknown"}
OUTPUT_DIR="/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

function get_budget_status() {
    echo "=== AWS Budget Status ==="
    echo "Account: $ACCOUNT_NAME"
    echo ""

    # List all budgets
    echo "Fetching budget details..."
    BUDGET_NAMES=$(aws budgets describe-budgets --query 'Budgets[].BudgetName' --output text)
    
    if [ -z "$BUDGET_NAMES" ]; then
        echo "No budgets found."
    else
        for budget_name in $BUDGET_NAMES; do
            echo "Checking status for budget: $budget_name"
            BUDGET_STATUS=$(aws budgets describe-budget-performance-history \
                --budget-name "$budget_name" \
                --query 'BudgetPerformanceHistory.BudgetedAndActualAmounts[].ActualAmount.Amount' \
                --output text)
            
            echo "Current spend for $budget_name: $BUDGET_STATUS"
        done
    fi

    echo ""
    echo "Budget status check completed successfully!"
}

# Execute the main function
get_budget_status
