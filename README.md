# aws-tools

- [aws-tools](#aws-tools)
  - [get-creds.sh](#get-credssh)
    - [Remote Usage](#remote-usage)
      - [1. Save environment variables to file](#1-save-environment-variables-to-file)
      - [2. Evaluate and export to current shell](#2-evaluate-and-export-to-current-shell)
    - [Local Usage](#local-usage)
      - [1. Save environment variables to file (local)](#1-save-environment-variables-to-file-local)
      - [2. Evaluate and export to current shell (local)](#2-evaluate-and-export-to-current-shell-local)
      - [3. Source and use function (bash/zsh only)](#3-source-and-use-function-bashzsh-only)
      - [4. Configure new SSO profile](#4-configure-new-sso-profile)
      - [5. Get JSON output for scripting](#5-get-json-output-for-scripting)
    - [Options](#options)
    - [Output Formats](#output-formats)
  - [eks-attach.sh](#eks-attachsh)


## get-creds.sh

AWS SSO credential management script with automatic profile configuration and multiple export formats.

### Remote Usage

Execute directly from GitHub without downloading:

#### 1. Save environment variables to file

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/get-creds.sh) \
  --profile default --format env >> .env
```

#### 2. Evaluate and export to current shell

```bash
eval "$(bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/get-creds.sh) \
  --profile default --format eval)"
```

### Local Usage

For full functionality including sourcing, clone the repository first:

```bash
# Clone the repository
git clone https://github.com/dragoscops/aws-tools.git
cd aws-tools

# Make script executable
chmod +x get-creds.sh
```

#### 1. Save environment variables to file (local)

```bash
./get-creds.sh --profile default --format env >> .env
```

#### 2. Evaluate and export to current shell (local)

```bash
eval "$(./get-creds.sh --profile default --format eval)"
```

#### 3. Source and use function (bash/zsh only)

```bash
# Source the script to load the aws-creds function
source ./get-creds.sh

# Then call the function with desired options
aws-creds --profile default --format export
```

#### 4. Configure new SSO profile

```bash
./get-creds.sh --configure --profile staging
# Or using the function after sourcing
aws-creds --configure --profile staging
```

#### 5. Get JSON output for scripting

```bash
./get-creds.sh --profile production --format json | jq .AccessKeyId
# Or using the function after sourcing
aws-creds --profile production --format json | jq .AccessKeyId
```

### Options

- `--profile PROFILE` - AWS profile name (default: `$AWS_PROFILE` or 'default')
- `--region REGION` - AWS region (default: `$AWS_REGION` or 'us-east-1')
- `--format FORMAT` - Output format: `env|json|eval|export` (default: env)
- `--configure` - Force SSO profile configuration
- `--help` - Show help message

### Output Formats

- `env` - Plain environment variables (`AWS_ACCESS_KEY_ID=...`)
- `json` - JSON format for programmatic use
- `eval` - Export statements for eval usage
- `export` - Direct exports (use with source)

## eks-attach.sh

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/eks-attach.sh) \
  --cluster-name <NAME> --region <REGION> [--k9s][--role-arn <ARN>]
```
