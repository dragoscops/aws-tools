#!/bin/bash

set -e

# === Defaults ===
PROFILE=

TODO:

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

aws-creds() {
  local PROFILE=${1-${AWS_PROFILE:-default}}
  local CREDS

  grep "$PROFILE" ~/.aws/config >/dev/null || {
    echo "AWS SSO Profile is not configured. Please configure it using \`aws configure sso\`"
    exit 1
  }

  echo "You may not ... ???? SSO shit..." >&2
  if ! CREDS=$(aws configure export-credentials --profile "$PROFILE" --format env 2>/dev/null); then
    echo "SSO cache for profile '$PROFILE' is expired – firing authentication..." >&2
    aws sso login --profile "$PROFILE" || {
      echo "Authentication failed or aborted. No credentials exported" >&2
      return 1
    }
    CREDS=$(aws configure export-credentials --profile "$PROFILE" --format env)
  fi
  eval "$CREDS"
  echo "creds valid until: "
  node -p 'new Date(process.env.AWS_CREDENTIAL_EXPIRATION).toTimeString()'
}
