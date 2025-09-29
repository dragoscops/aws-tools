#!/bin/bash
#
# EKS Cluster Attachment Script
#
# This script connects to an Amazon EKS cluster by updating kubectl configuration
# and optionally assuming IAM roles for cross-account access.
#
# Usage:
#   eks-attach.sh [--role-arn <ARN>] --cluster-name <NAME> --region <REGION> [--k9s]
#
# Options:
#   --cluster-name NAME  EKS cluster name (required)
#   --region REGION      AWS region where cluster is located (required)
#   --role-arn ARN       IAM role ARN to assume for access (optional)
#   --k9s                Launch k9s terminal UI after connecting (optional)
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - kubectl installed
#   - jq installed (for role assumption)
#   - k9s installed (optional, only if using --k9s flag)
#   - Valid AWS credentials or SSO session
#

set -euo pipefail

# Default values
LAUNCH_K9S="false"
ASSUME_ROLE="false"
ROLE_ARN=""
CLUSTER_NAME=""
REGION=""

#######################################
# Print usage information
# Outputs:
#   Usage information to stderr
#######################################
usage() {
  cat >&2 <<EOF
Usage: $(basename "${0}") [OPTIONS]

EKS Cluster Attachment Script

OPTIONS:
  --cluster-name NAME  EKS cluster name (required)
  --region REGION      AWS region where cluster is located (required)
  --role-arn ARN       IAM role ARN to assume for access (optional)
  --k9s                Launch k9s terminal UI after connecting (optional)
  --help              Show this help message

EXAMPLES:
  $(basename "${0}") --cluster-name my-cluster --region us-west-2
  $(basename "${0}") --cluster-name prod --region us-east-1 --role-arn arn:aws:iam::123456789012:role/EKSRole --k9s
EOF
}

#######################################
# Parse command line arguments
# Arguments:
#   Command line arguments
# Sets:
#   Global variables for script configuration
#######################################
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    local key="${1}"
    case "${key}" in
      --role-arn)
        [[ -n "${2:-}" ]] || { echo "ERROR: --role-arn requires a value" >&2; exit 1; }
        ROLE_ARN="${2}"
        ASSUME_ROLE="true"
        shift 2
        ;;
      --cluster-name)
        [[ -n "${2:-}" ]] || { echo "ERROR: --cluster-name requires a value" >&2; exit 1; }
        CLUSTER_NAME="${2}"
        shift 2
        ;;
      --region)
        [[ -n "${2:-}" ]] || { echo "ERROR: --region requires a value" >&2; exit 1; }
        REGION="${2}"
        shift 2
        ;;
      --k9s)
        LAUNCH_K9S="true"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "ERROR: Unknown option: ${1}" >&2
        usage
        exit 1
        ;;
    esac
  done
}

#######################################
# Validate required inputs
# Globals:
#   CLUSTER_NAME, REGION
# Returns:
#   Exits with error if required arguments are missing
#######################################
validate_inputs() {
  if [[ -z "${CLUSTER_NAME}" || -z "${REGION}" ]]; then
    echo "ERROR: Missing required arguments." >&2
    usage
    exit 1
  fi
}

#######################################
# Assume IAM role for cross-account access
# Globals:
#   ROLE_ARN
# Exports:
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
#######################################
assume_iam_role() {
  echo "[1] Assuming role: ${ROLE_ARN}"

  local session_name="eks-session-$(whoami)"
  local creds

  if ! creds=$(aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "${session_name}" \
    --query 'Credentials' \
    --output json); then
    echo "ERROR: Failed to assume role ${ROLE_ARN}" >&2
    exit 1
  fi

  # Export credentials for AWS CLI to use
  export AWS_ACCESS_KEY_ID
  AWS_ACCESS_KEY_ID=$(echo "${creds}" | jq -r '.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY
  AWS_SECRET_ACCESS_KEY=$(echo "${creds}" | jq -r '.SecretAccessKey')
  export AWS_SESSION_TOKEN
  AWS_SESSION_TOKEN=$(echo "${creds}" | jq -r '.SessionToken')

  echo "Successfully assumed role: ${ROLE_ARN}"
}

#######################################
# Update kubeconfig for EKS cluster
# Globals:
#   CLUSTER_NAME, REGION
#######################################
update_kubeconfig() {
  echo "[2] Updating kubeconfig for EKS cluster: ${CLUSTER_NAME} in region: ${REGION}"

  if ! aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}"; then
    echo "ERROR: Failed to update kubeconfig for cluster ${CLUSTER_NAME}" >&2
    exit 1
  fi

  echo "Successfully updated kubeconfig"
}

#######################################
# Test kubectl access to the cluster
#######################################
test_kubectl_access() {
  echo "[3] Verifying connection with kubectl"

  if ! kubectl get nodes; then
    echo "ERROR: Failed to connect to cluster. Check your credentials and cluster access." >&2
    exit 1
  fi

  echo "Successfully verified cluster connection"
}

#######################################
# Launch k9s if requested and available
# Globals:
#   LAUNCH_K9S
#######################################
launch_k9s() {
  if [[ "${LAUNCH_K9S}" == "true" ]]; then
    if command -v k9s &> /dev/null; then
      echo "[4] Launching k9s..."
      k9s
    else
      echo "WARNING: k9s not found. Please install it or skip --k9s" >&2
      echo "Install k9s: https://k9scli.io/topics/install/" >&2
    fi
  fi
}

#######################################
# Main execution function
#######################################
main() {
  parse_arguments "$@"
  validate_inputs

  # Assume role if specified
  if [[ "${ASSUME_ROLE}" == "true" ]]; then
    assume_iam_role
  fi

  # Connect to EKS cluster
  update_kubeconfig
  test_kubectl_access

  # Optionally launch k9s
  launch_k9s

  echo "EKS connection process completed successfully!"
}

# Execute main function when script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
