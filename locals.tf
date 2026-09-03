locals {
  # Each resource family is toggled by the presence of its own input, so an
  # enabled family always carries the configuration it needs.
  instance_enabled          = var.instance != null
  lb_enabled                = var.lb != null
  database_enabled          = var.database != null
  bucket_enabled            = var.bucket != null
  certificate_enabled       = var.certificate != null
  distribution_enabled      = var.distribution != null
  container_service_enabled = var.container_service != null
  domain_enabled            = var.domain_name != null

  # Lightsail resource names are unique per Region, so every family gets a
  # distinct suffix off the base name. The instance keeps the bare name because
  # it is the resource callers refer to from outside the module.
  instance_name          = local.instance_enabled ? coalesce(var.instance.name, var.name) : null
  key_pair_default_name  = "${var.name}-key"
  static_ip_name         = coalesce(var.static_ip_name, "${var.name}-ip")
  lb_name                = local.lb_enabled ? coalesce(var.lb.name, "${var.name}-lb") : null
  lb_certificate_name    = var.lb_certificate != null ? coalesce(var.lb_certificate.name, "${var.name}-lb-cert") : null
  database_name          = local.database_enabled ? coalesce(var.database.relational_database_name, "${var.name}-db") : null
  bucket_name            = local.bucket_enabled ? coalesce(var.bucket.name, "${var.name}-bucket") : null
  certificate_name       = local.certificate_enabled ? coalesce(var.certificate.name, "${var.name}-cert") : null
  distribution_name      = local.distribution_enabled ? coalesce(var.distribution.name, "${var.name}-cdn") : null
  container_service_name = local.container_service_enabled ? coalesce(var.container_service.name, "${var.name}-cs") : null

  create_key_pair = var.key_pair != null
  key_pair_name   = local.create_key_pair ? one(aws_lightsail_key_pair.this[*].name) : var.key_pair_name

  # An explicit list wins; otherwise the load balancer fronts the instance this
  # module created, if there is one.
  lb_instances = toset(
    length(var.lb_attached_instances) > 0 ? var.lb_attached_instances : compact([local.instance_name])
  )

  # Read through the instance resource rather than the input so Terraform
  # orders alarm creation after the instance exists. Lightsail rejects an alarm
  # whose monitored resource is not there yet.
  alarm_monitored_resource_name = (
    var.alarm_monitored_resource_name != null
    ? var.alarm_monitored_resource_name
    : one(aws_lightsail_instance.this[*].name)
  )
}
