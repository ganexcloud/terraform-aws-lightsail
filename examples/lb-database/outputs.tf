output "lb_dns_name" {
  description = "DNS name of the load balancer."
  value       = module.app.lb_dns_name
}

output "lb_certificate_domain_validation_records" {
  description = "Records to publish before attaching the certificate."
  value       = module.app.lb_certificate_domain_validation_records
}

output "database_master_endpoint_address" {
  description = "Endpoint address of the managed database."
  value       = module.app.database_master_endpoint_address
}
