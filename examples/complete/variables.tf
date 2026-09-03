variable "region" {
  description = "AWS region used by the example. Certificates, distributions and DNS zones require us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name used for the certificate, the CDN and the DNS zone."
  type        = string
  default     = "example.com"
}

variable "ssh_public_key" {
  description = "Public key registered as the Lightsail key pair."
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleExampleExampleExampleExampleExample example"
}

variable "database_master_password" {
  description = "Master password for the managed relational database."
  type        = string
  default     = "ExamplePassword123!"
  sensitive   = true
}
