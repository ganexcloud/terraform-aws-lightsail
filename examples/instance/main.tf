# A single Lightsail host with attached storage, a static IP, an explicit
# firewall and native alarms — the shape most Ganex projects use.
#
# The alarms notify the account contact method, which is a per-account,
# per-region singleton with no Terraform resource. Create it once before
# applying this example:
#
#   aws lightsail create-contact-method \
#     --protocol Email --contact-endpoint ops@example.com

module "lightsail" {
  source = "../../"

  name = "ganex-lightsail-example-production"

  instance = {
    availability_zone = "${var.region}a"
    blueprint_id      = "amazon_linux_2023"
    bundle_id         = "small_2_0"
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
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidrs     = var.ssh_cidrs
    },
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
      cidrs     = ["0.0.0.0/0"]
    },
    {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidrs     = ["0.0.0.0/0"]
    },
  ]

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
    environment = "production"
    managed-by  = "terraform"
  }
}
