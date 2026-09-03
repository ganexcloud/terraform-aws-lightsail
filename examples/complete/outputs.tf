output "instance_name" {
  description = "Name of the Lightsail instance."
  value       = module.lightsail.instance_name
}

output "static_ip_address" {
  description = "Static IP attached to the instance."
  value       = module.lightsail.static_ip_address
}

output "lb_dns_name" {
  description = "DNS name of the load balancer."
  value       = module.lightsail.lb_dns_name
}

output "bucket_url" {
  description = "URL of the object storage bucket."
  value       = module.lightsail.bucket_url
}

output "distribution_domain_name" {
  description = "Domain name of the CDN distribution."
  value       = module.lightsail.distribution_domain_name
}

output "container_service_url" {
  description = "Public URL of the container service."
  value       = module.lightsail.container_service_url
}

output "alarm_names" {
  description = "Alarms created for the instance."
  value       = module.lightsail.alarm_names
}
