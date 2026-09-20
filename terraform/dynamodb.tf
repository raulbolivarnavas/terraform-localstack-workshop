resource "aws_dynamodb_table" "tables" {
  for_each = var.dynamodb_tables

  name         = each.key
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = each.value.hash_key
  range_key = each.value.range_key

  attribute {
    name = each.value.hash_key
    type = each.value.hash_key_type
  }

  dynamic "attribute" {
    for_each = each.value.range_key != null ? [1] : []

    content {
      name = each.value.range_key
      type = each.value.range_key_type
    }
  }
}