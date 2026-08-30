# AWS S3 Backend Configuration

This guide details how to configure Terraform to use an **AWS S3 Remote State Backend** using partial configuration (`backend-config`) to manage state storage securely.

---

## ⚙️ Terraform Configuration

Define the backend block in your Terraform configuration (e.g., `provider.tf`). Leave environment-specific parameters (`bucket`, `key`, `region`) unconfigured so they can be injected dynamically:

```hcl
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## 🛠️ Local Setup & Configuration

### 1. Create `backend.tfvars`

Create a `backend.tfvars` file in your root working directory to define the Terraform backend variables:

```hcl
bucket = "cloud-architect-for-microservice-state"
key    = "prod/terraform.tfstate"
region = "eu-west-3"
```

### 2. Configure AWS Credentials

If you manage your credentials via ~/.aws/credentials (or ~/.aws/config) and are not using the default profile, export the AWS_PROFILE environment variable pointing to your specific profile name:

```bash
export AWS_PROFILE="your-named-profile"
```


## Initialization

Initialize Terraform by supplying the backend.tfvars file via the -backend-config flag:
```hcl
terraform init -backend-config=backend.tfvars
```