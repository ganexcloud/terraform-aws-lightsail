###############################################################################
# Alarms
#
# The AWS provider has no Lightsail alarm resource, so alarms come from the
# Cloud Control provider. The contact method they notify is a per-account,
# per-region singleton with no resource in either provider; create it once
# outside Terraform as documented in the README.
###############################################################################

resource "awscc_lightsail_alarm" "this" {
  for_each = var.alarms

  alarm_name              = coalesce(each.value.alarm_name, "${var.name}-${each.key}")
  monitored_resource_name = local.alarm_monitored_resource_name
  metric_name             = each.value.metric_name
  comparison_operator     = each.value.comparison_operator
  threshold               = each.value.threshold
  evaluation_periods      = each.value.evaluation_periods
  datapoints_to_alarm     = each.value.datapoints_to_alarm
  contact_protocols       = each.value.contact_protocols
  notification_enabled    = each.value.notification_enabled
  notification_triggers   = each.value.notification_triggers
  treat_missing_data      = each.value.treat_missing_data

  lifecycle {
    precondition {
      condition     = var.alarm_monitored_resource_name != null || var.instance != null
      error_message = "Alarms need a target: set alarm_monitored_resource_name, or let the module create an instance."
    }
  }
}
