#!/bin/bash

# Comprehensive AWS Cost Explorer Cleanup Script
# This script cleans up all generated files from Cost Explorer scripts

# Configuration
OUTPUT_DIR="../output"
TEMP_DIR="/tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== AWS Cost Explorer Cleanup Script ===${NC}"
echo ""
echo -e "${YELLOW}WARNING: AWS Cost Explorer itself cannot be disabled once enabled.${NC}"
echo -e "${YELLOW}This script only cleans up locally generated files.${NC}"
echo ""

# Function to clean up output directory
cleanup_output_dir() {
    if [ -d "$OUTPUT_DIR" ]; then
        echo -e "${YELLOW}Found output directory: $OUTPUT_DIR${NC}"
        echo "Contents:"
        ls -la "$OUTPUT_DIR" 2>/dev/null || echo "Directory is empty or inaccessible"
        echo ""
        
        read -p "Delete all files in $OUTPUT_DIR? (y/n): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if rm -rf "$OUTPUT_DIR"/*; then
                echo -e "${GREEN}✓ Output directory cleaned${NC}"
            else
                echo -e "${RED}✗ Failed to clean output directory${NC}"
            fi
        else
            echo "Skipping output directory cleanup"
        fi
    else
        echo -e "${GREEN}✓ No output directory found${NC}"
    fi
}

# Function to clean up temp files
cleanup_temp_files() {
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    
    # List of temporary files that might be created
    temp_files=(
        "/tmp/ce_test.json"
        "/tmp/caller_identity.json"
        "/tmp/cost_explorer_*.json"
        "/tmp/test_*.json"
    )
    
    for pattern in "${temp_files[@]}"; do
        if ls $pattern 1> /dev/null 2>&1; then
            rm -f $pattern
            echo -e "${GREEN}✓ Removed temporary files matching: $pattern${NC}"
        fi
    done
}

# Function to clean up specific cost explorer files
cleanup_cost_explorer_files() {
    echo -e "${YELLOW}Cleaning up Cost Explorer specific files...${NC}"
    
    # Define patterns for cost explorer files
    patterns=(
        "*cost*"
        "*rightsizing*"
        "*ri_*"
        "*savings*plans*"
        "*forecast*"
        "*budget*"
        "*anomal*"
        "*reservation*"
        "*utilization*"
    )
    
    for account_dir in "$OUTPUT_DIR"/*/; do
        if [ -d "$account_dir" ]; then
            echo "Checking account directory: $account_dir"
            
            for pattern in "${patterns[@]}"; do
                files_found=$(find "$account_dir" -name "$pattern" -type f 2>/dev/null)
                if [ -n "$files_found" ]; then
                    echo "Found Cost Explorer files:"
                    echo "$files_found"
                    
                    read -p "Delete these Cost Explorer files? (y/n): " -n 1 -r
                    echo ""
                    
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        find "$account_dir" -name "$pattern" -type f -delete
                        echo -e "${GREEN}✓ Deleted files matching pattern: $pattern${NC}"
                    fi
                fi
            done
        fi
    done
}

# Function to display what cannot be cleaned
display_limitations() {
    echo ""
    echo -e "${YELLOW}=== IMPORTANT LIMITATIONS ===${NC}"
    echo ""
    echo -e "${RED}What CANNOT be cleaned/disabled:${NC}"
    echo "• AWS Cost Explorer service (once enabled, it stays enabled)"
    echo "• Historical cost data in AWS (stored by AWS for 13 months)"
    echo "• AWS Cost Explorer API access"
    echo "• Billing data in AWS Console"
    echo ""
    echo -e "${YELLOW}What CAN be managed:${NC}"
    echo "• Rightsizing recommendations (can be disabled in AWS Console)"
    echo "• Cost Anomaly Detection (can be disabled in AWS Console)"
    echo "• Cost budgets (can be deleted in AWS Console)"
    echo "• Local script-generated files (cleaned by this script)"
    echo ""
    echo -e "${BLUE}To disable specific features:${NC}"
    echo "1. Go to: https://console.aws.amazon.com/costmanagement/preferences"
    echo "2. Disable 'Rightsizing recommendations' if desired"
    echo "3. Go to: https://console.aws.amazon.com/costmanagement/anomaly-detection"
    echo "4. Disable Cost Anomaly Detection if desired"
    echo ""
}

# Function to show current status
show_current_status() {
    echo -e "${BLUE}=== Current Status ===${NC}"
    echo ""
    
    if [ -d "$OUTPUT_DIR" ]; then
        echo "Output directory exists: $OUTPUT_DIR"
        file_count=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l)
        echo "Total files in output directory: $file_count"
        
        if [ $file_count -gt 0 ]; then
            echo ""
            echo "File breakdown by type:"
            find "$OUTPUT_DIR" -name "*cost*" -type f 2>/dev/null | wc -l | sed 's/^/  Cost files: /'
            find "$OUTPUT_DIR" -name "*rightsizing*" -type f 2>/dev/null | wc -l | sed 's/^/  Rightsizing files: /'
            find "$OUTPUT_DIR" -name "*ri_*" -type f 2>/dev/null | wc -l | sed 's/^/  RI files: /'
            find "$OUTPUT_DIR" -name "*savings*" -type f 2>/dev/null | wc -l | sed 's/^/  Savings Plans files: /'
        fi
    else
        echo "No output directory found"
    fi
    echo ""
}

# Main menu
main_menu() {
    while true; do
        echo -e "${BLUE}=== Cleanup Options ===${NC}"
        echo "1. Show current status"
        echo "2. Clean all output files"
        echo "3. Clean specific Cost Explorer files"
        echo "4. Clean temporary files"
        echo "5. Display limitations and AWS Console instructions"
        echo "6. Exit"
        echo ""
        
        read -p "Select an option (1-6): " choice
        
        case $choice in
            1)
                show_current_status
                ;;
            2)
                cleanup_output_dir
                ;;
            3)
                cleanup_cost_explorer_files
                ;;
            4)
                cleanup_temp_files
                ;;
            5)
                display_limitations
                ;;
            6)
                echo -e "${GREEN}Cleanup script completed!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-6.${NC}"
                ;;
        esac
        echo ""
    done
}

# Start the script
main_menu
