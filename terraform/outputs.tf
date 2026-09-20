output "ssm_parameters" {
  value = keys(aws_ssm_parameter.parameters)
}

output "queue_urls" {
  value = {
    for name, queue in aws_sqs_queue.queues :
    name => queue.url
  }
}

output "queue_arns" {
  value = {
    for name, queue in aws_sqs_queue.queues :
    name => queue.arn
  }
}

output "topic_arns" {
  value = {
    for name, topic in aws_sns_topic.topics :
    name => topic.arn
  }
}

output "dynamodb_tables" {
  value = {
    for name, table in aws_dynamodb_table.tables :
    name => table.name
  }
}

output "secret_arns" {
  value = {
    for name, secret in aws_secretsmanager_secret.secrets :
    name => secret.arn
  }

  sensitive = true
}