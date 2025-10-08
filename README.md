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
    - [Prerequisites](#prerequisites)
  - [eks-attach.sh](#eks-attachsh)
    - [Remote Usage](#remote-usage-1)
      - [1. Connect to EKS cluster](#1-connect-to-eks-cluster)
      - [2. Connect with role assumption](#2-connect-with-role-assumption)
      - [3. Connect and launch k9s](#3-connect-and-launch-k9s)
    - [Local Usage](#local-usage-1)
      - [1. Basic EKS connection (local)](#1-basic-eks-connection-local)
      - [2. Connect with role assumption (local)](#2-connect-with-role-assumption-local)
      - [3. Connect and launch k9s (local)](#3-connect-and-launch-k9s-local)
      - [4. Advanced usage examples](#4-advanced-usage-examples)
    - [Options](#options-1)
    - [Prerequisites](#prerequisites-1)

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

### Prerequisites

- AWS CLI installed and configured
- `jq` installed (for JSON processing in some examples)
- Valid AWS SSO configuration or existing AWS credentials
- Bash shell (Google Bash Style Guide compliant)

## eks-attach.sh

EKS cluster connection script that automatically configures kubectl and optionally assumes IAM roles for access.

### Remote Usage

Execute directly from GitHub without downloading:

#### 1. Connect to EKS cluster

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/eks-attach.sh) \
  --cluster-name my-cluster --region us-west-2
```

#### 2. Connect with role assumption

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/eks-attach.sh) \
  --cluster-name my-cluster --region us-west-2 \
  --role-arn arn:aws:iam::123456789012:role/EKSAdminRole
```

#### 3. Connect and launch k9s

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dragoscops/aws-tools/refs/heads/main/eks-attach.sh) \
  --cluster-name my-cluster --region us-west-2 --k9s
```

### Local Usage

For repeated use, clone the repository first:

```bash
# Clone the repository
git clone https://github.com/dragoscops/aws-tools.git
cd aws-tools

# Make script executable
chmod +x eks-attach.sh
```

#### 1. Basic EKS connection (local)

```bash
./eks-attach.sh --cluster-name my-cluster --region us-west-2
```

#### 2. Connect with role assumption (local)

```bash
./eks-attach.sh --cluster-name my-cluster --region us-west-2 \
  --role-arn arn:aws:iam::123456789012:role/EKSAdminRole
```

#### 3. Connect and launch k9s (local)

```bash
./eks-attach.sh --cluster-name my-cluster --region us-west-2 --k9s
```

#### 4. Advanced usage examples

```bash
# Connect to production cluster with cross-account role
./eks-attach.sh \
  --cluster-name prod-cluster \
  --region eu-west-1 \
  --role-arn arn:aws:iam::987654321098:role/CrossAccountEKSRole \
  --k9s

# Connect to development cluster (same account)
./eks-attach.sh --cluster-name dev-cluster --region us-east-1
```

### Options

- `--cluster-name NAME` - EKS cluster name (required)
- `--region REGION` - AWS region where the cluster is located (required)
- `--role-arn ARN` - IAM role ARN to assume for cluster access (optional)
- `--k9s` - Launch k9s terminal UI after connecting (optional)

### Prerequisites

- AWS CLI installed and configured
- `kubectl` installed
- `jq` installed (for role assumption)
- `k9s` installed (optional, only if using `--k9s` flag)
- Bash shell (Google Bash Style Guide compliant)
- Valid AWS credentials or SSO session
