variable "region" {
  description = "AWS region used by the example."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name requested on the load balancer certificate."
  type        = string
  default     = "example.com"
}

variable "database_master_password" {
  description = "Master password for the managed relational database."
  type        = string
  default     = "ExamplePassword123!"
  sensitive   = true
}
