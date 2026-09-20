variable "aws_region" {
  description = "AWS region used by LocalStack"
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint"
  type        = string
  default     = "http://localhost:4566"
}

variable "ssm_parameters" {
  type = map(object({
    type        = optional(string, "String")
    value       = string
    description = optional(string, "")
  }))
}

variable "secrets" {
  type = map(object({
    description = optional(string, "")
    value       = map(string)
  }))
}

variable "queues" {
  type = map(object({
    visibility_timeout_seconds = optional(number, 30)
    message_retention_seconds  = optional(number, 86400)
  }))
}

variable "topics" {
  type = set(string)
}

variable "dynamodb_tables" {
  type = map(object({
    hash_key       = string
    hash_key_type  = optional(string, "S")
    range_key      = optional(string)
    range_key_type = optional(string, "S")
  }))
}