# Compute and Orchestration Design

This document details the configuration of the Amazon ECS cluster, the host provisioning layer using EC2 Auto Scaling Groups, AWS Capacity Providers, and task-level scaling metrics.

---

## Table of Contents
- [Compute Host Provisioning Configuration](#compute-host-provisioning-configuration)
- [ECS Capacity Providers (Managed Instance Scaling)](#ecs-capacity-providers-managed-instance-scaling)
- [Task Placement and Resource Density Optimization](#task-placement-and-resource-density-optimization)
- [Application Task Auto Scaling](#application-task-auto-scaling)


---

## Compute Host Provisioning Configuration

To host our containerized workloads, we manage a cluster of EC2 instances using `modules/autoscaling` and `modules/ecs-cluster`.

```text
  [ ECS Cluster ]
         │
         ▼ (Managed Scaling Calls)
  [ ECS Capacity Provider ]
         │
         ▼ (Triggers Target Tracking)
  [ Auto Scaling Group ] ---> Launches EC2 instances based on Launch Template (t3.micro, custom AMI)
```

### 1. Launch Template Configuration
The launch template defines how new EC2 nodes are provisioned in the public subnets:
*   **AMI Selection**: The official AWS ECS-Optimized Amazon Linux 2023 AMI. This image includes the Docker daemon, the ECS container agent, and security patches pre-installed.
*   **Instance Type**: `t3.micro` (2 vCPUs, 1.0 GiB RAM).
*   **User Data Initialization**: A shell script configures the ECS Agent to join our cluster at boot time:
    ```bash
    #!/bin/bash
    echo "ECS_CLUSTER=${ecs_cluster_name}" >> /etc/ecs/ecs.config
    ```

### 2. Auto Scaling Group (ASG) Limits
*   **Minimum Size**: `1` instance (to maintain baseline availability at minimal cost).
*   **Maximum Size**: `4` instances (to control compute cost caps during unexpected traffic spikes).

---

## ECS Capacity Providers (Managed Instance Scaling)

Rather than using basic scaling alarms based on raw host CPU utilization, the fleet is integrated with an **ECS Capacity Provider** (`modules/ecs_capacity_provider`).

```text
  No capacity available on Host 1 -> Task requested -> Capacity Provider detects shortage 
  -> Triggers ASG Scale-Out -> New EC2 instance boots and joins cluster -> Task successfully deployed
```

### Managed Scaling Logic
*   **Target Capacity Setting**: Configured to `100%`.
*   **How it Works**: The Capacity Provider monitors task resource reservations instead of host metrics. If a task is scheduled but cannot run due to insufficient CPU or Memory on the existing EC2 hosts, the Capacity Provider signals the ASG to launch a new EC2 instance.
*   **Managed Termination Protection**: Enabled. This prevents the ASG from terminating an EC2 instance that is currently running active container tasks during scale-in events.

---

## Task Placement and Resource Density Optimization

Because `t3.micro` hosts have highly constrained resources (2048 CPU units and 1000 MiB of usable memory), task limits must be carefully planned to prevent resource exhaustion.

### Task Allocation Profile

| Service / Task | CPU Reservation | Memory Hard Limit | Max Density on 1 Instance | Network Mode |
| :--- | :--- | :--- | :--- | :--- |
| **Inventory App** | `256` (0.25 vCPU) | `200 MiB` | 4 | `awsvpc` |
| **Billing App** | `256` (0.25 vCPU) | `200 MiB` | 4 | `awsvpc` |
| **RabbitMQ Broker**| `512` (0.50 vCPU) | `300 MiB` | 2 | `awsvpc` |
| **PostgreSQL DBs** | `256` (0.25 vCPU) | `150 MiB` | 4 | `awsvpc` |

> [!WARNING]
> Exceeding these hard memory allocations will cause the Linux kernel Out-Of-Memory (OOM) killer to terminate the container. Keep application runtimes optimized to fit within these limits.

---

## Application Task Auto Scaling

Task-level autoscaling is managed by `modules/ecs-service-autoscaling` and runs independently of host instance scaling.

```text
  Traffic Spike -> Tasks hit 70% CPU -> ECS Service Autoscaling scales Tasks (e.g., 2 to 4) 
  -> Host memory exhausted -> Capacity Provider scales EC2 Hosts (e.g., 1 to 2)
```

1.  **Orchestrator**: Target tracking metrics are managed via AWS Application Auto Scaling.
2.  **Tracking Metric**: Average Target CPU Utilization is set to `70%`.
3.  **Scale-Out Action**: If the average CPU utilization of the Inventory App tasks exceeds 70% over a 3-minute evaluation window, Application Auto Scaling provisions additional tasks.
4.  **Cooldown Windows**:
    *   **Scale-Out Cooldown**: `60 seconds` (to rapidly address traffic surges).
    *   **Scale-In Cooldown**: `300 seconds` (to prevent scale oscillation or "flapping").

---

> [!NOTE]
> For instructions on how application workloads run on this compute layer and handle service discovery, see [04-Application-Workloads.md](docs/04-application-workloads.md).