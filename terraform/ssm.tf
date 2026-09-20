resource "aws_ssm_parameter" "parameters" {
  for_each = var.ssm_parameters

  name        = each.key
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  overwrite = true
}