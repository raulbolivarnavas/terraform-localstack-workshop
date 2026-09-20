# Terraform + LocalStack Workshop

> A hands-on Infrastructure as Code workshop for provisioning, testing, and managing AWS-compatible cloud infrastructure locally using Terraform and LocalStack.

[![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![LocalStack](https://img.shields.io/badge/LocalStack-AWS%20Emulation-5C4EE5?logo=localstack&logoColor=white)](https://www.localstack.cloud/)
[![AWS](https://img.shields.io/badge/AWS-Cloud%20Services-232F3E?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Docker-Containers-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

**Terraform + LocalStack Workshop** is a practical learning environment designed to demonstrate how modern cloud infrastructure can be defined, provisioned, tested, destroyed, and recreated using **Infrastructure as Code (IaC)** principles.

The project combines:

- **Terraform** for declarative infrastructure provisioning.
- **LocalStack** for locally emulating AWS services.
- **Docker Compose** for running the local cloud environment.
- **AWS CLI** for inspecting and validating provisioned resources.
- **Git** for versioning infrastructure definitions and workshop exercises.

Instead of provisioning resources in a real AWS account, the workshop runs the infrastructure locally through LocalStack.

This provides a safe and repeatable environment for learning Terraform and AWS architecture without requiring cloud credentials or incurring AWS infrastructure costs.

---

## Architecture

```text
                         Developer Workstation / VPS
                                  │
                                  │
                         ┌────────▼────────┐
                         │    Terraform    │
                         │ Infrastructure  │
                         │    as Code      │
                         └────────┬────────┘
                                  │
                           AWS Provider
                                  │
                                  ▼
                     http://localhost:4566
                                  │
                    ┌─────────────▼─────────────┐
                    │                           │
                    │        LocalStack         │
                    │                           │
                    │    Local AWS Emulator     │
                    │                           │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────┬───────┼────────┬───────────────┐
          │               │       │        │               │
          ▼               ▼       ▼        ▼               ▼
     Parameter         Secrets    SQS      SNS          DynamoDB
       Store           Manager
       (SSM)
```

Docker provides the runtime environment while Terraform communicates with LocalStack through the AWS Provider.

The same Terraform concepts used in this repository can later be applied to real AWS environments by changing provider configuration, credentials, state management, and environment-specific variables.

---

## Learning Objectives

By completing this workshop, you will learn how to:

- Understand the fundamentals of Infrastructure as Code.
- Install and configure Terraform.
- Run LocalStack using Docker Compose.
- Configure the Terraform AWS Provider for LocalStack.
- Understand Terraform providers, resources, variables, outputs, and state.
- Provision AWS-compatible infrastructure locally.
- Manage SSM Parameter Store parameters.
- Manage AWS Secrets Manager secrets.
- Create SQS queues.
- Create SNS topics.
- Connect SNS topics to SQS queues.
- Implement Dead Letter Queues.
- Provision DynamoDB tables.
- Provision S3 buckets.
- Work with EventBridge.
- Understand Terraform dependency management.
- Detect infrastructure drift.
- Recreate infrastructure safely.
- Build reusable Terraform modules.
- Apply Infrastructure as Code best practices.
- Validate infrastructure using the AWS CLI.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| LocalStack | Local AWS cloud emulation |
| Docker | Container runtime |
| Docker Compose | Local infrastructure orchestration |
| AWS Provider | Terraform integration with AWS-compatible APIs |
| AWS CLI | Resource inspection and validation |
| Git | Source control |
| Bash | Environment automation |

---

## AWS Services Covered

The workshop progressively introduces several AWS services.

| Service | Purpose |
|---|---|
| AWS Systems Manager Parameter Store | Application configuration |
| AWS Secrets Manager | Secret and credential management |
| Amazon SQS | Asynchronous messaging |
| Amazon SNS | Publish/subscribe messaging |
| Amazon DynamoDB | NoSQL persistence |
| Amazon S3 | Object storage |
| Amazon EventBridge | Event-driven integration |
| AWS IAM | Identity and access concepts |
| AWS KMS | Encryption concepts |

Additional services can be incorporated as the workshop evolves.

---

## Repository Structure

```text
terraform-localstack-workshop/
│
├── README.md
├── LICENSE
├── .gitignore
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

Each laboratory is intentionally isolated so concepts can be learned incrementally.

---

# Prerequisites

Before starting the workshop, install the following tools.

## Terraform

Verify Terraform:

```bash
terraform version
```

## Docker

Verify Docker:

```bash
docker --version
```

Verify the Docker daemon:

```bash
docker info
```

## Docker Compose

This workshop uses Docker Compose V2.

```bash
docker compose version
```

## AWS CLI

Verify the AWS CLI:

```bash
aws --version
```

## Git

```bash
git --version
```

---

# Getting Started

## 1. Clone the Repository

```bash
git clone <repository-url>
cd terraform-localstack-workshop
```

---

## 2. Start LocalStack

Start the local AWS-compatible environment:

```bash
docker compose -f docker/docker-compose.yml up -d
```

Verify the container:

```bash
docker ps
```

Follow LocalStack logs:

```bash
docker logs -f localstack
```

LocalStack exposes its primary AWS API gateway through:

```text
http://localhost:4566
```

Verify its health:

```bash
curl http://localhost:4566/_localstack/health
```

---

# Terraform Configuration

Terraform normally communicates with AWS public APIs.

For this workshop, the AWS Provider is configured to communicate with LocalStack instead.

Example:

```hcl
provider "aws" {

  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb       = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
  }
}
```

This redirects AWS API calls from Terraform to LocalStack.

---

# Terraform Workflow

A typical Terraform workflow consists of four primary operations.

## Initialize

Download providers and initialize the working directory:

```bash
terraform init
```

## Format

Normalize Terraform source formatting:

```bash
terraform fmt -recursive
```

## Validate

Validate the Terraform configuration:

```bash
terraform validate
```

## Plan

Preview infrastructure changes:

```bash
terraform plan
```

Terraform displays which resources will be:

```text
+ created
~ modified
- destroyed
```

Always review the plan before applying infrastructure changes.

## Apply

Provision the infrastructure:

```bash
terraform apply
```

For automated local environments:

```bash
terraform apply -auto-approve
```

---

# Example: SSM Parameter Store

Terraform resource:

```hcl
resource "aws_ssm_parameter" "environment" {

  name        = "/workshop/environment"
  description = "Application runtime environment"

  type  = "String"
  value = "local"
}
```

Apply:

```bash
terraform apply
```

Verify using the AWS CLI:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  ssm get-parameter \
  --name "/workshop/environment" \
  --region us-east-1
```

---

# Example: SQS

Create a queue:

```hcl
resource "aws_sqs_queue" "orders" {

  name = "workshop-orders"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
}
```

Verify:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sqs list-queues \
  --region us-east-1
```

---

# Example: SNS

```hcl
resource "aws_sns_topic" "order_events" {

  name = "workshop-order-events"
}
```

Verify:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sns list-topics \
  --region us-east-1
```

---

# Example: DynamoDB

```hcl
resource "aws_dynamodb_table" "orders" {

  name         = "workshop-orders"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "tenantId"
  range_key = "orderId"

  attribute {
    name = "tenantId"
    type = "S"
  }

  attribute {
    name = "orderId"
    type = "S"
  }
}
```

Verify:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  dynamodb list-tables \
  --region us-east-1
```

---

# Infrastructure State

Terraform maintains information about managed infrastructure inside its state.

By default:

```text
terraform.tfstate
```

Conceptually:

```text
Terraform Configuration
          │
          ▼
    Terraform Plan
          │
          ▼
    Terraform Apply
          │
          ▼
   Terraform State
          │
          ▼
      LocalStack
```

Terraform compares the desired configuration with the current infrastructure state to determine which operations are required.

---

## Important: Terraform State May Contain Sensitive Information

Terraform state can contain:

- Passwords
- Secret values
- Resource identifiers
- Configuration parameters
- Infrastructure metadata

Never commit Terraform state files to Git.

Recommended `.gitignore`:

```gitignore
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
crash.log
crash.*.log

# Sensitive variable files
*.auto.tfvars
*.auto.tfvars.json

# Environment
.env
```

For collaborative production environments, use a secure remote Terraform backend instead of local state.

---

# Infrastructure Drift

One of the important concepts demonstrated by this workshop is **infrastructure drift**.

Consider the following sequence:

```text
Terraform Apply
      │
      ▼
LocalStack Resources
      │
      ▼
Resource manually deleted
      │
      ▼
Terraform Plan
      │
      ▼
Drift detected
      │
      ▼
Terraform Apply
      │
      ▼
Resource recreated
```

For example:

```bash
terraform apply
```

Delete a resource manually using the AWS CLI.

Then execute:

```bash
terraform plan
```

Terraform should identify that the desired infrastructure no longer matches the actual infrastructure.

Running:

```bash
terraform apply
```

reconciles the environment.

This is one of the fundamental advantages of declarative Infrastructure as Code.

---

# LocalStack Persistence

LocalStack provides a local implementation of AWS APIs.

Depending on the LocalStack edition, service implementation, and persistence capabilities, some resources may not survive container recreation or restart.

This workshop therefore treats **Terraform configuration as the source of truth**.

Instead of relying exclusively on the runtime environment:

```text
LocalStack
    │
    └── resources
```

the desired model is:

```text
Git Repository
      │
      ▼
Terraform Configuration
      │
      ▼
Terraform
      │
      ▼
LocalStack
      │
      ▼
AWS-compatible resources
```

If the local environment is lost, the infrastructure can be recreated from code.

---

# Destroying the Environment

Terraform-managed resources can be removed with:

```bash
terraform destroy
```

Review the plan and confirm the operation.

For local automated environments:

```bash
terraform destroy -auto-approve
```

Stop LocalStack:

```bash
docker compose -f docker/docker-compose.yml down
```

Be careful when removing Docker volumes.

Commands such as:

```bash
docker compose down -v
```

remove associated persistent volumes and should only be used when intentionally resetting the environment.

---

# Workshop Roadmap

The repository is organized as a progressive learning path:

```text
01  Terraform Fundamentals
        │
02  SSM Parameter Store
        │
03  Secrets Manager
        │
04  SQS
        │
05  SNS
        │
06  DynamoDB
        │
07  S3
        │
08  SNS + SQS Integration
        │
09  Dead Letter Queues
        │
10  EventBridge
        │
11  Terraform Modules
        │
12  Infrastructure Drift
        │
13  Testing Infrastructure
        │
14  Environment Management
        │
15  CI/CD
        ▼
Production-oriented IaC Concepts
```

---

# Infrastructure as Code Principles

This repository promotes several important engineering principles.

### Declarative Infrastructure

Infrastructure should describe the desired state rather than a sequence of manual configuration steps.

### Reproducibility

A developer should be able to clone the repository and recreate the environment consistently.

### Idempotency

Executing Terraform repeatedly should converge toward the same desired infrastructure state.

### Version Control

Infrastructure definitions should evolve through Git just like application source code.

### Automation

Manual infrastructure operations should progressively be replaced with automated workflows.

### Isolation

LocalStack allows developers to experiment without modifying shared cloud environments.

### Review Before Apply

Infrastructure changes should be inspected through:

```bash
terraform plan
```

before they are applied.

---

# Local Development Workflow

The expected development cycle is:

```text
                   Developer
                       │
                       ▼
               Modify *.tf files
                       │
                       ▼
                 terraform fmt
                       │
                       ▼
               terraform validate
                       │
                       ▼
                 terraform plan
                       │
                       ▼
                Review changes
                       │
                       ▼
                 terraform apply
                       │
                       ▼
                    LocalStack
                       │
                       ▼
                Validate with
                   AWS CLI
```

---

# Makefile Automation

As the workshop evolves, common operations can be exposed through a `Makefile`.

Example commands:

```bash
make up
make init
make validate
make plan
make apply
make verify
make destroy
make down
```

This provides a simpler developer experience while preserving Terraform as the infrastructure engine.

Example workflow:

```bash
make up
make apply
make verify
```

---

# From LocalStack to AWS

One of the goals of this workshop is to teach infrastructure patterns that can later be applied to real AWS environments.

Local development:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
LocalStack
```

Cloud environment:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
AWS
```

Moving to real AWS requires additional considerations, including:

- Secure AWS authentication
- IAM policies and roles
- Remote Terraform state
- State locking
- Encryption
- Networking
- Resource policies
- Security boundaries
- Cost management
- Backup strategies
- Monitoring
- CI/CD controls
- Multiple environments
- Production governance

LocalStack should therefore be considered a development and learning environment, not a replacement for validating production infrastructure in AWS.

---

# Best Practices

Throughout the workshop, follow these recommendations:

1. Run `terraform fmt` before committing changes.
2. Run `terraform validate` before planning.
3. Always review `terraform plan`.
4. Never commit Terraform state containing sensitive information.
5. Never commit real AWS credentials.
6. Keep secrets outside source control.
7. Pin provider versions.
8. Commit the Terraform dependency lock file when appropriate.
9. Prefer reusable Terraform modules for repeated patterns.
10. Use meaningful resource names.
11. Keep environment-specific configuration separate from reusable infrastructure.
12. Treat Terraform configuration as the source of truth.
13. Avoid manually modifying Terraform-managed resources.
14. Test infrastructure changes locally before applying them to shared environments.

---

# Security

This repository is intended for local development and educational purposes.

Never store real credentials directly in Terraform files.

Avoid:

```hcl
access_key = "REAL_ACCESS_KEY"
secret_key = "REAL_SECRET_KEY"
```

The credentials:

```hcl
access_key = "test"
secret_key = "test"
```

are intentionally fake credentials used exclusively with LocalStack.

Production AWS environments should use secure authentication mechanisms such as:

- IAM Roles
- AWS IAM Identity Center
- Environment-based credentials
- Workload Identity
- CI/CD identity federation
- OpenID Connect (OIDC)

---

# Troubleshooting

## LocalStack is not reachable

Check:

```bash
docker ps
```

Then:

```bash
curl http://localhost:4566/_localstack/health
```

Inspect logs:

```bash
docker logs localstack
```

---

## Terraform cannot connect to AWS services

Verify that the provider endpoints reference LocalStack:

```text
http://localhost:4566
```

Also verify:

```bash
curl http://localhost:4566/_localstack/health
```

---

## Docker permission denied

If Docker requires root privileges:

```bash
sudo usermod -aG docker $USER
```

Log out and log back in before trying again.

Verify:

```bash
docker ps
```

---

## Terraform configuration validation fails

Run:

```bash
terraform fmt -recursive
terraform validate
```

Then inspect provider compatibility:

```bash
terraform providers
```

---

# Contributing

Contributions are welcome.

A typical contribution workflow is:

```bash
git checkout -b feature/new-lab
```

Make the required changes and validate them:

```bash
terraform fmt -recursive
terraform validate
```

Commit:

```bash
git add .
git commit -m "feat: add new Terraform workshop lab"
```

Push:

```bash
git push origin feature/new-lab
```

Then open a Pull Request describing:

- The purpose of the change.
- Infrastructure resources introduced.
- How the change was tested.
- Any compatibility considerations.

---

# Future Improvements

Potential future additions include:

- Terraform Test
- Terratest
- TFLint
- Checkov
- Trivy
- GitHub Actions
- Remote Terraform state
- Environment isolation
- Terraform modules
- IAM policy examples
- Lambda
- API Gateway
- Step Functions
- EventBridge architectures
- Kubernetes integration
- Spring Boot integration examples
- CI/CD infrastructure pipelines
- Real AWS deployment examples

---

# Who Is This Workshop For?

This repository is suitable for:

- Software Engineers
- Backend Developers
- Java Developers
- Cloud Engineers
- DevOps Engineers
- Platform Engineers
- Solutions Architects
- SRE Engineers
- Students learning Infrastructure as Code

Basic familiarity with Docker, Linux, and AWS concepts is helpful but not required.

---

# Disclaimer

This repository is designed for educational, experimentation, and local development purposes.

LocalStack emulates AWS APIs but does not guarantee identical behavior for every AWS feature or service.

Infrastructure should always be validated appropriately before deployment to production environments.

---

# License

This project is licensed under the MIT License.

See the [LICENSE](LICENSE) file for details.

---

# Author

**Raul Bolivar**

Software Engineer | Java & Reactive Systems | Cloud-Native Architecture | Infrastructure as Code

This repository is part of an ongoing effort to share practical examples of modern software engineering, cloud architecture, Infrastructure as Code, and local cloud development.

---

## Final Goal

The objective of this workshop is not simply to learn Terraform syntax.

The goal is to understand a fundamental modern infrastructure principle:

> **Infrastructure should be reproducible, reviewable, testable, automated, and versioned as code.**

With Terraform and LocalStack, these concepts can be explored safely on a local development environment before applying them to real cloud infrastructure.