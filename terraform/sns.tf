resource "aws_sns_topic" "topics" {
  for_each = var.topics

  name = each.value
}