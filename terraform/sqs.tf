resource "aws_sqs_queue" "queues" {
  for_each = var.queues

  name = each.key

  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds
}