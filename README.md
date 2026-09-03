# terraform-aws-lightsail

Terraform module that creates and manages AWS Lightsail resources: instances with
their key pairs, block storage, static IPs and firewall rules, plus load
balancers, managed relational databases, object storage buckets, certificates,
CDN distributions, container services, DNS zones and native alarms.

## Compatibility

This module requires Terraform 1.6.0 or later, AWS provider versions from 5.40.0
up to but not including 7.0.0, and AWS Cloud Control (`awscc`) provider versions
from 1.0.0 up to but not including 2.0.0.

## Usage

Each resource family is enabled by supplying its input and skipped when that
input is left at its default. A single instance with storage, a static IP, an
explicit firewall and alarms looks like this:

```hcl
module "lightsail" {
  source  = "ganexcloud/lightsail/aws"
  version = "~> 1.0"

  name = "app-production"

  instance = {
    availability_zone = "us-east-1a"
    blueprint_id      = "amazon_linux_2023"
    bundle_id         = "small_2_0"
  }

  key_pair      = { public_key = var.ssh_public_key }
  auto_snapshot = { snapshot_time = "06:00" }

  disks = {
    data = {
      size_in_gb = 20
      disk_path  = "/dev/xvdf"
    }
  }

  create_static_ip = true

  public_ports = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidrs = ["198.51.100.10/32"] },
    { from_port = 443, to_port = 443, protocol = "tcp", cidrs = ["0.0.0.0/0"] },
  ]

  alarms = {
    cpu-high = {
      metric_name         = "CPUUtilization"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 2
    }
  }

  tags = {
    environment = "production"
    managed-by  = "terraform"
  }
}
```

## Resource families

| Family | Enabled by | Creates |
|---|---|---|
| Instance | `instance` | instance, optional key pair, disks, static IP, public ports |
| Load balancer | `lb` | load balancer, instance attachments, certificate, redirection and stickiness policies |
| Database | `database` | managed relational database |
| Bucket | `bucket` | bucket, optional access key, resource access grants |
| Certificate | `certificate` | Lightsail certificate |
| Distribution | `distribution` | CDN distribution |
| Container service | `container_service` | container service and optional deployment version |
| DNS | `domain_name` | DNS zone and `domain_entries` records |
| Alarms | `alarms` | native Lightsail alarms |

## Alarms need a contact method

Lightsail alarms notify a **contact method**, which is a singleton per account
and region. Neither the AWS provider nor Cloud Control exposes it as a resource,
so it is not managed here. Create it once before applying, otherwise alarms are
created but stay silent:

```sh
aws lightsail create-contact-method --protocol Email --contact-endpoint ops@example.com
```

The email address must then confirm the subscription.

Alarms are created through the `awscc` provider because the AWS provider has no
Lightsail alarm resource. That provider is therefore a hard requirement of the
module even when `alarms` is left empty.

By default alarms monitor the instance this module creates. Point them at
another Lightsail resource with `alarm_monitored_resource_name`.

## Regional constraints

Lightsail certificates, CDN distributions and DNS zones are global resources
that AWS only exposes through `us-east-1`. The module deliberately does not
declare a provider configuration alias for them, because that would force every
consumer to pass a second provider even when only creating an instance.

To manage a regional instance and a global distribution together, call the
module twice:

```hcl
module "app" {
  source = "ganexcloud/lightsail/aws"
  name   = "app-production"

  instance = {
    availability_zone = "sa-east-1a"
    blueprint_id      = "amazon_linux_2023"
    bundle_id         = "small_2_0"
  }
}

module "app_cdn" {
  source    = "ganexcloud/lightsail/aws"
  providers = { aws = aws.us_east_1 }

  name        = "app-production"
  domain_name = "example.com"

  distribution = {
    bundle_id = "small_1_0"
    origin = {
      name        = module.app.instance_name
      region_name = "sa-east-1"
    }
  }
}
```

## Changing `user_data`

Lightsail runs `user_data` only on first boot, and the AWS provider forces a
replacement whenever the value changes. Editing it would silently destroy a live
host without re-running anything, so the module ignores subsequent changes to
`user_data`. Rebuild deliberately when the bootstrap has to run again:

```sh
terraform apply -replace='module.lightsail.aws_lightsail_instance.this[0]'
```

## Load balancer certificates

A load balancer certificate can only be attached after it is validated. Create
it first, publish the records from the
`lb_certificate_domain_validation_records` output, then set
`lb_certificate_attach = true` on a second apply. `lb_https_redirection_enabled`
requires an attached certificate.

## Notes

- `public_ports` is authoritative when non-empty: Lightsail replaces the entire
  rule set, including the ports opened by default at instance creation. Leave it
  empty to keep the Lightsail defaults.
- Lightsail accepts a single add-on per instance, which is why `auto_snapshot` is
  an object rather than a list.
- `bucket_resource_access` accepts the literal `"self"` as shorthand for the
  instance created by this module.
- Each change to `container_service_deployment` publishes a new immutable
  deployment version; Lightsail keeps the previous ones.
- The bucket secret access key and the database master password are stored in
  Terraform state.

## Examples

- [`examples/instance`](examples/instance) — a single host with storage, static IP, firewall and alarms.
- [`examples/lb-database`](examples/lb-database) — load balancer, certificate and managed database.
- [`examples/complete`](examples/complete) — every resource family.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.40.0, < 7.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.0.0, < 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.40.0, < 7.0.0 |
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | >= 1.0.0, < 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lightsail_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_bucket) | resource |
| [aws_lightsail_bucket_access_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_bucket_access_key) | resource |
| [aws_lightsail_bucket_resource_access.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_bucket_resource_access) | resource |
| [aws_lightsail_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_certificate) | resource |
| [aws_lightsail_container_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_container_service) | resource |
| [aws_lightsail_container_service_deployment_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_container_service_deployment_version) | resource |
| [aws_lightsail_database.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_database) | resource |
| [aws_lightsail_disk.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_disk) | resource |
| [aws_lightsail_disk_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_disk_attachment) | resource |
| [aws_lightsail_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_distribution) | resource |
| [aws_lightsail_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_domain) | resource |
| [aws_lightsail_domain_entry.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_domain_entry) | resource |
| [aws_lightsail_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_instance) | resource |
| [aws_lightsail_instance_public_ports.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_instance_public_ports) | resource |
| [aws_lightsail_key_pair.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_key_pair) | resource |
| [aws_lightsail_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_lb) | resource |
| [aws_lightsail_lb_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_lb_attachment) | resource |
| [aws_lightsail_lb_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_lb_certificate) | resource |
| [aws_lightsail_lb_certificate_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_lb_certificate_attachment) | resource |
| [aws_lightsail_lb_https_redirection_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_lb_https_redirection_policy) | resource |
| [aws_lightsail_lb_stickiness_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_lb_stickiness_policy) | resource |
| [aws_lightsail_static_ip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_static_ip) | resource |
| [aws_lightsail_static_ip_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lightsail_static_ip_attachment) | resource |
| [awscc_lightsail_alarm.this](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/lightsail_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_monitored_resource_name"></a> [alarm\_monitored\_resource\_name](#input\_alarm\_monitored\_resource\_name) | Name of the Lightsail resource the alarms monitor. Defaults to the instance created by this module. | `string` | `null` | no |
| <a name="input_alarms"></a> [alarms](#input\_alarms) | Lightsail alarms to create, keyed by an arbitrary identifier used as the name suffix. Requires a contact method to already exist in the account; see the README. | <pre>map(object({<br/>    metric_name           = string<br/>    comparison_operator   = string<br/>    threshold             = number<br/>    evaluation_periods    = optional(number, 1)<br/>    datapoints_to_alarm   = optional(number, 1)<br/>    contact_protocols     = optional(set(string), ["Email"])<br/>    notification_enabled  = optional(bool, true)<br/>    notification_triggers = optional(set(string), ["ALARM"])<br/>    treat_missing_data    = optional(string, "missing")<br/>    alarm_name            = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_auto_snapshot"></a> [auto\_snapshot](#input\_auto\_snapshot) | AutoSnapshot add-on for the instance. Lightsail allows a single add-on per instance. Set to null to disable. | <pre>object({<br/>    snapshot_time = string<br/>    status        = optional(string, "Enabled")<br/>  })</pre> | `null` | no |
| <a name="input_bucket"></a> [bucket](#input\_bucket) | Object storage bucket to create. Set to null to skip the bucket family. | <pre>object({<br/>    bundle_id    = string<br/>    name         = optional(string)<br/>    force_delete = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_bucket_resource_access"></a> [bucket\_resource\_access](#input\_bucket\_resource\_access) | Names of Lightsail resources (for example instances) granted access to the bucket. Use the literal string "self" to reference the instance created by this module. | `list(string)` | `[]` | no |
| <a name="input_certificate"></a> [certificate](#input\_certificate) | Lightsail certificate to create for use with a distribution. Only manageable in us-east-1. Set to null to skip. | <pre>object({<br/>    domain_name               = string<br/>    name                      = optional(string)<br/>    subject_alternative_names = optional(set(string))<br/>  })</pre> | `null` | no |
| <a name="input_container_service"></a> [container\_service](#input\_container\_service) | Container service to create. Set to null to skip the container family. | <pre>object({<br/>    power       = string<br/>    scale       = number<br/>    name        = optional(string)<br/>    is_disabled = optional(bool)<br/>    public_domain_names = optional(object({<br/>      certificate = list(object({<br/>        certificate_name = string<br/>        domain_names     = list(string)<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_container_service_deployment"></a> [container\_service\_deployment](#input\_container\_service\_deployment) | Deployment version for the container service. Every change creates a new immutable version. Set to null to leave deployments unmanaged. | <pre>object({<br/>    containers = list(object({<br/>      container_name = string<br/>      image          = string<br/>      command        = optional(list(string))<br/>      environment    = optional(map(string))<br/>      ports          = optional(map(string))<br/>    }))<br/>    public_endpoint = optional(object({<br/>      container_name = string<br/>      container_port = number<br/>      health_check = optional(object({<br/>        healthy_threshold   = optional(number)<br/>        unhealthy_threshold = optional(number)<br/>        interval_seconds    = optional(number)<br/>        timeout_seconds     = optional(number)<br/>        path                = optional(string)<br/>        success_codes       = optional(string)<br/>      }), {})<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_create_bucket_access_key"></a> [create\_bucket\_access\_key](#input\_create\_bucket\_access\_key) | Whether to create an access key for the bucket. The secret is exposed through the bucket\_secret\_access\_key output and stored in state. | `bool` | `false` | no |
| <a name="input_create_static_ip"></a> [create\_static\_ip](#input\_create\_static\_ip) | Whether to allocate a static IP and attach it to the instance. | `bool` | `false` | no |
| <a name="input_database"></a> [database](#input\_database) | Managed relational database to create. Set to null to skip the database family. | <pre>object({<br/>    blueprint_id                 = string<br/>    bundle_id                    = string<br/>    master_database_name         = string<br/>    master_username              = string<br/>    master_password              = string<br/>    relational_database_name     = optional(string)<br/>    availability_zone            = optional(string)<br/>    apply_immediately            = optional(bool)<br/>    backup_retention_enabled     = optional(bool)<br/>    preferred_backup_window      = optional(string)<br/>    preferred_maintenance_window = optional(string)<br/>    publicly_accessible          = optional(bool)<br/>    skip_final_snapshot          = optional(bool)<br/>    final_snapshot_name          = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_disks"></a> [disks](#input\_disks) | Additional block storage disks to create and attach to the instance, keyed by an arbitrary identifier used as the name suffix. | <pre>map(object({<br/>    size_in_gb        = number<br/>    disk_path         = string<br/>    availability_zone = optional(string)<br/>    name              = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_distribution"></a> [distribution](#input\_distribution) | CDN distribution to create. Only manageable in us-east-1. Set to null to skip. | <pre>object({<br/>    bundle_id = string<br/>    origin = object({<br/>      name            = string<br/>      region_name     = string<br/>      protocol_policy = optional(string)<br/>    })<br/>    name                   = optional(string)<br/>    certificate_name       = optional(string)<br/>    ip_address_type        = optional(string)<br/>    is_enabled             = optional(bool)<br/>    default_cache_behavior = optional(object({ behavior = string }), { behavior = "cache" })<br/>    cache_behaviors = optional(list(object({<br/>      behavior = string<br/>      path     = string<br/>    })), [])<br/>    cache_behavior_settings = optional(object({<br/>      allowed_http_methods = optional(string)<br/>      cached_http_methods  = optional(string)<br/>      default_ttl          = optional(number)<br/>      maximum_ttl          = optional(number)<br/>      minimum_ttl          = optional(number)<br/>      forwarded_cookies = optional(object({<br/>        option             = optional(string)<br/>        cookies_allow_list = optional(set(string))<br/>      }))<br/>      forwarded_headers = optional(object({<br/>        option             = optional(string)<br/>        headers_allow_list = optional(set(string))<br/>      }))<br/>      forwarded_query_strings = optional(object({<br/>        option                     = optional(bool)<br/>        query_strings_allowed_list = optional(set(string))<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_domain_entries"></a> [domain\_entries](#input\_domain\_entries) | Records to create in the Lightsail DNS zone, keyed by an arbitrary identifier. Requires domain\_name. | <pre>map(object({<br/>    name     = string<br/>    type     = string<br/>    target   = string<br/>    is_alias = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Lightsail DNS zone to create. Only manageable in us-east-1. Set to null to skip the DNS family. | `string` | `null` | no |
| <a name="input_instance"></a> [instance](#input\_instance) | Instance to create. Set to null to skip the instance family. Changing user\_data replaces the instance, so the module ignores subsequent changes to it; see the README. | <pre>object({<br/>    availability_zone = string<br/>    blueprint_id      = string<br/>    bundle_id         = string<br/>    name              = optional(string)<br/>    ip_address_type   = optional(string)<br/>    user_data         = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_key_pair"></a> [key\_pair](#input\_key\_pair) | SSH key pair to create for the instance. Omit public\_key to have Lightsail generate the pair, exposing it through the key\_pair\_private\_key output. Mutually exclusive with key\_pair\_name. | <pre>object({<br/>    name       = optional(string)<br/>    public_key = optional(string)<br/>    pgp_key    = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | Name of an existing Lightsail key pair to attach to the instance. Mutually exclusive with key\_pair. | `string` | `null` | no |
| <a name="input_lb"></a> [lb](#input\_lb) | Load balancer to create. Set to null to skip the load balancer family. | <pre>object({<br/>    instance_port     = number<br/>    name              = optional(string)<br/>    health_check_path = optional(string)<br/>    ip_address_type   = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_lb_attached_instances"></a> [lb\_attached\_instances](#input\_lb\_attached\_instances) | Names of the instances to attach to the load balancer. When empty, the instance created by this module is attached, if any. | `list(string)` | `[]` | no |
| <a name="input_lb_certificate"></a> [lb\_certificate](#input\_lb\_certificate) | TLS certificate to create on the load balancer. Set to null to skip. | <pre>object({<br/>    domain_name               = string<br/>    name                      = optional(string)<br/>    subject_alternative_names = optional(set(string))<br/>  })</pre> | `null` | no |
| <a name="input_lb_certificate_attach"></a> [lb\_certificate\_attach](#input\_lb\_certificate\_attach) | Whether to attach lb\_certificate to the load balancer. Attachment only succeeds after the certificate is validated, so this is usually enabled on a second apply. | `bool` | `false` | no |
| <a name="input_lb_https_redirection_enabled"></a> [lb\_https\_redirection\_enabled](#input\_lb\_https\_redirection\_enabled) | Whether to redirect HTTP to HTTPS on the load balancer. Set to null to leave the policy unmanaged. Requires an attached certificate. | `bool` | `null` | no |
| <a name="input_lb_stickiness"></a> [lb\_stickiness](#input\_lb\_stickiness) | Session stickiness policy for the load balancer. Set to null to leave it unmanaged. | <pre>object({<br/>    enabled         = bool<br/>    cookie_duration = number<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name applied to the Lightsail resources created by this module. Each resource family accepts an optional name of its own that overrides this value. | `string` | n/a | yes |
| <a name="input_public_ports"></a> [public\_ports](#input\_public\_ports) | Public port rules for the instance firewall. An empty list leaves the Lightsail defaults untouched; a non-empty list becomes the authoritative rule set. | <pre>list(object({<br/>    from_port         = number<br/>    to_port           = number<br/>    protocol          = string<br/>    cidrs             = optional(set(string))<br/>    ipv6_cidrs        = optional(set(string))<br/>    cidr_list_aliases = optional(set(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_static_ip_name"></a> [static\_ip\_name](#input\_static\_ip\_name) | Name of the static IP. Defaults to "<name>-ip". | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every taggable resource created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_arns"></a> [alarm\_arns](#output\_alarm\_arns) | ARNs of the Lightsail alarms, keyed by the alarms input key. |
| <a name="output_alarm_names"></a> [alarm\_names](#output\_alarm\_names) | Names of the Lightsail alarms, keyed by the alarms input key. |
| <a name="output_bucket_access_key_id"></a> [bucket\_access\_key\_id](#output\_bucket\_access\_key\_id) | Access key ID created for the bucket. |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the object storage bucket. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the object storage bucket. |
| <a name="output_bucket_secret_access_key"></a> [bucket\_secret\_access\_key](#output\_bucket\_secret\_access\_key) | Secret access key created for the bucket. |
| <a name="output_bucket_url"></a> [bucket\_url](#output\_bucket\_url) | URL of the object storage bucket. |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the Lightsail certificate. |
| <a name="output_certificate_domain_validation_options"></a> [certificate\_domain\_validation\_options](#output\_certificate\_domain\_validation\_options) | DNS records that must be published to validate the Lightsail certificate. |
| <a name="output_certificate_name"></a> [certificate\_name](#output\_certificate\_name) | Name of the Lightsail certificate. |
| <a name="output_container_service_arn"></a> [container\_service\_arn](#output\_container\_service\_arn) | ARN of the container service. |
| <a name="output_container_service_deployment_version"></a> [container\_service\_deployment\_version](#output\_container\_service\_deployment\_version) | Version number of the current container service deployment. |
| <a name="output_container_service_name"></a> [container\_service\_name](#output\_container\_service\_name) | Name of the container service. |
| <a name="output_container_service_private_domain_name"></a> [container\_service\_private\_domain\_name](#output\_container\_service\_private\_domain\_name) | Private domain name of the container service. |
| <a name="output_container_service_url"></a> [container\_service\_url](#output\_container\_service\_url) | Public URL of the container service. |
| <a name="output_database_arn"></a> [database\_arn](#output\_database\_arn) | ARN of the managed relational database. |
| <a name="output_database_master_endpoint_address"></a> [database\_master\_endpoint\_address](#output\_database\_master\_endpoint\_address) | Endpoint address of the managed relational database. |
| <a name="output_database_master_endpoint_port"></a> [database\_master\_endpoint\_port](#output\_database\_master\_endpoint\_port) | Endpoint port of the managed relational database. |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the managed relational database. |
| <a name="output_disk_arns"></a> [disk\_arns](#output\_disk\_arns) | ARNs of the block storage disks, keyed by the disks input key. |
| <a name="output_disk_names"></a> [disk\_names](#output\_disk\_names) | Names of the block storage disks, keyed by the disks input key. |
| <a name="output_distribution_arn"></a> [distribution\_arn](#output\_distribution\_arn) | ARN of the CDN distribution. |
| <a name="output_distribution_domain_name"></a> [distribution\_domain\_name](#output\_distribution\_domain\_name) | Domain name of the CDN distribution. |
| <a name="output_distribution_name"></a> [distribution\_name](#output\_distribution\_name) | Name of the CDN distribution. |
| <a name="output_distribution_status"></a> [distribution\_status](#output\_distribution\_status) | Status of the CDN distribution. |
| <a name="output_domain_arn"></a> [domain\_arn](#output\_domain\_arn) | ARN of the Lightsail DNS zone. |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | Name of the Lightsail DNS zone. |
| <a name="output_instance_arn"></a> [instance\_arn](#output\_instance\_arn) | ARN of the Lightsail instance. |
| <a name="output_instance_ipv6_addresses"></a> [instance\_ipv6\_addresses](#output\_instance\_ipv6\_addresses) | IPv6 addresses assigned to the instance. |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | Name of the Lightsail instance. |
| <a name="output_instance_private_ip_address"></a> [instance\_private\_ip\_address](#output\_instance\_private\_ip\_address) | Private IP address assigned to the instance. |
| <a name="output_instance_public_ip_address"></a> [instance\_public\_ip\_address](#output\_instance\_public\_ip\_address) | Public IP address assigned to the instance. |
| <a name="output_instance_username"></a> [instance\_username](#output\_instance\_username) | Default user name for connecting to the instance. |
| <a name="output_key_pair_fingerprint"></a> [key\_pair\_fingerprint](#output\_key\_pair\_fingerprint) | Fingerprint of the key pair created by this module. |
| <a name="output_key_pair_name"></a> [key\_pair\_name](#output\_key\_pair\_name) | Name of the key pair attached to the instance, whether created here or supplied. |
| <a name="output_key_pair_private_key"></a> [key\_pair\_private\_key](#output\_key\_pair\_private\_key) | Private key generated by Lightsail when key\_pair is created without a public\_key. |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | ARN of the load balancer. |
| <a name="output_lb_certificate_domain_validation_records"></a> [lb\_certificate\_domain\_validation\_records](#output\_lb\_certificate\_domain\_validation\_records) | DNS records that must be published to validate the load balancer certificate before it can be attached. |
| <a name="output_lb_certificate_name"></a> [lb\_certificate\_name](#output\_lb\_certificate\_name) | Name of the load balancer TLS certificate. |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | DNS name of the load balancer. |
| <a name="output_lb_name"></a> [lb\_name](#output\_lb\_name) | Name of the load balancer. |
| <a name="output_static_ip_address"></a> [static\_ip\_address](#output\_static\_ip\_address) | Static IP address allocated for the instance. Point DNS records here. |
| <a name="output_static_ip_name"></a> [static\_ip\_name](#output\_static\_ip\_name) | Name of the static IP allocated for the instance. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache 2.0. See [LICENSE](LICENSE).
