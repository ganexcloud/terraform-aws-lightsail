###############################################################################
# Certificate and CDN distribution
#
# Lightsail certificates and distributions are global resources that AWS only
# exposes through us-east-1. Instantiate the module against a us-east-1
# provider when using this family.
###############################################################################

resource "aws_lightsail_certificate" "this" {
  count = local.certificate_enabled ? 1 : 0

  name                      = local.certificate_name
  domain_name               = var.certificate.domain_name
  subject_alternative_names = var.certificate.subject_alternative_names
  tags                      = var.tags
}

resource "aws_lightsail_distribution" "this" {
  count = local.distribution_enabled ? 1 : 0

  # origin.name and certificate_name arrive as plain strings, so they carry no
  # implicit edge even when they name a resource this module creates.
  depends_on = [
    aws_lightsail_instance.this,
    aws_lightsail_bucket.this,
    aws_lightsail_lb.this,
    aws_lightsail_certificate.this,
  ]

  name             = local.distribution_name
  bundle_id        = var.distribution.bundle_id
  certificate_name = var.distribution.certificate_name
  ip_address_type  = var.distribution.ip_address_type
  is_enabled       = var.distribution.is_enabled
  tags             = var.tags

  origin {
    name            = var.distribution.origin.name
    region_name     = var.distribution.origin.region_name
    protocol_policy = var.distribution.origin.protocol_policy
  }

  default_cache_behavior {
    behavior = var.distribution.default_cache_behavior.behavior
  }

  dynamic "cache_behavior" {
    for_each = var.distribution.cache_behaviors

    content {
      behavior = cache_behavior.value.behavior
      path     = cache_behavior.value.path
    }
  }

  dynamic "cache_behavior_settings" {
    for_each = var.distribution.cache_behavior_settings == null ? [] : [var.distribution.cache_behavior_settings]

    content {
      allowed_http_methods = cache_behavior_settings.value.allowed_http_methods
      cached_http_methods  = cache_behavior_settings.value.cached_http_methods
      default_ttl          = cache_behavior_settings.value.default_ttl
      maximum_ttl          = cache_behavior_settings.value.maximum_ttl
      minimum_ttl          = cache_behavior_settings.value.minimum_ttl

      dynamic "forwarded_cookies" {
        for_each = cache_behavior_settings.value.forwarded_cookies == null ? [] : [cache_behavior_settings.value.forwarded_cookies]

        content {
          option             = forwarded_cookies.value.option
          cookies_allow_list = forwarded_cookies.value.cookies_allow_list
        }
      }

      dynamic "forwarded_headers" {
        for_each = cache_behavior_settings.value.forwarded_headers == null ? [] : [cache_behavior_settings.value.forwarded_headers]

        content {
          option             = forwarded_headers.value.option
          headers_allow_list = forwarded_headers.value.headers_allow_list
        }
      }

      dynamic "forwarded_query_strings" {
        for_each = cache_behavior_settings.value.forwarded_query_strings == null ? [] : [cache_behavior_settings.value.forwarded_query_strings]

        content {
          option                     = forwarded_query_strings.value.option
          query_strings_allowed_list = forwarded_query_strings.value.query_strings_allowed_list
        }
      }
    }
  }
}
