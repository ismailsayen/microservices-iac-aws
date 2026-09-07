# Networking and Security Design

This document details the network topology, IP allocation scheme, security group routing matrices, and Identity and Access Management (IAM) role profiles. 

---

## Table of Contents
- [VPC Network Topology](#vpc-network-topology)
- [Public Placement & NAT-less Routing Strategy](#public-placement--nat-less-routing-strategy)
- [Security Group Traffic Matrix](#security-group-traffic-matrix)
- [IAM Roles and Profiles (Least-Privilege)](#iam-roles-and-profiles-least-privilege)
- [Secrets Management & Secure Storage](#secrets-management--secure-storage)

---

## VPC Network Topology

The networking tier is provisioned using `modules/vpc` and operates with a highly consolidated footprint:

*   **VPC CIDR Block**: `10.0.0.0/16`
*   **Availability Zones**: 2 (using `us-east-1a` and `us-east-1b`)
*   **Subnet Partitioning**:
    *   `Pub-Subnet-A` (`us-east-1a`): `10.0.1.0/24` (Public IPs enabled on launch)
    *   `Pub-Subnet-B` (`us-east-1b`): `10.0.2.0/24` (Public IPs enabled on launch)
*   **Egress Path**: 1 Internet Gateway (`aws_internet_gateway` resource mapped to `0.0.0.0/0` in the main route table).

---

## Public Placement & NAT-less Routing Strategy

```text
  +-------------------------------------------------------------+
  |                   AWS VPC (10.0.0.0/16)                     |
  |                                                             |
  |   +-----------------------+     +-----------------------+   |
  |   | Public Subnet A       |     | Public Subnet B       |   |
  |   | (10.0.1.0/24)         |     | (10.0.2.0/24)         |   |
  |   |                       |     |                       |   |
  |   | [ ALB Node 1 ]        |     | [ ALB Node 2 ]        |   |
  |   | [ EC2 Instance 1 ]    |     | [ EC2 Instance 2 ]    |   |
  |   |   (Public IP Assigned)|     |   (Public IP Assigned)|   |
  |   +-----------+-----------+     +-----------+-----------+   |
  |               |                             |               |
  +---------------|-----------------------------|---------------+
                  +--------------+--------------+
                                 | Outbound Traffic (Pulling ECR Images / Systems Manager)
                                 ▼
                         [ Internet Gateway ]
                                 │
                                 ▼
                          [ Public Web ]
```

### Technical Trade-offs of NAT-less Layout

Deploying ECS Container Instances (`t3.micro` hosts) inside public subnets is a deliberate financial optimization designed to save the monthly overhead associated with AWS NAT Gateways.

1.  **The Challenge**: ECS tasks require access to ECR, Docker Hub, and AWS API Endpoints to download container images and coordinate with the ECS Control Plane. In a private subnet topology, this requires NAT Gateways or dedicated AWS VPC Endpoints (Interface and Gateway types), both of which incur hourly runtime fees.
2.  **The Solution**: Container hosts are placed directly in public subnets with public IPv4 addresses. Outbound traffic traverses the Internet Gateway directly at no extra runtime cost.
3.  **The Security Guardrails**: Because the hosts reside in a public subnet, inbound security group rules are configured to reject any direct internet access to the EC2 instances. Only the Application Load Balancer (ALB) and API Gateway pathways have authorization to establish connections into the tasks.

---

## Security Group Traffic Matrix

The firewall layout is split into specialized modules designed to isolate application tiers (`modules/security-group`):

```text
  [ Client ] ---> [ API Gateway ] ---> [ Load Balancer (ALB) ] ---> [ Application Tasks ] ---> [ Database Tasks ]
```
---

## IAM Roles and Profiles (Least-Privilege)

To enforce logical boundaries between resources, security controls are segmented using specific IAM roles:

### 1. EC2 Instance Profile Role (`modules/ec2-instance-role`)
Assigned to the underlying EC2 host instances within the Auto Scaling group.
*   **Permitted Policies**:
    *   `AmazonEC2ContainerServiceforEC2Role`: Enables the ECS Agent running on the host to register the instance into the logical ECS Cluster.
    *   `AmazonSSMManagedInstanceCore`: Provides AWS Systems Manager access, enabling operators to start secure, passwordless terminal sessions (`make ssm`) directly on the instances without maintaining public SSH keys.

### 2. ECS Task Execution Role (`modules/ecs-execution-role`)
Assigned to individual container Task Definitions. This role is used by the ECS Agent container to boot the application.
*   **Permitted Policies**:
    *   `AmazonEC2ContainerRegistryReadOnly`: Allows the agent to authenticate and pull application images securely from Private ECR repositories.
    *   `CloudWatchLogsFullAccess`: Permits the driver to write container runtime standard output and standard error logs to specific CloudWatch Log groups.
    *   `SecretsManagerReadWrite` (Restricted to project scope): Grants runtime access to decrypt secure database credentials stored in Secrets Manager.

---

## Secrets Management & Secure Storage

Database connection passwords, RabbitMQ credentials, and authentication keys are kept entirely out of Terraform code repositories.

```text
  +--------------------------+          1. Pull Task Execution Policy
  |   ECS Task definition    | <=======================================+
  |                          |                                         |
  |  +--------------------+  |          2. Decrypt Database Password   |
  |  | Application Task   |  | ====================> [ Secrets Manager ]
  |  +--------------------+  |                       (modules/secrets-manager)
  +--------------------------+
```

1.  **Storage**: Credentials are created in **AWS Secrets Manager** (`modules/secrets-manager`) with KMS-managed customer keys.
2.  **Injected at Runtime**: During task registration, target container environment keys reference the Secrets Manager ARN:
    ```hcl
    # Snippet from ECS Service configuration mapping
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = var.secrets_manager_arn
      }
    ]
    ```
3.  **Encrypted in Transit**: Secrets are injected directly into the container's environment space during the initial task boot cycle. They are never written to disk or logged to output consoles.

---

> [!NOTE]
> Now that the networking and security constraints are defined, see [03-Compute-Orchestration.md](docs/03-compute-orchestration.md) to review how tasks are run, scaled, and managed on our virtual EC2 cluster.