resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets

  name        = each.key
  description = each.value.description
}

resource "aws_secretsmanager_secret_version" "values" {
  for_each = var.secrets

  secret_id = aws_secretsmanager_secret.secrets[each.key].id

  secret_string = jsonencode(each.value.value)
}