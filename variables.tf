###############################################################################
# General
###############################################################################

variable "name" {
  description = "Base name applied to the Lightsail resources created by this module. Each resource family accepts an optional name of its own that overrides this value."
  type        = string
}

variable "tags" {
  description = "Tags applied to every taggable resource created by this module."
  type        = map(string)
  default     = {}
}

###############################################################################
# Instance
###############################################################################

variable "instance" {
  description = "Instance to create. Set to null to skip the instance family. Changing user_data replaces the instance, so the module ignores subsequent changes to it; see the README."
  type = object({
    availability_zone = string
    blueprint_id      = string
    bundle_id         = string
    name              = optional(string)
    ip_address_type   = optional(string)
    user_data         = optional(string)
  })
  default = null
}

variable "auto_snapshot" {
  description = "AutoSnapshot add-on for the instance. Lightsail allows a single add-on per instance. Set to null to disable."
  type = object({
    snapshot_time = string
    status        = optional(string, "Enabled")
  })
  default = null
}

variable "key_pair" {
  description = "SSH key pair to create for the instance. Omit public_key to have Lightsail generate the pair, exposing it through the key_pair_private_key output. Mutually exclusive with key_pair_name."
  type = object({
    name       = optional(string)
    public_key = optional(string)
    pgp_key    = optional(string)
  })
  default = null
}

variable "key_pair_name" {
  description = "Name of an existing Lightsail key pair to attach to the instance. Mutually exclusive with key_pair."
  type        = string
  default     = null
}

variable "disks" {
  description = "Additional block storage disks to create and attach to the instance, keyed by an arbitrary identifier used as the name suffix."
  type = map(object({
    size_in_gb        = number
    disk_path         = string
    availability_zone = optional(string)
    name              = optional(string)
  }))
  default = {}
}

variable "create_static_ip" {
  description = "Whether to allocate a static IP and attach it to the instance."
  type        = bool
  default     = false
}

variable "static_ip_name" {
  description = "Name of the static IP. Defaults to \"<name>-ip\"."
  type        = string
  default     = null
}

variable "public_ports" {
  description = "Public port rules for the instance firewall. An empty list leaves the Lightsail defaults untouched; a non-empty list becomes the authoritative rule set."
  type = list(object({
    from_port         = number
    to_port           = number
    protocol          = string
    cidrs             = optional(set(string))
    ipv6_cidrs        = optional(set(string))
    cidr_list_aliases = optional(set(string))
  }))
  default = []
}

###############################################################################
# Load balancer
###############################################################################

variable "lb" {
  description = "Load balancer to create. Set to null to skip the load balancer family."
  type = object({
    instance_port     = number
    name              = optional(string)
    health_check_path = optional(string)
    ip_address_type   = optional(string)
  })
  default = null
}

variable "lb_attached_instances" {
  description = "Names of the instances to attach to the load balancer. When empty, the instance created by this module is attached, if any."
  type        = list(string)
  default     = []
}

variable "lb_certificate" {
  description = "TLS certificate to create on the load balancer. Set to null to skip."
  type = object({
    domain_name               = string
    name                      = optional(string)
    subject_alternative_names = optional(set(string))
  })
  default = null
}

variable "lb_certificate_attach" {
  description = "Whether to attach lb_certificate to the load balancer. Attachment only succeeds after the certificate is validated, so this is usually enabled on a second apply."
  type        = bool
  default     = false
}

variable "lb_https_redirection_enabled" {
  description = "Whether to redirect HTTP to HTTPS on the load balancer. Set to null to leave the policy unmanaged. Requires an attached certificate."
  type        = bool
  default     = null
}

variable "lb_stickiness" {
  description = "Session stickiness policy for the load balancer. Set to null to leave it unmanaged."
  type = object({
    enabled         = bool
    cookie_duration = number
  })
  default = null
}

###############################################################################
# Database
###############################################################################

variable "database" {
  description = "Managed relational database to create. Set to null to skip the database family."
  type = object({
    blueprint_id                 = string
    bundle_id                    = string
    master_database_name         = string
    master_username              = string
    master_password              = string
    relational_database_name     = optional(string)
    availability_zone            = optional(string)
    apply_immediately            = optional(bool)
    backup_retention_enabled     = optional(bool)
    preferred_backup_window      = optional(string)
    preferred_maintenance_window = optional(string)
    publicly_accessible          = optional(bool)
    skip_final_snapshot          = optional(bool)
    final_snapshot_name          = optional(string)
  })
  default   = null
  sensitive = true
}

###############################################################################
# Bucket
###############################################################################

variable "bucket" {
  description = "Object storage bucket to create. Set to null to skip the bucket family."
  type = object({
    bundle_id    = string
    name         = optional(string)
    force_delete = optional(bool)
  })
  default = null
}

variable "create_bucket_access_key" {
  description = "Whether to create an access key for the bucket. The secret is exposed through the bucket_secret_access_key output and stored in state."
  type        = bool
  default     = false
}

variable "bucket_resource_access" {
  description = "Names of Lightsail resources (for example instances) granted access to the bucket. Use the literal string \"self\" to reference the instance created by this module."
  type        = list(string)
  default     = []
}

###############################################################################
# Certificate and distribution
###############################################################################

variable "certificate" {
  description = "Lightsail certificate to create for use with a distribution. Only manageable in us-east-1. Set to null to skip."
  type = object({
    domain_name               = string
    name                      = optional(string)
    subject_alternative_names = optional(set(string))
  })
  default = null
}

variable "distribution" {
  description = "CDN distribution to create. Only manageable in us-east-1. Set to null to skip."
  type = object({
    bundle_id = string
    origin = object({
      name            = string
      region_name     = string
      protocol_policy = optional(string)
    })
    name                   = optional(string)
    certificate_name       = optional(string)
    ip_address_type        = optional(string)
    is_enabled             = optional(bool)
    default_cache_behavior = optional(object({ behavior = string }), { behavior = "cache" })
    cache_behaviors = optional(list(object({
      behavior = string
      path     = string
    })), [])
    cache_behavior_settings = optional(object({
      allowed_http_methods = optional(string)
      cached_http_methods  = optional(string)
      default_ttl          = optional(number)
      maximum_ttl          = optional(number)
      minimum_ttl          = optional(number)
      forwarded_cookies = optional(object({
        option             = optional(string)
        cookies_allow_list = optional(set(string))
      }))
      forwarded_headers = optional(object({
        option             = optional(string)
        headers_allow_list = optional(set(string))
      }))
      forwarded_query_strings = optional(object({
        option                     = optional(bool)
        query_strings_allowed_list = optional(set(string))
      }))
    }))
  })
  default = null
}

###############################################################################
# Container service
###############################################################################

variable "container_service" {
  description = "Container service to create. Set to null to skip the container family."
  type = object({
    power       = string
    scale       = number
    name        = optional(string)
    is_disabled = optional(bool)
    public_domain_names = optional(object({
      certificate = list(object({
        certificate_name = string
        domain_names     = list(string)
      }))
    }))
  })
  default = null
}

variable "container_service_deployment" {
  description = "Deployment version for the container service. Every change creates a new immutable version. Set to null to leave deployments unmanaged."
  type = object({
    containers = list(object({
      container_name = string
      image          = string
      command        = optional(list(string))
      environment    = optional(map(string))
      ports          = optional(map(string))
    }))
    public_endpoint = optional(object({
      container_name = string
      container_port = number
      health_check = optional(object({
        healthy_threshold   = optional(number)
        unhealthy_threshold = optional(number)
        interval_seconds    = optional(number)
        timeout_seconds     = optional(number)
        path                = optional(string)
        success_codes       = optional(string)
      }), {})
    }))
  })
  default = null
}

###############################################################################
# DNS
###############################################################################

variable "domain_name" {
  description = "Lightsail DNS zone to create. Only manageable in us-east-1. Set to null to skip the DNS family."
  type        = string
  default     = null
}

variable "domain_entries" {
  description = "Records to create in the Lightsail DNS zone, keyed by an arbitrary identifier. Requires domain_name."
  type = map(object({
    name     = string
    type     = string
    target   = string
    is_alias = optional(bool)
  }))
  default = {}
}

###############################################################################
# Alarms
###############################################################################

variable "alarms" {
  description = "Lightsail alarms to create, keyed by an arbitrary identifier used as the name suffix. Requires a contact method to already exist in the account; see the README."
  type = map(object({
    metric_name           = string
    comparison_operator   = string
    threshold             = number
    evaluation_periods    = optional(number, 1)
    datapoints_to_alarm   = optional(number, 1)
    contact_protocols     = optional(set(string), ["Email"])
    notification_enabled  = optional(bool, true)
    notification_triggers = optional(set(string), ["ALARM"])
    treat_missing_data    = optional(string, "missing")
    alarm_name            = optional(string)
  }))
  default = {}
}

variable "alarm_monitored_resource_name" {
  description = "Name of the Lightsail resource the alarms monitor. Defaults to the instance created by this module."
  type        = string
  default     = null
}
