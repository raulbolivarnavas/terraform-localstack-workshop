# Workshop Architecture

> Technical architecture of the Terraform + LocalStack Workshop and the responsibilities of each component.

---

## Table of Contents

1. [Architecture Goals](#architecture-goals)
2. [High-Level Architecture](#high-level-architecture)
3. [Component Responsibilities](#component-responsibilities)
4. [Provisioning Flow](#provisioning-flow)
5. [Runtime Architecture](#runtime-architecture)
6. [Network Architecture](#network-architecture)
7. [State Architecture](#state-architecture)
8. [Configuration Model](#configuration-model)
9. [Repository Architecture](#repository-architecture)
10. [AWS Service Architecture](#aws-service-architecture)
11. [Messaging Architecture](#messaging-architecture)
12. [Failure and Recovery](#failure-and-recovery)
13. [From LocalStack to AWS](#from-localstack-to-aws)
14. [Architectural Principles](#architectural-principles)

---

# Architecture Goals

The workshop architecture is designed around the following goals:

- Reproducibility
- Isolation
- Automation
- Low-cost experimentation
- Infrastructure versioning
- Safe AWS learning
- Infrastructure drift detection
- Local development
- Progressive learning
- Migration toward real AWS concepts

The architecture intentionally separates infrastructure runtime from infrastructure definition.

```text
Runtime
   │
   └── Docker + LocalStack

Definition
   │
   └── Terraform
```

This separation is fundamental.

LocalStack is not the source of truth.

Terraform configuration is.

---

# High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                       Developer Environment                     │
│                                                                 │
│   ┌───────────────┐                                             │
│   │      Git      │                                             │
│   │  Repository   │                                             │
│   └───────┬───────┘                                             │
│           │                                                     │
│           ▼                                                     │
│   ┌───────────────┐                                             │
│   │   Terraform   │                                             │
│   │               │                                             │
│   │      HCL      │                                             │
│   └───────┬───────┘                                             │
│           │                                                     │
│           ▼                                                     │
│   ┌───────────────┐                                             │
│   │ AWS Provider  │                                             │
│   └───────┬───────┘                                             │
│           │                                                     │
│           │ HTTP :4566                                          │
│           ▼                                                     │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                     Docker                              │   │
│   │                                                         │   │
│   │    ┌──────────────────────────────────────────────┐     │   │
│   │    │                LocalStack                    │     │   │
│   │    │                                              │     │   │
│   │    │ SSM │ Secrets │ SQS │ SNS │ DynamoDB │ S3    │     │   │
│   │    │                                              │     │   │
│   │    └──────────────────────────────────────────────┘     │   │
│   │                                                         │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# Component Responsibilities

## Git

Git stores the infrastructure definition and workshop documentation.

Responsibilities:

```text
Git
├── Terraform configuration
├── Documentation
├── Docker configuration
├── Examples
├── Modules
└── Automation scripts
```

Git should not contain:

```text
Terraform state
Real credentials
Production secrets
Local runtime data
```

---

## Terraform

Terraform manages the desired infrastructure state.

Responsibilities:

- Resource definition
- Dependency resolution
- Infrastructure planning
- Infrastructure provisioning
- Drift detection
- Resource updates
- Resource destruction

Terraform answers:

> What infrastructure should exist?

---

## AWS Provider

The Terraform AWS Provider translates Terraform resources into AWS API operations.

Normally:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
AWS APIs
```

In this workshop:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
LocalStack APIs
```

The Terraform resource definitions remain AWS-oriented.

---

## LocalStack

LocalStack provides local implementations of AWS APIs.

Responsibilities:

- Accept AWS API requests.
- Emulate supported AWS services.
- Provide local cloud resources.
- Enable integration testing.
- Reduce dependency on real cloud environments.

LocalStack answers:

> Where can we execute AWS-compatible infrastructure locally?

---

## Docker

Docker provides runtime isolation for LocalStack.

```text
Host
 │
 ▼
Docker Engine
 │
 ▼
LocalStack Container
```

Docker Compose provides lifecycle management:

```bash
docker compose up -d
docker compose down
```

---

## AWS CLI

AWS CLI provides an independent mechanism for validating resources.

Example:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sqs list-queues
```

This is useful because Terraform provisions the resource while AWS CLI independently verifies its availability.

---

# Provisioning Flow

When:

```bash
terraform apply
```

is executed, the following sequence occurs:

```text
Developer
    │
    ▼
Terraform CLI
    │
    ▼
Load *.tf
    │
    ▼
Load State
    │
    ▼
Build Dependency Graph
    │
    ▼
AWS Provider
    │
    ▼
LocalStack :4566
    │
    ▼
AWS-compatible API
    │
    ▼
Create / Update / Delete Resources
    │
    ▼
Provider Response
    │
    ▼
Terraform State Updated
```

---

# Runtime Architecture

The local runtime is intentionally simple:

```text
Host / WSL / VPS
       │
       ├── Terraform
       │
       ├── AWS CLI
       │
       └── Docker
             │
             ▼
         LocalStack
```

Terraform does not need to run inside Docker.

This keeps:

- Terraform state accessible.
- CLI usage simple.
- Debugging straightforward.
- Docker focused on infrastructure runtime.

---

# Network Architecture

LocalStack exposes the AWS edge endpoint:

```text
localhost:4566
```

Communication:

```text
Terraform
    │
    │ HTTP
    ▼
localhost:4566
    │
    ▼
Docker Port Mapping
    │
    ▼
LocalStack:4566
```

Example Docker Compose configuration:

```yaml
ports:
  - "127.0.0.1:4566:4566"
```

Binding to:

```text
127.0.0.1
```

prevents the LocalStack API from being unnecessarily exposed publicly.

This is especially important when running the workshop on a VPS.

---

# State Architecture

There are two different types of state.

## Terraform State

```text
terraform.tfstate
```

Terraform state describes the relationship between Terraform resources and infrastructure resources.

Example:

```text
aws_sqs_queue.orders
        │
        ▼
workshop-orders
```

## LocalStack Runtime State

LocalStack maintains the actual emulated AWS resources.

```text
LocalStack
├── queues
├── topics
├── parameters
├── secrets
├── tables
└── buckets
```

These two states serve different purposes.

```text
Terraform State
      │
      │ reconciliation
      ▼
LocalStack State
```

Terraform configuration remains the desired-state definition.

---

# Configuration Model

Environment-specific values should be separated from reusable infrastructure.

```text
Terraform Resources
        │
        ├── reusable logic
        │
        ▼
Variables
        │
        ▼
terraform.tfvars
        │
        ▼
Environment Configuration
```

Example:

```hcl
variable "environment" {
  type = string
}
```

```hcl
environment = "local"
```

Resources:

```hcl
resource "aws_sqs_queue" "orders" {
  name = "${var.environment}-orders"
}
```

---

# Repository Architecture

```text
terraform-localstack-workshop/
│
├── docker/
│   └── docker-compose.yml
│
├── docs/
│   ├── architecture.md
│   ├── terraform-basics.md
│   └── localstack.md
│
├── terraform/
│   ├── ...
```

The repository is divided by responsibility:

```text
docker     → Runtime
docs       → Knowledge
labs       → Learning
modules    → Reusability
scripts    → Automation
```

---

# AWS Service Architecture

The workshop evolves toward the following architecture:

```text
                       Applications
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
         SSM            Secrets             S3
    Configuration      Credentials         Objects
                            │
                            │
                            ▼
                      Event Producers
                            │
                            ▼
                           SNS
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
             SQS           SQS           SQS
              │
              ▼
           Consumer
              │
              ▼
           DynamoDB
```

This allows the workshop to introduce synchronous configuration, asynchronous messaging, persistence, and event-driven architecture.

---

# Messaging Architecture

A later lab introduces SNS + SQS.

```text
                    ┌───────────────┐
                    │   Producer    │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │      SNS      │
                    │     Topic     │
                    └───────┬───────┘
                            │
               ┌────────────┴────────────┐
               │                         │
               ▼                         ▼
        ┌─────────────┐           ┌─────────────┐
        │     SQS     │           │     SQS     │
        │  Consumer A │           │  Consumer B │
        └──────┬──────┘           └─────────────┘
               │
               │ failed messages
               ▼
        ┌─────────────┐
        │     DLQ     │
        └─────────────┘
```

Terraform manages all relationships.

---

# Failure and Recovery

The workshop treats Terraform configuration as recoverable infrastructure definition.

Consider:

```text
LocalStack Restart
       │
       ▼
Some Runtime State Lost
       │
       ▼
terraform plan
       │
       ▼
Drift Detected
       │
       ▼
terraform apply
       │
       ▼
Infrastructure Restored
```

This illustrates an important principle:

> Runtime infrastructure should be reproducible from version-controlled definitions.

---

# From LocalStack to AWS

The local architecture:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
LocalStack
```

Production architecture:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
AWS
```

The infrastructure definitions may be conceptually similar, but real AWS environments introduce additional concerns:

```text
AWS
├── Authentication
├── IAM
├── Networking
├── Encryption
├── Cost
├── Availability
├── Backup
├── Monitoring
├── Governance
└── Compliance
```

LocalStack testing does not eliminate the need for validation against real AWS.

---

# Architectural Principles

## Infrastructure is Code

Infrastructure definitions belong in source control.

## Declarative Desired State

Terraform describes what should exist.

## Runtime is Replaceable

Local infrastructure should be disposable and reproducible.

## Configuration is Externalized

Environment-specific values should not be embedded throughout infrastructure code.

## Dependencies are Explicit

Infrastructure relationships should be represented through Terraform references.

## Security by Default

Local services should not be publicly exposed unnecessarily.

For example:

```yaml
127.0.0.1:4566:4566
```

is preferred over:

```yaml
4566:4566
```

on an Internet-accessible VPS.

## Automation over Manual Operations

Prefer:

```bash
terraform apply
```

over manually creating resources.

## Verification

Provisioning should be followed by independent validation.

```text
Terraform Apply
      │
      ▼
AWS CLI Verification
      │
      ▼
Integration Testing
```

---

# Final Architecture

The complete learning model is:

```text
                        Git
                         │
                         ▼
                 Terraform Code
                         │
                         ▼
                 Terraform Engine
                         │
                         ▼
                  AWS Provider
                         │
                         ▼
                    LocalStack
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
    Configuration     Messaging      Persistence
          │              │              │
      SSM/Secrets      SNS/SQS       DynamoDB/S3
                         │
                         ▼
                       DLQ
```

The architecture allows cloud infrastructure concepts to be learned locally while maintaining the same fundamental Infrastructure as Code workflow used in real environments.

---