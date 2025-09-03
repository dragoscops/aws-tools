# aws-tools

- [aws-tools](#aws-tools)
  - [get-creds.sh](#get-credssh)
    - [Remote Usage](#remote-usage)
      - [1. Save environment variables to file](#1-save-environment-variables-to-file)
      - [2. Evaluate and export to current shell](#2-evaluate-and-export-to-current-shell)
      - [3. Source directly (for bash/zsh compatibility)](#3-source-directly-for-bashzsh-compatibility)
    - [Options](#options)
    - [Output Formats](#output-formats)
  - [eks-attach.sh](#eks-attachsh)


## get-creds.sh

AWS SSO credential management script with automatic profile configuration and multiple export formats.

### Remote Usage

Execute directly from GitHub without downloading:

#### 1. Save environment variables to file

```bash
PROFILE=default \
bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/get-creds.sh) \
  --profile $PROFILE --format env >> .env
```

#### 2. Evaluate and export to current shell

```bash
PROFILE=default \
eval "$(bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/get-creds.sh) \
  --profile $PROFILE --format eval)"
```

#### 3. Source directly (for bash/zsh compatibility)

```bash
PROFILE=default \
source <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/get-creds.sh) \
  --profile $PROFILE --format export
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
