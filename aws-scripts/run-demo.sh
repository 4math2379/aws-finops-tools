#!/bin/bash

# Demo script to run all FinOps scripts and generate sample data

echo "=== AWS FinOps Demo Data Generation ==="
echo "This script will run all FinOps scripts to generate sample data for the dashboard"
echo ""

# Run all the scripts
echo "Running cost and usage analysis..."
./get-cost-usage.sh

echo ""
echo "Running budget status check..."
./get-budget-status.sh

echo ""
echo "Running RI utilization analysis..."
./get-ri-utilization.sh

echo ""
echo "Running cost forecasting..."
./forecast-costs.sh

echo ""
echo "Running Savings Plans analysis..."
./get-savings-plans.sh

echo ""
echo "Running cost optimization analysis..."
./cost-optimization.sh

echo ""
echo "Running cost trend analysis..."
./analyze-cost-trends.sh

echo ""
echo "Exporting data to CSV..."
./export-cost-csv.sh

echo ""
echo "=== Demo Complete ==="
echo ""
echo "Data files have been generated in /output directory"
echo ""
echo "You can now view the dashboard at:"
echo "  http://localhost:8080"
echo ""
echo "API endpoints available at:"
echo "  http://localhost:8081/api/health"
echo "  http://localhost:8081/api/latest-data"
echo "  http://localhost:8081/api/files"
echo ""
