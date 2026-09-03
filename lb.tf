###############################################################################
# Load balancer
###############################################################################

resource "aws_lightsail_lb" "this" {
  count = local.lb_enabled ? 1 : 0

  name              = local.lb_name
  instance_port     = var.lb.instance_port
  health_check_path = var.lb.health_check_path
  ip_address_type   = var.lb.ip_address_type
  tags              = var.tags
}

resource "aws_lightsail_lb_attachment" "this" {
  for_each = local.lb_enabled ? local.lb_instances : []

  lb_name       = aws_lightsail_lb.this[0].name
  instance_name = each.value

  # Lightsail only attaches instances that are already running.
  depends_on = [aws_lightsail_instance.this]
}

resource "aws_lightsail_lb_certificate" "this" {
  count = local.lb_enabled && var.lb_certificate != null ? 1 : 0

  name                      = local.lb_certificate_name
  lb_name                   = aws_lightsail_lb.this[0].name
  domain_name               = var.lb_certificate.domain_name
  subject_alternative_names = var.lb_certificate.subject_alternative_names
}

# Attachment only succeeds once the certificate is validated, which needs DNS
# records published from the lb_certificate_domain_validation_records output.
resource "aws_lightsail_lb_certificate_attachment" "this" {
  count = local.lb_enabled && var.lb_certificate != null && var.lb_certificate_attach ? 1 : 0

  lb_name          = aws_lightsail_lb.this[0].name
  certificate_name = aws_lightsail_lb_certificate.this[0].name
}

resource "aws_lightsail_lb_https_redirection_policy" "this" {
  count = local.lb_enabled && var.lb_https_redirection_enabled != null ? 1 : 0

  lb_name = aws_lightsail_lb.this[0].name
  enabled = var.lb_https_redirection_enabled

  depends_on = [aws_lightsail_lb_certificate_attachment.this]
}

resource "aws_lightsail_lb_stickiness_policy" "this" {
  count = local.lb_enabled && var.lb_stickiness != null ? 1 : 0

  lb_name         = aws_lightsail_lb.this[0].name
  enabled         = var.lb_stickiness.enabled
  cookie_duration = var.lb_stickiness.cookie_duration
}
