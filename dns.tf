###############################################################################
# DNS
#
# Lightsail DNS zones are global and AWS only exposes them through us-east-1.
###############################################################################

resource "aws_lightsail_domain" "this" {
  count = local.domain_enabled ? 1 : 0

  domain_name = var.domain_name
}

resource "aws_lightsail_domain_entry" "this" {
  for_each = var.domain_entries

  domain_name = one(aws_lightsail_domain.this[*].domain_name)
  name        = each.value.name
  type        = each.value.type
  target      = each.value.target
  is_alias    = each.value.is_alias

  lifecycle {
    precondition {
      condition     = var.domain_name != null
      error_message = "domain_entries needs domain_name set so the module has a zone to write the records into."
    }
  }
}
