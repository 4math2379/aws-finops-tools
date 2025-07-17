#!/bin/bash

# Cleanup script for AWS Cost Explorer data

# Configuration
OUTPUT_DIR="/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Confirm before deletion
read -p "Are you sure you want to delete the generated data in $OUTPUT_DIR? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Deleting files in $OUTPUT_DIR..."
    if rm -rf "$OUTPUT_DIR"/*; then
        echo -e "${GREEN}✓ Cleanup complete!${NC}"
    else
        echo -e "${RED}✗ Failed to delete some files. Check permissions.${NC}"
    fi
else
    echo ""
    echo "Cleanup cancelled."
fi
