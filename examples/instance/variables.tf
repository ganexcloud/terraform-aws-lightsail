variable "region" {
  description = "AWS region used by the example."
  type        = string
  default     = "us-east-1"
}

variable "ssh_public_key" {
  description = "Public key registered as the Lightsail key pair."
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleExampleExampleExampleExampleExample example"
}

variable "ssh_cidrs" {
  description = "CIDR blocks allowed to reach SSH on the instance."
  type        = list(string)
  default     = ["198.51.100.10/32"]
}
