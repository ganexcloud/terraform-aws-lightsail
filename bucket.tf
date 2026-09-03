###############################################################################
# Object storage bucket
###############################################################################

resource "aws_lightsail_bucket" "this" {
  count = local.bucket_enabled ? 1 : 0

  name         = local.bucket_name
  bundle_id    = var.bucket.bundle_id
  force_delete = var.bucket.force_delete
  tags         = var.tags
}

# The secret is only readable at creation and is kept in state from then on.
resource "aws_lightsail_bucket_access_key" "this" {
  count = local.bucket_enabled && var.create_bucket_access_key ? 1 : 0

  bucket_name = aws_lightsail_bucket.this[0].name
}

# for_each keys stay config-known while resource_name may resolve to the
# instance this module creates, so Terraform orders the grant after it exists.
resource "aws_lightsail_bucket_resource_access" "this" {
  for_each = local.bucket_enabled ? toset(var.bucket_resource_access) : []

  bucket_name   = aws_lightsail_bucket.this[0].name
  resource_name = each.value == "self" ? one(aws_lightsail_instance.this[*].name) : each.value

  lifecycle {
    precondition {
      condition     = each.value != "self" || var.instance != null
      error_message = "bucket_resource_access uses \"self\" but the module does not create an instance."
    }
  }
}
