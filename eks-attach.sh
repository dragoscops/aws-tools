#!/bin/bash

set -e

# === Defaults ===
LAUNCH_K9S=false
ASSUME_ROLE=false

# === Parse arguments ===
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --role-arn)
      ROLE_ARN="$2"
      ASSUME_ROLE=true
      shift; shift
      ;;
    --cluster-name)
      CLUSTER_NAME="$2"
      shift; shift
      ;;
    --region)
      REGION="$2"
      shift; shift
      ;;
    --k9s)
      LAUNCH_K9S=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--role-arn <ARN>] --cluster-name <NAME> --region <REGION> [--k9s]"
      exit 1
      ;;
  esac
done

# === Validate required inputs ===
if [[ -z "$CLUSTER_NAME" || -z "$REGION" ]]; then
  echo "Missing required arguments."
  echo "Usage: $0 [--role-arn <ARN>] --cluster-name <NAME> --region <REGION> [--k9s]"
  exit 1
fi

# === Assume role if needed ===
if $ASSUME_ROLE; then
  echo "[1] Assuming role: $ROLE_ARN"
  SESSION_NAME="eks-session-$(whoami)"
  CREDS=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --query 'Credentials' \
    --output json)

  export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.SessionToken')
fi

# === Update kubeconfig ===
echo "[2] Updating kubeconfig for EKS cluster: $CLUSTER_NAME in region: $REGION"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

# === Test kubectl access ===
echo "[3] Verifying connection with kubectl"
kubectl get nodes

# === Optionally launch k9s ===
if $LAUNCH_K9S; then
  if command -v k9s &> /dev/null; then
    echo "[4] Launching k9s..."
    k9s
  else
    echo "[4] k9s not found. Please install it or skip --k9s"
  fi
fi
