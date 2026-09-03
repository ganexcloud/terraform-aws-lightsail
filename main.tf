###############################################################################
# Instance
#
# The instance family mirrors a single Lightsail host: its key pair, attached
# block storage, static IP and public firewall rules.
###############################################################################

resource "aws_lightsail_key_pair" "this" {
  count = local.create_key_pair ? 1 : 0

  name       = coalesce(var.key_pair.name, var.name)
  public_key = var.key_pair.public_key
  pgp_key    = var.key_pair.pgp_key
  tags       = var.tags
}

resource "aws_lightsail_instance" "this" {
  count = local.instance_enabled ? 1 : 0

  name              = local.instance_name
  availability_zone = var.instance.availability_zone
  blueprint_id      = var.instance.blueprint_id
  bundle_id         = var.instance.bundle_id
  ip_address_type   = var.instance.ip_address_type
  key_pair_name     = local.key_pair_name
  user_data         = var.instance.user_data
  tags              = var.tags

  # Lightsail accepts a single add-on per instance.
  dynamic "add_on" {
    for_each = var.auto_snapshot == null ? [] : [var.auto_snapshot]

    content {
      type          = "AutoSnapshot"
      snapshot_time = add_on.value.snapshot_time
      status        = add_on.value.status
    }
  }

  # user_data only runs on first boot and any change to it forces a
  # replacement, so an edit would silently destroy a live host without
  # re-running anything. Existing instances are left alone; recreate
  # deliberately with `terraform apply -replace` to re-bootstrap.
  lifecycle {
    ignore_changes = [user_data]

    precondition {
      condition     = var.key_pair == null || var.key_pair_name == null
      error_message = "Set either key_pair (to create one) or key_pair_name (to reuse an existing one), not both."
    }
  }
}

resource "aws_lightsail_disk" "this" {
  for_each = var.disks

  name              = coalesce(each.value.name, "${var.name}-${each.key}")
  size_in_gb        = each.value.size_in_gb
  availability_zone = coalesce(each.value.availability_zone, try(var.instance.availability_zone, null))
  tags              = var.tags

  lifecycle {
    precondition {
      condition     = each.value.availability_zone != null || var.instance != null
      error_message = "Disk \"${each.key}\" needs an availability_zone when the module does not create an instance."
    }
  }
}

resource "aws_lightsail_disk_attachment" "this" {
  for_each = local.instance_enabled ? var.disks : {}

  disk_name     = aws_lightsail_disk.this[each.key].name
  instance_name = aws_lightsail_instance.this[0].name
  disk_path     = each.value.disk_path
}

resource "aws_lightsail_static_ip" "this" {
  count = var.create_static_ip ? 1 : 0

  name = local.static_ip_name
}

resource "aws_lightsail_static_ip_attachment" "this" {
  count = var.create_static_ip && local.instance_enabled ? 1 : 0

  static_ip_name = aws_lightsail_static_ip.this[0].name
  instance_name  = aws_lightsail_instance.this[0].name
}

# A non-empty public_ports list is authoritative: Lightsail replaces the whole
# rule set, including the defaults opened at instance creation.
resource "aws_lightsail_instance_public_ports" "this" {
  count = local.instance_enabled && length(var.public_ports) > 0 ? 1 : 0

  instance_name = aws_lightsail_instance.this[0].name

  dynamic "port_info" {
    for_each = var.public_ports

    content {
      from_port         = port_info.value.from_port
      to_port           = port_info.value.to_port
      protocol          = port_info.value.protocol
      cidrs             = port_info.value.cidrs
      ipv6_cidrs        = port_info.value.ipv6_cidrs
      cidr_list_aliases = port_info.value.cidr_list_aliases
    }
  }
}
