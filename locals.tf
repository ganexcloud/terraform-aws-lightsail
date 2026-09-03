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

  instance_name = local.instance_enabled ? coalesce(var.instance.name, var.name) : null

  create_key_pair = var.key_pair != null
  key_pair_name   = local.create_key_pair ? one(aws_lightsail_key_pair.this[*].name) : var.key_pair_name

  static_ip_name = coalesce(var.static_ip_name, "${var.name}-ip")

  lb_name             = local.lb_enabled ? coalesce(var.lb.name, var.name) : null
  lb_certificate_name = var.lb_certificate != null ? coalesce(var.lb_certificate.name, var.name) : null

  # An explicit list wins; otherwise the load balancer fronts the instance this
  # module created, if there is one.
  lb_instances = toset(
    length(var.lb_attached_instances) > 0 ? var.lb_attached_instances : compact([local.instance_name])
  )

  database_name = local.database_enabled ? coalesce(var.database.relational_database_name, var.name) : null

  bucket_name = local.bucket_enabled ? coalesce(var.bucket.name, var.name) : null
  # "self" is sugar for the instance created by this module.
  bucket_resource_access = toset(compact([
    for resource_name in var.bucket_resource_access :
    resource_name == "self" ? local.instance_name : resource_name
  ]))

  certificate_name  = local.certificate_enabled ? coalesce(var.certificate.name, var.name) : null
  distribution_name = local.distribution_enabled ? coalesce(var.distribution.name, var.name) : null

  container_service_name = local.container_service_enabled ? coalesce(var.container_service.name, var.name) : null

  alarm_monitored_resource_name = try(
    coalesce(var.alarm_monitored_resource_name, local.instance_name),
    null
  )
}
