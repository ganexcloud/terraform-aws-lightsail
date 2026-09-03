# Every resource family the module supports, exercised in one configuration.
#
# Certificates, distributions and DNS zones are global resources that AWS only
# exposes through us-east-1, so this example pins that region. Outside
# us-east-1, split those families into a second module call against a
# us-east-1 provider.

module "lightsail" {
  source = "../../"

  name = "ganex-lightsail-complete"

  # ---------------------------------------------------------------- instance
  instance = {
    availability_zone = "${var.region}a"
    blueprint_id      = "amazon_linux_2023"
    bundle_id         = "small_2_0"
    ip_address_type   = "dualstack"
    user_data         = "#!/bin/bash\necho ganex > /etc/ganex-managed\n"
  }

  key_pair = {
    public_key = var.ssh_public_key
  }

  auto_snapshot = {
    snapshot_time = "06:00"
  }

  disks = {
    data = {
      size_in_gb = 20
      disk_path  = "/dev/xvdf"
    }
  }

  create_static_ip = true

  public_ports = [
    {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidrs     = ["0.0.0.0/0"]
    },
  ]

  # --------------------------------------------------------- load balancer
  lb = {
    instance_port     = 80
    health_check_path = "/health"
  }

  lb_stickiness = {
    enabled         = true
    cookie_duration = 600
  }

  # --------------------------------------------------------------- database
  database = {
    blueprint_id         = "mysql_8_0"
    bundle_id            = "micro_2_0"
    master_database_name = "appdb"
    master_username      = "appuser"
    master_password      = var.database_master_password
    skip_final_snapshot  = true
  }

  # ----------------------------------------------------------------- bucket
  bucket = {
    bundle_id = "small_1_0"
  }

  create_bucket_access_key = true
  bucket_resource_access   = ["self"]

  # ------------------------------------------------ certificate and CDN
  certificate = {
    domain_name               = var.domain_name
    subject_alternative_names = ["www.${var.domain_name}"]
  }

  distribution = {
    bundle_id = "small_1_0"

    origin = {
      name            = "ganex-lightsail-complete"
      region_name     = var.region
      protocol_policy = "http-only"
    }

    default_cache_behavior = {
      behavior = "cache"
    }

    cache_behaviors = [
      {
        behavior = "dont-cache"
        path     = "/api/*"
      },
    ]

    cache_behavior_settings = {
      allowed_http_methods = "GET,HEAD,OPTIONS"
      cached_http_methods  = "GET,HEAD"
      default_ttl          = 86400
      minimum_ttl          = 0
      maximum_ttl          = 31536000

      forwarded_cookies = {
        option = "none"
      }

      forwarded_headers = {
        option             = "allow-list"
        headers_allow_list = ["Host"]
      }

      forwarded_query_strings = {
        option = false
      }
    }
  }

  # -------------------------------------------------------- container service
  container_service = {
    power = "nano"
    scale = 1
  }

  container_service_deployment = {
    containers = [
      {
        container_name = "app"
        image          = "public.ecr.aws/nginx/nginx:stable"
        ports          = { "80" = "HTTP" }
        environment    = { APP_ENV = "production" }
      },
    ]

    public_endpoint = {
      container_name = "app"
      container_port = 80

      health_check = {
        path          = "/"
        success_codes = "200-299"
      }
    }
  }

  # -------------------------------------------------------------------- DNS
  domain_name = var.domain_name

  domain_entries = {
    apex = {
      name   = var.domain_name
      type   = "A"
      target = "198.51.100.20"
    }
  }

  # ----------------------------------------------------------------- alarms
  alarms = {
    cpu-high = {
      metric_name         = "CPUUtilization"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 80
      evaluation_periods  = 2
      datapoints_to_alarm = 2
    }
    status-check-failed = {
      metric_name         = "StatusCheckFailed"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      threshold           = 1
    }
  }

  tags = {
    Example    = "complete"
    managed-by = "terraform"
  }
}
