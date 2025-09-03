#!/bin/bash
#
# AWS SSO Credential Management Script
#
# This script manages AWS SSO credentials with automatic profile configuration,
# multiple export formats, and credential caching.
#
# Usage:
#   get-creds.sh [OPTIONS]
#
# Options:
#   --profile PROFILE    AWS profile name (default: $AWS_PROFILE or 'default')
#   --region REGION      AWS region (default: $AWS_REGION or 'us-east-1')
#   --format FORMAT      Output format: env|json|eval|export (default: env)
#   --configure          Force SSO profile configuration
#   --help              Show this help message
#
# Formats:
#   env     - Print environment variables to stdout
#   json    - Print credentials in JSON format
#   eval    - Print eval-ready export statements
#   export  - Export variables to current shell (source this script)
#

set -euo pipefail

# Global constants
readonly SCRIPT_NAME="$(basename "${0}")"
readonly AWS_CONFIG_FILE="${HOME}/.aws/config"
readonly AWS_CREDENTIALS_FILE="${HOME}/.aws/credentials"

# Default values
readonly DEFAULT_REGION="us-east-1"
readonly DEFAULT_FORMAT="env"
readonly DEFAULT_PROFILE="default"

#######################################
# Print usage information
# Globals:
#   SCRIPT_NAME
# Arguments:
#   None
# Outputs:
#   Usage information to stdout
#######################################
usage() {
  cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

AWS SSO Credential Management Script

OPTIONS:
  --profile PROFILE    AWS profile name (default: \$AWS_PROFILE or 'default')
  --region REGION      AWS region (default: \$AWS_REGION or 'us-east-1')
  --format FORMAT      Output format: env|json|eval|export (default: env)
  --configure          Force SSO profile configuration
  --help              Show this help message

OUTPUT FORMATS:
  env     - Print environment variables (AWS_ACCESS_KEY_ID=...)
  json    - Print credentials in JSON format
  eval    - Print eval-ready export statements (export AWS_ACCESS_KEY_ID=...)
  export  - Export variables to current shell (source this script)

EXAMPLES:
  ${SCRIPT_NAME} --profile dev --format eval
  source ${SCRIPT_NAME} --profile prod --format export
  ${SCRIPT_NAME} --configure --profile staging
EOF
}

#######################################
# Print error message and exit
# Arguments:
#   Error message
# Outputs:
#   Error message to stderr
#######################################
error_exit() {
  echo "ERROR: ${1}" >&2
  exit 1
}

#######################################
# Print info message to stderr
# Arguments:
#   Info message
# Outputs:
#   Info message to stderr
#######################################
info() {
  echo "INFO: ${1}" >&2
}

#######################################
# Print warning message to stderr
# Arguments:
#   Warning message
# Outputs:
#   Warning message to stderr
#######################################
warn() {
  echo "WARN: ${1}" >&2
}

#######################################
# Parse command line arguments
# Globals:
#   AWS_PROFILE, AWS_REGION
# Arguments:
#   Command line arguments
# Returns:
#   Sets global variables: PROFILE, REGION, FORMAT, CONFIGURE_FLAG
#######################################
parse_arguments() {
  PROFILE="${AWS_PROFILE:-${DEFAULT_PROFILE}}"
  REGION="${AWS_REGION:-${DEFAULT_REGION}}"
  FORMAT="${DEFAULT_FORMAT}"
  CONFIGURE_FLAG="false"

  while [[ $# -gt 0 ]]; do
    case "${1}" in
      --profile|-p)
        [[ -n "${2:-}" ]] || error_exit "Profile name required"
        PROFILE="${2}"
        shift 2
        ;;
      --region|-r)
        [[ -n "${2:-}" ]] || error_exit "Region name required"
        REGION="${2}"
        shift 2
        ;;
      --format|-f)
        [[ -n "${2:-}" ]] || error_exit "Format required"
        case "${2}" in
          env|json|eval|export)
            FORMAT="${2}"
            ;;
          *)
            error_exit "Invalid format: ${2}. Must be one of: env, json, eval, export"
            ;;
        esac
        shift 2
        ;;
      --configure)
        CONFIGURE_FLAG="true"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error_exit "Unknown option: ${1}. Use --help for usage information."
        ;;
    esac
  done

  readonly PROFILE REGION FORMAT CONFIGURE_FLAG
}

#######################################
# Check if AWS CLI is installed
# Arguments:
#   None
# Returns:
#   0 if installed, exits with error otherwise
#######################################
check_aws_cli() {
  if ! command -v aws >/dev/null 2>&1; then
    error_exit "AWS CLI is not installed. Please install it first."
  fi
}

#######################################
# Check if profile exists in AWS config
# Arguments:
#   Profile name
# Returns:
#   0 if profile exists, 1 otherwise
#######################################
profile_exists() {
  local profile="${1}"

  [[ -f "${AWS_CONFIG_FILE}" ]] || return 1

  if [[ "${profile}" == "default" ]]; then
    grep -q "^\[default\]" "${AWS_CONFIG_FILE}" 2>/dev/null
  else
    grep -q "^\[profile ${profile}\]" "${AWS_CONFIG_FILE}" 2>/dev/null
  fi
}

#######################################
# Configure SSO profile interactively
# Arguments:
#   Profile name
#   Region
# Returns:
#   0 on success, exits on failure
#######################################
configure_sso_profile() {
  local profile="${1}"
  local region="${2}"

  info "Configuring SSO profile: ${profile}"

  # Run aws configure sso with the specified profile
  if ! aws configure sso --profile "${profile}"; then
    error_exit "Failed to configure SSO profile: ${profile}"
  fi

  # Verify the profile was created
  if ! profile_exists "${profile}"; then
    error_exit "Profile configuration failed: ${profile} not found in ${AWS_CONFIG_FILE}"
  fi

  info "Successfully configured SSO profile: ${profile}"
}

#######################################
# Get credentials from AWS SSO
# Arguments:
#   Profile name
# Returns:
#   0 on success, 1 on failure
# Outputs:
#   Sets global variables with credential data
#######################################
get_aws_credentials() {
  local profile="${1}"
  local creds_output

  info "Attempting to get credentials for profile: ${profile}"

  # Try to get credentials without login first
  if creds_output=$(aws configure export-credentials --profile "${profile}" --format env 2>/dev/null); then
    info "Using cached credentials for profile: ${profile}"
  else
    info "Cached credentials expired or not found. Initiating SSO login..."

    # Attempt SSO login
    if ! aws sso login --profile "${profile}"; then
      error_exit "SSO login failed for profile: ${profile}"
    fi

    # Try to get credentials again after login
    if ! creds_output=$(aws configure export-credentials --profile "${profile}" --format env 2>/dev/null); then
      error_exit "Failed to export credentials after SSO login for profile: ${profile}"
    fi

    info "Successfully obtained credentials after SSO login"
  fi

  # Parse the credentials from the output
  AWS_ACCESS_KEY_ID=$(echo "${creds_output}" | grep "^export AWS_ACCESS_KEY_ID=" | cut -d'=' -f2- | tr -d '"')
  AWS_SECRET_ACCESS_KEY=$(echo "${creds_output}" | grep "^export AWS_SECRET_ACCESS_KEY=" | cut -d'=' -f2- | tr -d '"')
  AWS_SESSION_TOKEN=$(echo "${creds_output}" | grep "^export AWS_SESSION_TOKEN=" | cut -d'=' -f2- | tr -d '"')
  AWS_CREDENTIAL_EXPIRATION=$(echo "${creds_output}" | grep "^export AWS_CREDENTIAL_EXPIRATION=" | cut -d'=' -f2- | tr -d '"')

  # Validate that we got the required credentials
  [[ -n "${AWS_ACCESS_KEY_ID:-}" ]] || error_exit "Failed to extract AWS_ACCESS_KEY_ID"
  [[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]] || error_exit "Failed to extract AWS_SECRET_ACCESS_KEY"
  [[ -n "${AWS_SESSION_TOKEN:-}" ]] || error_exit "Failed to extract AWS_SESSION_TOKEN"

  readonly AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_CREDENTIAL_EXPIRATION
}

#######################################
# Format expiration time in human-readable format
# Arguments:
#   ISO timestamp
# Returns:
#   Formatted time string
#######################################
format_expiration_time() {
  local expiration="${1:-}"

  if [[ -z "${expiration}" ]]; then
    echo "Unknown"
    return
  fi

  # Try to format using date command (works on macOS and Linux)
  if command -v date >/dev/null 2>&1; then
    if date -d "${expiration}" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${expiration%Z}" 2>/dev/null; then
      return
    fi
  fi

  # Fallback to raw timestamp
  echo "${expiration}"
}

#######################################
# Output credentials in requested format
# Arguments:
#   Format (env|json|eval|export)
# Globals:
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN,
#   AWS_CREDENTIAL_EXPIRATION, REGION, PROFILE
# Outputs:
#   Formatted credentials to stdout
#######################################
output_credentials() {
  local format="${1}"
  local expiration_formatted

  expiration_formatted=$(format_expiration_time "${AWS_CREDENTIAL_EXPIRATION}")

  case "${format}" in
    env)
      cat << EOF
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
AWS_DEFAULT_REGION=${REGION}
AWS_REGION=${REGION}
AWS_PROFILE=${PROFILE}
AWS_CREDENTIAL_EXPIRATION=${AWS_CREDENTIAL_EXPIRATION}
EOF
      info "Credentials valid until: ${expiration_formatted}"
      ;;

    json)
      cat << EOF
{
  "AccessKeyId": "${AWS_ACCESS_KEY_ID}",
  "SecretAccessKey": "${AWS_SECRET_ACCESS_KEY}",
  "SessionToken": "${AWS_SESSION_TOKEN}",
  "Region": "${REGION}",
  "Profile": "${PROFILE}",
  "Expiration": "${AWS_CREDENTIAL_EXPIRATION}"
}
EOF
      ;;

    eval)
      cat << EOF
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}"
export AWS_DEFAULT_REGION="${REGION}"
export AWS_REGION="${REGION}"
export AWS_PROFILE="${PROFILE}"
export AWS_CREDENTIAL_EXPIRATION="${AWS_CREDENTIAL_EXPIRATION}"
EOF
      info "Credentials valid until: ${expiration_formatted}"
      info "Run: eval \"\$(${SCRIPT_NAME} --profile ${PROFILE} --format eval)\""
      ;;

    export)
      export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
      export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
      export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}"
      export AWS_DEFAULT_REGION="${REGION}"
      export AWS_REGION="${REGION}"
      export AWS_PROFILE="${PROFILE}"
      export AWS_CREDENTIAL_EXPIRATION="${AWS_CREDENTIAL_EXPIRATION}"

      info "Credentials exported to current shell environment"
      info "Credentials valid until: ${expiration_formatted}"
      info "Profile: ${PROFILE}, Region: ${REGION}"
      ;;
  esac
}

#######################################
# Main function
# Arguments:
#   Command line arguments
#######################################
main() {
  parse_arguments "$@"
  check_aws_cli

  # Check if profile exists or needs configuration
  if [[ "${CONFIGURE_FLAG}" == "true" ]] || ! profile_exists "${PROFILE}"; then
    if [[ "${CONFIGURE_FLAG}" == "false" ]]; then
      info "Profile '${PROFILE}' not found in ${AWS_CONFIG_FILE}"
      info "Run with --configure to set up SSO profile interactively"
      error_exit "Profile configuration required"
    fi
    configure_sso_profile "${PROFILE}" "${REGION}"
  fi

  # Get and output credentials
  get_aws_credentials "${PROFILE}"
  output_credentials "${FORMAT}"
}

# Execute main function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
