aws_region          = "us-east-1"
localstack_endpoint = "http://localhost:4566"

ssm_parameters = {
  "/retailmind/environment" = {
    value       = "local"
    description = "Runtime environment"
  }

  "/retailmind/database/host" = {
    value       = "postgres"
    description = "PostgreSQL host"
  }

  "/retailmind/database/port" = {
    value       = "5432"
    description = "PostgreSQL port"
  }

  "/retailmind/features/inventory-sync" = {
    value       = "true"
    description = "Inventory synchronization"
  }
}

secrets = {
  "retailmind/database" = {
    description = "RetailMind local database credentials"

    value = {
      username = "retailmind"
      password = "local-password"
    }
  }

  "retailmind/shopify" = {
    description = "Shopify local configuration"

    value = {
      clientId     = "local-client"
      clientSecret = "local-secret"
    }
  }
}

queues = {
  "retailmind-inventory-events" = {
    visibility_timeout_seconds = 30
    message_retention_seconds  = 86400
  }

  "retailmind-orders" = {
    visibility_timeout_seconds = 60
    message_retention_seconds  = 345600
  }

  "retailmind-cache-invalidation" = {
    visibility_timeout_seconds = 30
    message_retention_seconds  = 86400
  }
}

topics = [
  "retailmind-product-events",
  "retailmind-order-events",
  "retailmind-inventory-events"
]

dynamodb_tables = {
  "retailmind-inventory" = {
    hash_key      = "tenantId"
    hash_key_type = "S"

    range_key      = "sku"
    range_key_type = "S"
  }

  "retailmind-orders" = {
    hash_key      = "tenantId"
    hash_key_type = "S"

    range_key      = "orderId"
    range_key_type = "S"
  }
}