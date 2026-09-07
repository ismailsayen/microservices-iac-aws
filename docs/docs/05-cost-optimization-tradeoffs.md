# Cost Management and Architectural Trade-offs

This document details the financial architecture of the Cloud Design Project, outlining standing vs. runtime resources, monthly run-rate calculations, and the structural compromises made to balance security and high availability with a strict operational budget.

---

## Table of Contents

- [Financial Optimization Strategy](#financial-optimization-strategy)
- [Comprehensive Monthly Cost Estimation (6-Node Fleet)](#comprehensive-monthly-cost-estimation-6-node-fleet)
- [Standing (Zero-Cost) vs. Runtime (Active Billing) Resources](#standing-zero-cost-vs-runtime-active-billing-resources)
- [Critical Architectural Trade-offs](#critical-architectural-trade-offs)
- [1. No NAT Gateways (Direct Outbound Routing)](#1-no-nat-gateways-direct-outbound-routing)
- [2. Self-Hosted Containerized Databases vs. Managed Amazon RDS](#2-self-hosted-containerized-databases-vs-managed-amazon-rds)
- [3. ECS on EC2 vs. AWS Fargate Serverless Compute](#3-ecs-on-ec2-vs-aws-fargate-serverless-compute)

---

## Financial Optimization Strategy

Typical enterprise-grade AWS microservice environments utilize managed databases (RDS), serverless compute (Fargate), private network subnets, and redundant egress proxies (NAT Gateways). While highly available, this baseline architecture costs upwards of **$150/month** in idle runtime charges alone.

To reduce this overhead for sandbox and developer testing environments, this deployment uses a **dense-packing EC2 model** [2026]. By managing our own routing, containers, and database tasks directly on a cluster of `t3.micro` nodes, the minimum cost profile is significantly reduced while maintaining a multi-service operational workflow.

---

## Comprehensive Monthly Cost Estimation (6-Node Fleet)

The following calculation represents the active run-rate of the **Compute** phase. The calculations are based on the default configurations of the cluster, running **6 active `t3.micro` nodes** [2026] in `us-east-1` (N. Virginia):

| Billing Domain | AWS Component | Configured Details | Unit Rate (USD) | Total Monthly Cost (USD) |
| :--- | :--- | :--- | :--- | :--- |
| **Compute** | EC2 Instances | 6 active `t3.micro` instances | \$0.0104 / hour | \$45.54 |
| **Storage** | EBS Volume GP3 | 6 hosts × 30 GB per host = 180 GB | \$0.08 / GB-month | \$14.40 |
| **Networking** | Application Load Balancer | 1 Active ALB + LCU baseline metrics | \$0.0225 / ALB-hour + LCU | \$22.27 |
| **Secrets** | AWS Secrets Manager | 1 Secret containing environmental variables | \$0.40 / secret-month | \$0.40 |
| **DNS** | Amazon Route 53 | 1 Private/Public Hosted Zone registration | \$0.50 / zone-month | \$0.50 |
| **Routing** | Amazon API Gateway | HTTP API Gateway Integration Layer | Under 1M requests/month | \$1.00 |
| **Monitoring** | Amazon CloudWatch | Logs and telemetry metrics | Under free tier thresholds | \$1.00 |
| **Total** | | | **Estimated Monthly Run-rate** | **\$85.11** |

---

## Standing (Zero-Cost) vs. Runtime (Active Billing) Resources

To manage costs efficiently, we separate resources into **standing configurations** (which cost nothing when idle and should be kept) and **runtime resources** (which actively incur hourly billing and should be destroyed when not in use).

### Standing Resources (Safe to Keep Active)

The following resources do not incur ongoing hourly charges and can remain active in your account:

| Resource | Keep? | Why |
| :--- | :---: | :--- |
| **IAM Roles** | ✅ | Free of charge. |
| **IAM Policies** | ✅ | Free of charge. |
| **Security Groups** | ✅ | Free of charge. |
| **Launch Templates** | ✅ | Free of charge. |
| **Auto Scaling Groups** | ✅ | Free of charge (only running EC2 instances incur costs). |
| **ECS Cluster** | ✅ | Free of charge (only tasks and compute nodes incur costs). |
| **Cognito User Pool** | ✅ | Free tier up to 50,000 Monthly Active Users (MAUs). |
| **Cognito App Client** | ✅ | Free of charge. |
| **API Gateway Configuration** | ✅ | Charges are based entirely on incoming request volume. |
| **ACM Certificates** | ✅ | Public certificates issued and validated by ACM are free. |
| **Route Tables** | ✅ | Free of charge. |
| **Internet Gateway** | ✅ | Free of charge. |
| **VPC** | ✅ | Free of charge. |
| **Subnets** | ✅ | Free of charge. |
| **CloudWatch Log Groups** | ✅ | Free tier covers 5 GB; beyond that, charged at \$0.50/GB. |

### Runtime Resources (Destroy When Not In Use)

The following resources generate ongoing hourly billing and should be torn down when the development environment is idle:

| Resource | Keep? | Why |
| :--- | :---: | :--- |
| **EC2 Instances** | ❌ | Incurs continuous hourly compute charges. |
| **ECS Tasks** | ❌ | Consumes CPU and memory allocations on host nodes. |
| **Application Load Balancer** | ❌ | Charged continuously per active ALB hour + LCU metrics. |
| **EBS Volumes** | ❌ | Charged continuously by provisioned size (\$0.08/GB-month). |
| **Elastic IPs** | ❌ | AWS charges an idle fee for unused Elastic IPs. |
| **NAT Gateways** | ❌ | Omitted entirely from this project to save \$32/month per AZ. |

---

## Critical Architectural Trade-offs

### 1. No NAT Gateways (Direct Outbound Routing)

- **The Cost Saving**: Managed NAT Gateways cost roughly \$32/month per Availability Zone in idle fees. Omitting them saves **\$64/month** across our two Availability Zones.
- **The Design Trade-off**: EC2 host instances must reside in public subnets with public IP addresses to pull container images and communicate with AWS API endpoints.
- **The Risk**: Increased attack surface area for the compute hosts.
- **The Mitigation**: Strict Security Group rules are applied. Direct ingress from the public internet is completely blocked. Inbound traffic is accepted only when routed through the Application Load Balancer (ALB).

### 2. Self-Hosted Containerized Databases vs. Managed Amazon RDS

- **The Cost Saving**: Avoids the minimum hourly costs of running two independent RDS PostgreSQL databases, saving **\$30 - \$50/month**.
- **The Design Trade-off**: PostgreSQL databases are hosted inside the ECS cluster alongside application containers, storing data using local host directory bind mounts (`modules/ecs-service`).
- **The Risk**: We lose RDS managed services, including automated backups, multi-AZ storage replication, automated minor version upgrades, and automated failover.
- **The Mitigation**: Best suited for non-production development environments. If an EC2 host fails, the Auto Scaling group replaces it, but databases are pinned to their matching hosts to protect their local bind-mounted directories.

### 3. ECS on EC2 vs. AWS Fargate Serverless Compute

- **The Cost Saving**: AWS Fargate charges for CPU and memory usage per task. Running six tasks simultaneously on Fargate can quickly become expensive. Under the EC2 launch type, we pay a flat rate for our `t3.micro` instances and can pack multiple containers onto each host.
- **The Design Trade-off**: We must manage the underlying host operating systems, scale EC2 instances using Capacity Providers, and configure ECS agent settings.
- **The Risk**: Increased operational overhead to monitor host CPU and memory pools.
- **The Mitigation**: Automated using our `ecs_capacity_provider` module, which scales the underlying EC2 instances based on task resource demands.

---

> [!NOTE]
> For instructions on how to set up, build, and deploy the workspace environment, refer back to the root [README.md](../README.md)
