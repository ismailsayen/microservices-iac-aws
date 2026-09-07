
# Cloud-Architect-For-Microservice: Containerized Microservices on AWS

The Cloud-Architect-For-Microservice Project is an architectural blueprint and deployment pipeline for a decoupled microservices system on Amazon Web Services (AWS). It models a retail inventory and transactional billing engine, demonstrating how to deploy secure, auto-scaling applications under strict cost constraints.

To achieve a minimal cost profile, the infrastructure runs entirely on Amazon ECS (EC2 Launch Type) using cost-efficient `t3.micro` instances. Rather than utilizing expensive managed NAT Gateways, the container hosts reside in public subnets with direct Internet Gateway routing, while security is strictly enforced at the host and container boundaries. This setup demonstrates how to achieve enterprise-level security, data isolation, and dynamic scaling on a highly optimized budget.

---

## Documentation Index

The design specifications, deployment procedures, and operational guides are split into modular articles:

* **[01-Architecture-Overview.md](docs/01-architecture-overview.md)**  
    Visual conceptual designs, end-to-end request lifecycles, and component-to-component integrations.
* **[02-Networking-Security.md](docs/02-networking-security.md)**  
    Subnet configurations, security group rules, public subnet hosting trade-offs, and custom IAM role profiles.
* **[03-Compute-Orchestration.md](docs/03-compute-orchestration.md)**  
    ECS on EC2 setups, Launch Templates, Auto Scaling Group Capacity Providers, and target tracking configurations.
* **[04-Infrastructure-as-Code.md](docs/05-infrastructure-as-code.md)**  
    Terraform directory patterns, state management, inputs/outputs, and multi-environment orchestration.
* **[05-Cost-Optimization-Tradeoffs.md](docs/07-cost-optimization-tradeoffs.md)**  
    Financial breakdown of Fargate vs. EC2, the decision to omit NAT Gateways, and associated operational risks.

---

## Quick Start Deployment Workflow

Operations are run inside a standardized development workspace container or directly from your local host machine. The `Makefile` automatically handles directory tracking (`-chdir`) and volume mounts via the `DIR` variable.

This project is divided into a multi-tier structure that must be deployed in order:
1. **`bootstrap`**: Sets up remote state storage (S3 backend & DynamoDB locks).
2. **`foundation`**: Deploys base networking, VPCs, and core security configurations.
3. **`compute`**: Deploys instances, clusters, and application resources (using configurations stored in `modules`).

---

### 1. Initialize and Run the Workspace Container

To install Docker (if required), build the workspace image, and launch the interactive container with your local AWS configuration and workspace mounted:

```bash
make all
```

> [!NOTE]
> Running `make all` executes the `docker`, `build`, and `run` targets in sequence. This mounts your local `~/.aws` directory inside the container workspace to securely pass credentials.

---

### 2. Deployment Steps (By Tier)

Pass the target folder to the `make` commands using the `DIR` variable. 

#### Step A: Deploy Bootstrap
Initialize and deploy the remote backend first:
```bash
terraform init DIR=bootstrap
terraform plan DIR=bootstrap
terraform apply DIR=bootstrap
```

#### Step B: Deploy Foundation
Next, deploy the core networking and foundation layer:
```bash
terraform init DIR=foundation
terraform plan DIR=foundation
terraform apply DIR=foundation
```

#### Step C: Deploy Compute
Finally, deploy the compute infrastructure and applications:
```bash
terraform init DIR=compute
terraform plan DIR=compute
terraform apply DIR=compute
```

---

### 3. Tear Down Resources

To avoid ongoing AWS costs, destroy your infrastructure tiers. They must be torn down in the **reverse order** of deployment:

```bash
# 1. Destroy compute first
terraform destroy DIR=compute

# 2. Destroy foundation second
terraform destroy DIR=foundation

# 3. Destroy bootstrap last
terraform destroy DIR=bootstrap
```

---




## Collaborators

* [Ismail Sayen](https://github.com/ismailsayen) - Cloud & Devops Engineer
* [Hassan El ouazizi](https://github.com/helouazizi) - Cloud & Devops Engineer