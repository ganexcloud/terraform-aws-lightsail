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

resource "aws_lightsail_bucket_resource_access" "this" {
  for_each = local.bucket_enabled ? local.bucket_resource_access : []

  bucket_name   = aws_lightsail_bucket.this[0].name
  resource_name = each.value
}
