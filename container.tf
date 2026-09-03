###############################################################################
# Container service
###############################################################################

resource "aws_lightsail_container_service" "this" {
  count = local.container_service_enabled ? 1 : 0

  name        = local.container_service_name
  power       = var.container_service.power
  scale       = var.container_service.scale
  is_disabled = var.container_service.is_disabled
  tags        = var.tags

  dynamic "public_domain_names" {
    for_each = var.container_service.public_domain_names == null ? [] : [var.container_service.public_domain_names]

    content {
      dynamic "certificate" {
        for_each = public_domain_names.value.certificate

        content {
          certificate_name = certificate.value.certificate_name
          domain_names     = certificate.value.domain_names
        }
      }
    }
  }
}

# Every change here publishes a new immutable deployment version; Lightsail
# keeps the previous ones.
resource "aws_lightsail_container_service_deployment_version" "this" {
  count = local.container_service_enabled && var.container_service_deployment != null ? 1 : 0

  service_name = aws_lightsail_container_service.this[0].name

  dynamic "container" {
    for_each = var.container_service_deployment.containers

    content {
      container_name = container.value.container_name
      image          = container.value.image
      command        = container.value.command
      environment    = container.value.environment
      ports          = container.value.ports
    }
  }

  dynamic "public_endpoint" {
    for_each = var.container_service_deployment.public_endpoint == null ? [] : [var.container_service_deployment.public_endpoint]

    content {
      container_name = public_endpoint.value.container_name
      container_port = public_endpoint.value.container_port

      health_check {
        healthy_threshold   = public_endpoint.value.health_check.healthy_threshold
        unhealthy_threshold = public_endpoint.value.health_check.unhealthy_threshold
        interval_seconds    = public_endpoint.value.health_check.interval_seconds
        timeout_seconds     = public_endpoint.value.health_check.timeout_seconds
        path                = public_endpoint.value.health_check.path
        success_codes       = public_endpoint.value.health_check.success_codes
      }
    }
  }
}
