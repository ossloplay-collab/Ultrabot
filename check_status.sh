#!/bin/bash
# Global Status Check Script for Linux/Mac
# Usage: ./check_status.sh

set -e

echo "🌍 Starting Global Status Check..."

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

# Run the Python script
python3 check_status.py

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✅ Status check completed successfully"
else
    echo ""
    echo "❌ Status check failed"
    exit 1
fi
