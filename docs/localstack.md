# LocalStack

> A practical guide to using LocalStack as the local AWS-compatible runtime for the Terraform + LocalStack Workshop.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Why LocalStack?](#why-localstack)
3. [Role in This Workshop](#role-in-this-workshop)
4. [Architecture](#architecture)
5. [Docker Configuration](#docker-configuration)
6. [Starting LocalStack](#starting-localstack)
7. [Health Checks](#health-checks)
8. [AWS CLI Configuration](#aws-cli-configuration)
9. [Terraform Integration](#terraform-integration)
10. [Working with AWS Services](#working-with-aws-services)
11. [Persistence](#persistence)
12. [Resource Recovery](#resource-recovery)
13. [Networking](#networking)
14. [Troubleshooting](#troubleshooting)
15. [Security](#security)
16. [LocalStack vs AWS](#localstack-vs-aws)
17. [Best Practices](#best-practices)

---

# Introduction

LocalStack provides a local environment that implements APIs compatible with many AWS services.

Instead of:

```text
Developer
    │
    ▼
Internet
    │
    ▼
AWS
```

the workshop uses:

```text
Developer
    │
    ▼
localhost:4566
    │
    ▼
LocalStack
```

Terraform and the AWS CLI interact with LocalStack using the same general AWS API model used for real cloud environments.

---

# Why LocalStack?

Learning AWS infrastructure directly against a cloud account introduces additional concerns:

- AWS credentials
- Cloud costs
- IAM permissions
- Shared resources
- Cleanup requirements
- Accidental resource creation
- Network dependencies

LocalStack provides a controlled environment for experimentation.

```text
                  Real AWS             LocalStack

Credentials       Required             Test credentials
Cloud cost        Possible             Local runtime
Internet          Required             Usually not
Isolation         Account-based        Local environment
Reset             More complex         Easy
Experimentation   Controlled           Fast
```

LocalStack is especially useful for:

- Development
- Integration testing
- Infrastructure experiments
- Terraform learning
- CI pipelines
- Event-driven architecture testing

---

# Role in This Workshop

Responsibilities are deliberately separated.

```text
Terraform
    │
    │ Defines infrastructure
    ▼
AWS Provider
    │
    │ Sends AWS API requests
    ▼
LocalStack
    │
    │ Emulates AWS APIs
    ▼
AWS-compatible Resources
```

Terraform is responsible for the desired infrastructure.

LocalStack is responsible for executing the AWS-compatible APIs locally.

Therefore:

> LocalStack is the runtime, not the infrastructure source of truth.

---

# Architecture

```text
┌────────────────────────────────────────────────────┐
│                       Host                         │
│                                                    │
│   Terraform                      AWS CLI           │
│       │                             │              │
│       └──────────────┬──────────────┘              │
│                      │                             │
│                      ▼                             │
│              localhost:4566                        │
│                      │                             │
│                      ▼                             │
│              Docker Port Mapping                   │
│                      │                             │
│                      ▼                             │
│            ┌────────────────────┐                  │
│            │     LocalStack     │                  │
│            │                    │                  │
│            │ SSM                │                  │
│            │ Secrets Manager    │                  │
│            │ SQS                │                  │
│            │ SNS                │                  │
│            │ DynamoDB           │                  │
│            │ S3                 │                  │
│            │ EventBridge        │                  │
│            └────────────────────┘                  │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

# Docker Configuration

A minimal LocalStack configuration:

```yaml
services:

  localstack:
    image: localstack/localstack-pro:2026.7.4
    container_name: localstack
    hostname: localstack
    restart: unless-stopped

    environment:
      LOCALSTACK_AUTH_TOKEN: ${LOCALSTACK_AUTH_TOKEN}
      AWS_DEFAULT_REGION: us-east-1
      AWS_ACCESS_KEY_ID: test
      AWS_SECRET_ACCESS_KEY: test

      SERVICES: >-
        s3,
        dynamodb,
        sqs,
        sns,
        ssm,
        secretsmanager,
        events

    ports:
      - "127.0.0.1:4566:4566"

    volumes:
      - localstack-data:/var/lib/localstack
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  localstack-data:
    name: localstack-data
```

The important port is:

```text
4566
```

LocalStack exposes its AWS edge endpoint through this port.

---

# Starting LocalStack

Start:

```bash
docker compose up -d
```

Check:

```bash
docker ps
```

Expected container:

```text
localstack
```

Follow logs:

```bash
docker logs -f localstack
```

Stop:

```bash
docker compose down
```

Restart:

```bash
docker restart localstack
```

Recreate after changing Docker Compose:

```bash
docker compose up -d --force-recreate localstack
```

This recreates the container without intentionally deleting named volumes.

---

# Health Checks

LocalStack exposes a health endpoint.

```bash
curl http://localhost:4566/_localstack/health
```

For scripts:

```bash
curl -sf http://localhost:4566/_localstack/health
```

A Docker health check can also be configured:

```yaml
healthcheck:
  test:
    [
      "CMD",
      "curl",
      "-f",
      "http://localhost:4566/_localstack/health"
    ]
  interval: 10s
  timeout: 5s
  retries: 10
  start_period: 20s
```

---

# AWS CLI Configuration

AWS CLI can communicate with LocalStack by specifying the endpoint.

General syntax:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  <service> <operation> \
  --region us-east-1
```

Example:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sqs list-queues \
  --region us-east-1
```

Test credentials can be exported:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

These credentials are intentionally non-production credentials.

---

# Terraform Integration

Terraform normally sends AWS API calls to AWS.

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
AWS
```

For LocalStack:

```text
Terraform
    │
    ▼
AWS Provider
    │
    ▼
localhost:4566
    │
    ▼
LocalStack
```

Example provider:

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

Terraform resources continue using AWS resource types:

```hcl
resource "aws_sqs_queue" "orders" {
  name = "workshop-orders"
}
```

---

# Working with AWS Services

## SSM Parameter Store

Create:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  ssm put-parameter \
  --name "/workshop/environment" \
  --value "local" \
  --type String \
  --region us-east-1
```

Read:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  ssm get-parameter \
  --name "/workshop/environment" \
  --region us-east-1
```

---

## Secrets Manager

Create:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  secretsmanager create-secret \
  --name workshop/database \
  --secret-string '{"username":"workshop","password":"local"}' \
  --region us-east-1
```

List:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  secretsmanager list-secrets \
  --region us-east-1
```

Never use real production secrets in workshop configuration.

---

## SQS

Create:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sqs create-queue \
  --queue-name workshop-orders \
  --region us-east-1
```

List:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sqs list-queues \
  --region us-east-1
```

---

## SNS

Create:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sns create-topic \
  --name workshop-order-events \
  --region us-east-1
```

List:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sns list-topics \
  --region us-east-1
```

---

## DynamoDB

List tables:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  dynamodb list-tables \
  --region us-east-1
```

Describe:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  dynamodb describe-table \
  --table-name workshop-orders \
  --region us-east-1
```

---

## S3

Create bucket:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  s3 mb s3://workshop-storage \
  --region us-east-1
```

List:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  s3 ls
```

---

# Persistence

LocalStack runtime persistence and Terraform state are separate concerns.

```text
Terraform
    │
    ├── terraform.tfstate
    │
    ▼
Desired Infrastructure Relationship

LocalStack
    │
    ├── /var/lib/localstack
    │
    ▼
Runtime Service State
```

A Docker named volume can be mounted:

```yaml
volumes:
  - localstack-data:/var/lib/localstack
```

and declared:

```yaml
volumes:
  localstack-data:
    name: localstack-data
```

However, persistence behavior can depend on:

- LocalStack version
- LocalStack edition/license
- AWS service implementation
- LocalStack persistence capabilities

For this reason, this workshop does **not** treat LocalStack runtime persistence as the only recovery mechanism.

Terraform remains the infrastructure source of truth.

---

# Resource Recovery

Consider:

```text
Terraform Configuration
        │
        ▼
terraform apply
        │
        ▼
LocalStack
        │
        ▼
Resources Created
```

If a resource disappears:

```text
Resource Lost
     │
     ▼
terraform plan
     │
     ▼
Difference Detected
     │
     ▼
terraform apply
     │
     ▼
Resource Recreated
```

This allows LocalStack to remain disposable.

---

# Networking

## Host to LocalStack

When Terraform runs directly on the host:

```text
http://localhost:4566
```

is appropriate.

## Container to LocalStack

A different container on the same Docker network should generally use the LocalStack service name:

```text
http://localstack:4566
```

Example:

```text
Application Container
        │
        ▼
localstack:4566
        │
        ▼
LocalStack Container
```

Using `localhost` inside another container would refer to that container itself.

---

# VPS Security

When LocalStack runs on a VPS, avoid exposing port `4566` publicly unless explicitly required.

Prefer:

```yaml
ports:
  - "127.0.0.1:4566:4566"
```

instead of:

```yaml
ports:
  - "4566:4566"
```

The latter can bind LocalStack to external host interfaces.

If Kubernetes workloads need to access LocalStack, design the network path deliberately instead of exposing the AWS emulator to the public Internet.

---

# Troubleshooting

## LocalStack is not running

```bash
docker ps -a --filter name=localstack
```

Logs:

```bash
docker logs localstack
```

---

## LocalStack API unavailable

```bash
curl -v http://localhost:4566/_localstack/health
```

Check port mapping:

```bash
docker port localstack
```

---

## AWS CLI cannot connect

Check:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sqs list-queues \
  --region us-east-1
```

Then:

```bash
curl http://localhost:4566/_localstack/health
```

---

## Terraform tries to reach real AWS

Review the provider configuration.

Verify service endpoints:

```hcl
endpoints {
  sqs = "http://localhost:4566"
}
```

Also verify fake credentials and validation settings.

---

## Container was recreated

Check the volume:

```bash
docker volume ls
```

Inspect:

```bash
docker volume inspect localstack-data
```

Do not execute:

```bash
docker compose down -v
```

unless you intentionally want to remove the associated volumes.

---

## Resource missing after restart

Check directly with AWS CLI.

For SSM:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  ssm get-parameters-by-path \
  --path "/" \
  --recursive \
  --region us-east-1
```

Then:

```bash
terraform plan
```

If Terraform detects drift:

```bash
terraform apply
```

---

# Security

LocalStack reduces cloud risk but does not eliminate security responsibilities.

Do not:

- Store production credentials in the repository.
- Store production secrets in `.tf` files.
- Expose LocalStack publicly without a specific requirement.
- Commit Terraform state containing sensitive values.
- Assume local test security controls are equivalent to AWS production controls.

Use fake credentials:

```text
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
```

only for LocalStack.

---

# LocalStack vs AWS

LocalStack provides AWS-compatible APIs for local development, but it is not AWS.

```text
              LocalStack                 AWS

Runtime       Local container            Cloud
Cost          Local resources            Usage based
Network       Local                       AWS networking
IAM           Emulated behavior          Production IAM
Availability  Developer environment       Managed services
Scale         Local                       Cloud scale
Persistence   Local capabilities          Managed persistence
```

Some AWS behavior may differ.

Therefore:

> A successful LocalStack test increases confidence but does not prove that infrastructure will behave identically in AWS.

Production infrastructure must still be validated appropriately against real AWS environments.

---

# Best Practices

1. Pin the LocalStack image version for reproducible labs.
2. Avoid `latest` for stable workshop releases.
3. Keep LocalStack bound to localhost when external access is unnecessary.
4. Treat Terraform as the desired infrastructure definition.
5. Validate resources independently using AWS CLI.
6. Keep fake local credentials separate from real AWS credentials.
7. Never commit production secrets.
8. Do not depend exclusively on LocalStack runtime persistence.
9. Use Docker named volumes when persistence is useful.
10. Avoid `docker compose down -v` unless intentionally resetting the environment.
11. Document differences discovered between LocalStack and AWS.
12. Test important production infrastructure against AWS before deployment.

---

# Recommended Development Cycle

```text
docker compose up -d
        │
        ▼
LocalStack Healthy
        │
        ▼
terraform init
        │
        ▼
terraform validate
        │
        ▼
terraform plan
        │
        ▼
terraform apply
        │
        ▼
AWS CLI Verification
        │
        ▼
Integration Tests
```

---

# Useful Commands

```bash
# Start LocalStack
docker compose up -d

# Check LocalStack
docker ps

# Health
curl http://localhost:4566/_localstack/health

# Logs
docker logs -f localstack

# Port mapping
docker port localstack

# Restart
docker restart localstack

# Stop
docker compose down
```

AWS CLI:

```bash
aws \
  --endpoint-url=http://localhost:4566 \
  sqs list-queues \
  --region us-east-1
```

Terraform:

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
```

---

# Next Steps

With LocalStack running, continue with:

```text
Terraform Configuration
        │
        ▼
AWS Provider
        │
        ▼
LocalStack
        │
        ▼
AWS-compatible Resource
        │
        ▼
AWS CLI Verification
```

From there, each lab introduces a new infrastructure capability while preserving the same Infrastructure as Code workflow.