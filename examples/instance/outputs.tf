output "instance_name" {
  description = "Name of the Lightsail instance."
  value       = module.lightsail.instance_name
}

output "static_ip_address" {
  description = "Static IP attached to the instance."
  value       = module.lightsail.static_ip_address
}

output "alarm_names" {
  description = "Alarms created for the instance."
  value       = module.lightsail.alarm_names
}
