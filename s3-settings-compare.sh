#!/bin/bash
#
# S3 Settings Comparison Script
#
# This script compares various settings between two S3 buckets to help
# identify configuration differences.
#
# Usage:
#   s3-settings-compare.sh BUCKET1 BUCKET2
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - jq installed for JSON processing
#   - Appropriate AWS permissions to read bucket configurations
#

set -euo pipefail

# Validate arguments
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 BUCKET1 BUCKET2" >&2
  echo "Compare settings between two S3 buckets" >&2
  exit 1
fi

readonly BUCKET1="${1}"
readonly BUCKET2="${2}"
readonly AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Comparing S3 buckets: ${BUCKET1} vs ${BUCKET2}"

# List of S3 API settings to compare
readonly S3_SETTINGS=(
  "get-bucket-location"
  "get-bucket-encryption"
  "get-bucket-acl"
  "get-bucket-policy"
  "get-bucket-versioning"
  "get-bucket-accelerate-configuration"
  "get-public-access-block"
  "get-bucket-logging"
  "get-bucket-lifecycle-configuration"
  "get-bucket-cors"
  "get-bucket-replication"
)

#######################################
# Compare a specific setting between two buckets
# Arguments:
#   Setting name (S3 API command without 's3api' prefix)
#   Bucket 1 name
#   Bucket 2 name
#   Region
# Outputs:
#   Formatted comparison of the setting for both buckets
#######################################
compare_bucket_setting() {
  local setting="${1}"
  local bucket1="${2}"
  local bucket2="${3}"
  local region="${4}"

  echo "=== ${setting} ==="
  echo "--- ${bucket1} ---"
  aws s3api "${setting}" --bucket "${bucket1}" --region "${region}" 2>/dev/null | jq '.' || echo "N/A"
  echo "--- ${bucket2} ---"
  aws s3api "${setting}" --bucket "${bucket2}" --region "${region}" 2>/dev/null | jq '.' || echo "N/A"
  echo ""

  # Pause for user to review (press any key to continue)
  echo "Press any key to continue..."
  read -r
}

# Main comparison loop
for setting in "${S3_SETTINGS[@]}"; do
  compare_bucket_setting "${setting}" "${BUCKET1}" "${BUCKET2}" "${AWS_REGION}"
done

echo "Comparison complete!"
