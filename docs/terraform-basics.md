# Terraform Basics

> A practical introduction to Terraform concepts, workflow, state management, providers, resources, variables, outputs, and Infrastructure as Code principles.

---

## Table of Contents

1. [Introduction](#introduction)
2. [What is Infrastructure as Code?](#what-is-infrastructure-as-code)
3. [What is Terraform?](#what-is-terraform)
4. [Terraform Architecture](#terraform-architecture)
5. [Terraform Configuration Language](#terraform-configuration-language)
6. [Providers](#providers)
7. [Resources](#resources)
8. [Variables](#variables)
9. [Local Values](#local-values)
10. [Outputs](#outputs)
11. [Terraform State](#terraform-state)
12. [Terraform Workflow](#terraform-workflow)
13. [Resource Dependencies](#resource-dependencies)
14. [Meta-Arguments](#meta-arguments)
15. [Data Sources](#data-sources)
16. [Terraform Modules](#terraform-modules)
17. [Infrastructure Drift](#infrastructure-drift)
18. [Terraform Lifecycle](#terraform-lifecycle)
19. [Useful Commands](#useful-commands)
20. [Security Considerations](#security-considerations)
21. [Best Practices](#best-practices)

---

# Introduction

Terraform is an Infrastructure as Code tool that allows infrastructure to be described using declarative configuration files.

Instead of manually creating infrastructure resources, engineers define the desired state in code.

```text
Manual Infrastructure

Developer
    │
    ├── Create Queue
    ├── Create Database
    ├── Create Topic
    ├── Configure Parameters
    └── Configure Permissions


Infrastructure as Code

Developer
    │
    ▼
Terraform Configuration
    │
    ▼
Terraform
    │
    ▼
Infrastructure
```

The infrastructure definition can then be:

- Version controlled
- Reviewed
- Tested
- Reproduced
- Automated
- Audited

---

# What is Infrastructure as Code?

Infrastructure as Code, commonly abbreviated as **IaC**, is the practice of managing infrastructure through machine-readable configuration instead of manual operations.

Traditional infrastructure management frequently involves:

```text
Engineer
   │
   ▼
Cloud Console
   │
   ├── click
   ├── configure
   ├── create
   └── modify
```

This introduces several problems:

- Manual configuration errors
- Configuration drift
- Difficult environment reproduction
- Poor auditability
- Knowledge concentrated in individuals
- Inconsistent environments

IaC changes this model:

```text
Git Repository
      │
      ▼
Infrastructure Code
      │
      ▼
Automation Tool
      │
      ▼
Infrastructure
```

The repository becomes the primary description of the intended infrastructure.

---

# What is Terraform?

Terraform is a declarative Infrastructure as Code tool.

A Terraform configuration describes **what infrastructure should exist** rather than providing a procedural sequence explaining how to create it.

Example:

```hcl
resource "aws_sqs_queue" "orders" {
  name = "workshop-orders"
}
```

This configuration declares:

> An SQS queue named `workshop-orders` should exist.

Terraform determines the operations necessary to reach that state.

---

# Terraform Architecture

Terraform sits between configuration files and infrastructure APIs.

```text
                    ┌─────────────────────┐
                    │ Terraform           │
                    │ Configuration       │
                    │                     │
                    │ *.tf                │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Terraform Core      │
                    │                     │
                    │ Dependency Graph    │
                    │ State Management    │
                    │ Plan Engine         │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Provider            │
                    │                     │
                    │ AWS Provider        │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Infrastructure API  │
                    └─────────────────────┘
```

In this workshop, the infrastructure API is provided by LocalStack.

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
LocalStack
    │
    ▼
AWS-compatible services
```

---

# Terraform Configuration Language

Terraform uses the **HashiCorp Configuration Language (HCL)**.

A basic block follows this structure:

```hcl
block_type "label" "name" {
  argument = value
}
```

Example:

```hcl
resource "aws_sqs_queue" "orders" {
  name = "workshop-orders"
}
```

Where:

```text
resource
   │
   ├── aws_sqs_queue
   │       Resource type
   │
   └── orders
           Local Terraform name
```

The Terraform identifier is:

```text
aws_sqs_queue.orders
```

---

# Providers

Providers allow Terraform to communicate with external platforms and APIs.

Examples include:

- AWS
- Azure
- Google Cloud
- Kubernetes
- GitHub
- Docker

For AWS:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

Provider configuration:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

For LocalStack, AWS service endpoints are redirected:

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

---

# Resources

Resources represent infrastructure objects managed by Terraform.

Examples:

```hcl
resource "aws_sqs_queue" "orders" {
  name = "workshop-orders"
}
```

```hcl
resource "aws_sns_topic" "orders" {
  name = "workshop-order-events"
}
```

```hcl
resource "aws_ssm_parameter" "environment" {
  name  = "/workshop/environment"
  type  = "String"
  value = "local"
}
```

Resources can reference other resources:

```hcl
resource "aws_sns_topic_subscription" "orders" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.orders.arn
}
```

Terraform automatically identifies the dependency.

---

# Variables

Variables make infrastructure configurable.

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

Usage:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Values can be supplied through:

```text
terraform.tfvars
*.auto.tfvars
-var
-var-file
TF_VAR_* environment variables
```

Example:

```hcl
aws_region = "us-east-1"
```

---

# Local Values

Local values simplify repeated expressions.

```hcl
locals {
  project     = "terraform-localstack-workshop"
  environment = "local"

  prefix = "${local.project}-${local.environment}"
}
```

Usage:

```hcl
resource "aws_sqs_queue" "orders" {
  name = "${local.prefix}-orders"
}
```

---

# Outputs

Outputs expose useful information after Terraform applies infrastructure.

```hcl
output "queue_url" {
  value = aws_sqs_queue.orders.url
}
```

Execute:

```bash
terraform output
```

or:

```bash
terraform output queue_url
```

Outputs are useful for:

- CI/CD pipelines
- Application configuration
- Debugging
- Integration tests
- Other Terraform configurations

---

# Terraform State

Terraform maintains a representation of managed infrastructure.

Default state file:

```text
terraform.tfstate
```

Conceptually:

```text
Terraform Configuration
        │
        ▼
Desired State
        │
        │
        ▼
Terraform Engine
        ▲
        │
        │
Current State
        ▲
        │
Terraform State + Provider APIs
```

Terraform uses state to associate configuration resources with infrastructure resources.

For example:

```text
aws_sqs_queue.orders

        ↕

http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/workshop-orders
```

## Never commit state files

State can contain sensitive information.

Add:

```gitignore
*.tfstate
*.tfstate.*
```

Production environments should generally use secure remote state storage.

---

# Terraform Workflow

The standard Terraform lifecycle is:

```text
Write
 │
 ▼
Format
 │
 ▼
Validate
 │
 ▼
Initialize
 │
 ▼
Plan
 │
 ▼
Review
 │
 ▼
Apply
 │
 ▼
Infrastructure
```

## Format

```bash
terraform fmt -recursive
```

## Initialize

```bash
terraform init
```

Terraform downloads the required providers and initializes the working directory.

## Validate

```bash
terraform validate
```

## Plan

```bash
terraform plan
```

Terraform calculates the changes required to reach the desired state.

Common symbols:

```text
+ create
~ update
- destroy
-/+ replace
```

## Apply

```bash
terraform apply
```

Automated local environments can use:

```bash
terraform apply -auto-approve
```

## Destroy

```bash
terraform destroy
```

---

# Resource Dependencies

Terraform automatically builds a dependency graph.

Example:

```hcl
resource "aws_sns_topic" "events" {
  name = "workshop-events"
}

resource "aws_sns_topic_subscription" "queue" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.events.arn
}
```

Terraform understands:

```text
SNS Topic ─────────┐
                   │
                   ▼
              Subscription
                   ▲
                   │
SQS Queue ─────────┘
```

Explicit dependencies can be declared with:

```hcl
depends_on = [
  aws_sqs_queue.events
]
```

Use `depends_on` only when Terraform cannot infer the dependency naturally.

---

# Meta-Arguments

Terraform provides several powerful meta-arguments.

## `for_each`

```hcl
resource "aws_sqs_queue" "queues" {
  for_each = toset([
    "orders",
    "payments",
    "notifications"
  ])

  name = each.value
}
```

Terraform creates:

```text
aws_sqs_queue.queues["orders"]
aws_sqs_queue.queues["payments"]
aws_sqs_queue.queues["notifications"]
```

## `count`

```hcl
resource "aws_sqs_queue" "workers" {
  count = 3

  name = "worker-${count.index}"
}
```

## `depends_on`

Defines explicit dependencies.

## `lifecycle`

Controls resource lifecycle behavior.

Example:

```hcl
lifecycle {
  prevent_destroy = true
}
```

---

# Data Sources

Data sources allow Terraform to read existing infrastructure.

Example:

```hcl
data "aws_region" "current" {}
```

Unlike a resource, a data source does not normally create infrastructure.

```text
resource
   │
   └── manages infrastructure

data
   │
   └── reads infrastructure
```

---

# Terraform Modules

Modules allow infrastructure definitions to be reused.

Example structure:

```text
modules/
└── sqs/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

Usage:

```hcl
module "orders_queue" {
  source = "../../modules/sqs"

  queue_name = "workshop-orders"
}
```

Modules improve:

- Reusability
- Standardization
- Maintainability
- Encapsulation
- Governance

---

# Infrastructure Drift

Infrastructure drift occurs when actual infrastructure differs from the desired Terraform configuration.

Example:

```text
Terraform Configuration
        │
        ▼
Queue exists
        │
        ▼
Someone deletes queue manually
        │
        ▼
Actual infrastructure differs
        │
        ▼
DRIFT
```

Running:

```bash
terraform plan
```

allows Terraform to compare the desired configuration with the current infrastructure.

Terraform may propose:

```text
+ create
```

Running:

```bash
terraform apply
```

restores the desired state.

---

# Terraform Lifecycle

The complete infrastructure lifecycle can be represented as:

```text
                 ┌──────────────┐
                 │ Configuration│
                 └──────┬───────┘
                        │
                        ▼
                 ┌──────────────┐
                 │     Plan     │
                 └──────┬───────┘
                        │
                        ▼
                 ┌──────────────┐
                 │    Apply     │
                 └──────┬───────┘
                        │
                        ▼
                 ┌──────────────┐
                 │Infrastructure│
                 └──────┬───────┘
                        │
                 configuration
                    changes
                        │
                        ▼
                      Plan
                        │
                        ▼
                      Apply
```

---

# Useful Commands

| Command | Purpose |
|---|---|
| `terraform version` | Display Terraform version |
| `terraform init` | Initialize project |
| `terraform fmt` | Format Terraform files |
| `terraform validate` | Validate configuration |
| `terraform plan` | Preview changes |
| `terraform apply` | Apply changes |
| `terraform destroy` | Destroy infrastructure |
| `terraform show` | Display state or plan |
| `terraform output` | Display outputs |
| `terraform state list` | List state resources |
| `terraform providers` | Display providers |
| `terraform console` | Interactive expression console |

---

# Security Considerations

Never store real credentials directly in Terraform source code.

Avoid:

```hcl
access_key = "REAL_ACCESS_KEY"
secret_key = "REAL_SECRET_KEY"
```

For this LocalStack workshop:

```hcl
access_key = "test"
secret_key = "test"
```

These are intentionally fake credentials.

Remember that sensitive resource values can still appear in Terraform state.

---

# Best Practices

Recommended practices:

1. Run `terraform fmt` before committing.
2. Run `terraform validate` before planning.
3. Review every Terraform plan.
4. Pin provider versions.
5. Commit `.terraform.lock.hcl` for reproducibility.
6. Never commit Terraform state.
7. Never commit real credentials.
8. Prefer variables over hard-coded environment values.
9. Use modules for repeated infrastructure patterns.
10. Use meaningful resource names.
11. Allow Terraform to infer dependencies.
12. Avoid manual changes to Terraform-managed infrastructure.
13. Separate reusable infrastructure from environment-specific configuration.
14. Treat infrastructure code with the same discipline as application code.

---

# Next Steps

Continue with:

- [Architecture](architecture.md)
- [LocalStack](localstack.md)

Then proceed to:

```text
labs/01-getting-started
```

The next objective is to connect:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
LocalStack
    │
    ▼
First AWS-compatible Resource
```