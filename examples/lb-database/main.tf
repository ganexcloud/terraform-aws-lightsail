# Two instances behind a Lightsail load balancer, backed by a managed
# database. The load balancer certificate is created but not attached:
# attachment only succeeds after the validation records from the
# lb_certificate_domain_validation_records output are published in DNS, so
# flip lb_certificate_attach to true on a second apply.

module "app" {
  source = "../../"

  name = "ganex-lightsail-app"

  instance = {
    availability_zone = "${var.region}a"
    blueprint_id      = "amazon_linux_2023"
    bundle_id         = "small_2_0"
  }

  lb = {
    instance_port     = 80
    health_check_path = "/health"
  }

  lb_certificate = {
    domain_name               = var.domain_name
    subject_alternative_names = ["www.${var.domain_name}"]
  }

  lb_certificate_attach        = false
  lb_https_redirection_enabled = null

  lb_stickiness = {
    enabled         = true
    cookie_duration = 600
  }

  database = {
    blueprint_id             = "mysql_8_0"
    bundle_id                = "micro_2_0"
    master_database_name     = "appdb"
    master_username          = "appuser"
    master_password          = var.database_master_password
    backup_retention_enabled = true
    skip_final_snapshot      = true
  }

  tags = {
    environment = "staging"
    managed-by  = "terraform"
  }
}
