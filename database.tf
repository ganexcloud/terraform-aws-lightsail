###############################################################################
# Managed relational database
###############################################################################

resource "aws_lightsail_database" "this" {
  count = local.database_enabled ? 1 : 0

  relational_database_name = local.database_name
  blueprint_id             = var.database.blueprint_id
  bundle_id                = var.database.bundle_id
  master_database_name     = var.database.master_database_name
  master_username          = var.database.master_username
  master_password          = var.database.master_password

  availability_zone            = var.database.availability_zone
  apply_immediately            = var.database.apply_immediately
  backup_retention_enabled     = var.database.backup_retention_enabled
  preferred_backup_window      = var.database.preferred_backup_window
  preferred_maintenance_window = var.database.preferred_maintenance_window
  publicly_accessible          = var.database.publicly_accessible
  skip_final_snapshot          = var.database.skip_final_snapshot
  final_snapshot_name          = var.database.final_snapshot_name

  tags = var.tags
}
