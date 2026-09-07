# Infrastructure as Code (IaC) Design

This document details the modular structure, state management, remote state sharing, and multi-tier execution lifecycle of our Terraform configurations.

---

## Table of Contents
- [Multi-Tiered Deployment Lifecycle](#multi-tiered-deployment-lifecycle)
- [Remote State Management and Isolation](#remote-state-management-and-isolation)
- [State Dependency Mapping (`terraform_remote_state`)](#state-dependency-mapping-terraform_remote_state)
- [Workspace Container Execution and Makefile Workflow](#workspace-container-execution-and-makefile-workflow)
- [Input/Output Variable Blueprint](#inputoutput-variable-blueprint)

---

## Multi-Tiered Deployment Lifecycle

To manage dependencies cleanly, avoid circular references, and isolate system failure domains, the Terraform infrastructure is partitioned into three decoupled folders:

```text
  [ 1. Bootstrap ]
          │ (Provisions State Buckets & Lock Tables)
          ▼
  [ 2. Foundation ]
          │ (Provisions Network, Cognito, API Gateway, Cluster Controls)
          ▼
  [ 3. Compute ]
            (Provisions Hosts, Load Balancers, Databases, Services, Observability)
```

### 1. The Bootstrap Tier (`/bootstrap`)
*   **Purpose**: Bootstraps the backend engine required for team-wide development.
*   **Resources Provisioned**:
    *   Amazon S3 bucket (with versioning and default encryption enabled) for remote state persistence.
    *   Amazon DynamoDB table (with a primary partition key named `LockID`) to manage state lock sessions.

### 2. The Foundation Tier (`/foundation`)
*   **Purpose**: Establishes the core network and security infrastructure.
*   **Resources Provisioned**:
    *   VPC subnets, internet gateways, security groups, and route tables (`vpc`, `security-group`).
    *   IAM identity configurations (`ecs-execution-role`, `ec2_instance_role`).
    *   Edge security networks (`cognito`, `api-gateway`, `api-gateway-authorizer`, `api_gateway_domain`).
    *   Datastore keys and environment references (`secrets-manager`).
    *   Internal directory registers (`cloud-map`) and logical clusters (`ecs-cluster`).

### 3. The Compute Tier (`/compute`)
*   **Purpose**: Manages runtime compute tasks and application services.
*   **Resources Provisioned**:
    *   Launch templates and Auto Scaling Groups (`autoscaling`).
    *   Capacity providers and target metric scales (`ecs_capacity_provider`, `ecs-service-autoscaling`).
    *   Ingress load balancing and routing parameters (`alb`, `api-gateway-integration`).
    *   Application, queue, and database containers (`ecs-service`).
    *   Operations consoles and alert triggers (`cloudwatch-dashboard`, `cloudwatch-alarms`).

---

## Remote State Management and Isolation

Each deployment tier maintains isolated state files to minimize the blast radius of any configuration mistakes. State files are stored in S3 and use DynamoDB to enforce state locking, preventing concurrent deployments from corrupting the files.

### Backend State Configurations

```hcl
# backend.tf - Common architecture pattern used in foundation & compute
terraform {
  backend "s3" {
    bucket         = "cloud-design-terraform-state"
    key            = "production/foundation.tfstate" # Changes per tier
    region         = "us-east-1"
    dynamodb_table = "cloud-design-terraform-locks"
    encrypt        = true
  }
}
```

---

## State Dependency Mapping (`terraform_remote_state`)

The `compute` tier requires metadata (such as subnet IDs, security group IDs, and cluster identifiers) generated during the `foundation` deployment. Rather than hardcoding these dependencies, the `compute` tier reads them dynamically from the `foundation` state file.

```text
  +--------------------------------+
  |    Foundation State File       |
  |    - public_subnet_ids         |
  |    - alb_sg_id                 |
  |    - cluster_id                |
  +--------------------------------+
                  │
                  ▼ (Publishes Outputs)
  +--------------------------------+
  |    Compute Tier                |
  |    - Reads Remote State Block  | <=== [ data.terraform_remote_state.foundation ]
  |    - Maps variables directly   |
  +--------------------------------+
```

### Remote State Extraction Configuration

```hcl
# compute/data.tf
data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = "cloud-design-terraform-state"
    key    = "production/foundation.tfstate"
    region = var.aws_region
  }
}
```

### Reference Mapping Examples

These outputs are referenced directly in our compute configuration files:

```hcl
# compute/main.tf
module "autoscaling" {
  source                = "../modules/autoscaling"
  subnet_ids            = data.terraform_remote_state.foundation.outputs.public_subnet_ids
  security_group_id     = data.terraform_remote_state.foundation.outputs.ec2_host_sg_id
  instance_profile_name = data.terraform_remote_state.foundation.outputs.instance_profile_name
  # ...
}
```

---

## Workspace Container Execution and Makefile Workflow

To ensure a consistent development environment, deployments are run inside a standardized workspace container managed by the project's `Makefile`.

```text
  User CLI Command (make apply) ---> Runs inside cloud-design-development Docker container
                                     ---> Automatically binds local directories
                                     ---> Passes AWS credential keys securely
                                     ---> Executes terraform apply
```

### Core Execution Command Mappings

*   **Initialize Directories**: Matches target folders and fetches referenced module scripts.
    ```bash
    make init
    ```
*   **Verify Execution Safety**: Compiles dynamic dependency schemas and verifies target additions.
    ```bash
    make plan
    ```
*   **Execute Physical Provisioning**: Runs the deployment and applies resource changes automatically.
    ```bash
    make apply
    ```
*   **Purge All Stack Infrastructure**: Destroys resources across the active AWS subscription.
    ```bash
    make destroy
    ```

---

## Input/Output Variable Blueprint

```text
  [ Variables Input ] ──> [ module.secrets ] ──> [ Decrypted Secrets JSON ] ──> [ Target ECS Task Envs ]
```

Tiers utilize standard variable parameters to configure environmental deployments without hardcoding values:

### 1. Variables Definition Configuration (`variables.tf`)
Variables are used to declare input parameters, such as database settings:
```hcl
variable "inventory_db" {
  type = object({
    host     = string
    port     = number
    database = string
    user     = string
    password = string
  })
}
```

### 2. Runtime Assignment Configuration (`terraform.tfvars`)
Values are defined in environment-specific variable files:
```hcl
inventory_db = {
  host     = "inventory-db"
  port     = 5432
  database = "inventory"
  user     = "db_admin"
  password = "password_secure_placeholder"
}
```



> [!NOTE]
> Now that the infrastructure deployment workflow is defined, see [06-Observability-Operations.md](docs/06-observability-operations.md) to review the dashboard configurations, alerts, and runtime logging architecture.