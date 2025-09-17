/*----------------------------------------------------------------------*/
/* General Cloudwatch Alarms                                            */
/*----------------------------------------------------------------------*/

locals {
  # Alarms ECS Services
  cw_alarms_default = {
    "warning-CPUUtilization" = {
      description = "is using more than 70% of CPU"
      threshold   = 70
      unit        = "Percent"
      metric_name = "CPUUtilization"
      statistic   = "Average"
      namespace   = "AWS/ECS"
      period      = 60
      alarms_tags = {
        "alarm-level" = "WARN"
      }
    }
    "critical-CPUUtilization" = {
      description = "is using more than 80% of CPU"
      threshold   = 80
      unit        = "Percent"
      metric_name = "CPUUtilization"
      statistic   = "Average"
      namespace   = "AWS/ECS"
      period      = 60
      alarms_tags = {
        "alarm-level" = "CRIT"
      }
    }
    "warning-MemoryUtilization" = {
      description = "is using more than 80% of memory."
      threshold   = 80
      unit        = "Percent"
      metric_name = "MemoryUtilization"
      statistic   = "Average"
      namespace   = "AWS/ECS"
      period      = 60
      alarms_tags = {
        "alarm-level" = "WARN"
      }
    }
    "critical-MemoryUtilization" = {
      description = "is using more than 90% of memory."
      level       = "CRIT"
      threshold   = 90
      unit        = "Percent"
      metric_name = "MemoryUtilization"
      statistic   = "Average"
      namespace   = "AWS/ECS"
      period      = 60
      alarms_tags = {
        "alarm-level" = "CRIT"
      }
    }
  }
  cw_alarms_tmp = merge([
    for service_name, values in try(var.ecs_service_parameters, []) : {
      for alarm, value in try(local.cw_alarms_default, {}) :
      "${service_name}-${alarm}" =>
      merge(
        value,
        {
          alarm_name         = "${split("/", value.namespace)[1]}-${alarm}-${local.common_name}-${service_name}"
          alarm_description  = "Service[${service_name}] ${value.description}"
          actions_enabled    = try(values.alarms_cw_overrides[alarm].actions_enabled, true)
          evaluation_periods = try(values.alarms_cw_overrides[alarm].evaluation_periods, 5)
          threshold          = try(values.alarms_cw_overrides[alarm].threshold, value.threshold)
          period             = try(values.alarms_cw_overrides[alarm].period, value.period)
          treat_missing_data = try(values.alarms_cw_overrides[alarm].treat_missing_data, "notBreaching")
          dimensions = {
            ClusterName = try(values.ecs_cluster_name, local.default_ecs_cluster_name)
            ServiceName = module.ecs_service["${service_name}"].name
          }
          ok_actions    = []
          alarm_actions = []
          alarms_tags   = merge(try(values.alarms_cw_overrides[alarm].alarms_tags, value.alarms_tags), { "alarm-service-name" = "${local.common_name}-${service_name}" })
      }) if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, false) && !contains(try(values.alarms_cw_disabled, []), alarm)
    }
  ]...)

  cw_alarms_custom_tmp = merge([
    for service_name, values in try(var.ecs_service_parameters, []) : {
      for alarm, value in try(values.alarms_cw_custom, {}) :
      "${service_name}-${alarm}" => merge(
        value,
        {
          alarm_name         = "${split("/", value.namespace)[1]}-${alarm}-${local.common_name}-${service_name}"
          alarm_description  = "Service[${service_name}] ${value.description}"
          actions_enabled    = try(value.actions_enabled, true)
          evaluation_periods = try(value.evaluation_periods, 5)
          threshold          = value.threshold
          period             = value.period
          treat_missing_data = try("${value.treat_missing_data}", "notBreaching")
          dimensions = {
            ClusterName = try(values.ecs_cluster_name, local.default_ecs_cluster_name)
            ServiceName = module.ecs_service["${service_name}"].name
          }
          ok_actions    = []
          alarm_actions = []
          alarms_tags   = merge(try(values.alarms_cw_overrides[alarm].alarms_tags, value.alarms_tags), { "alarm-service-name" = "${local.common_name}-${service_name}" })
        }
      ) if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, false)
    }
  ]...)

  cw_alarms = merge(
    local.cw_alarms_tmp,
    local.cw_alarms_custom_tmp
  )


}

/*----------------------------------------------------------------------*/
/* SNS Alarms Variables                                                 */
/*----------------------------------------------------------------------*/

locals {
  enable_alarms_notifications = length(local.cw_alarms) > 0 && try(var.ecs_service_defaults.alarms_defaults.enable_alarms_notifications, true) ? 1 : 0
}

data "aws_sns_topic" "cw_alarms_sns_topic_name" {
  count = local.enable_alarms_notifications
  name  = try(var.ecs_service_defaults.alarms_defaults.cw_alarms_sns_topic_name, "${local.default_sns_topic_name}")
}

/*----------------------------------------------------------------------*/
/* CW Alarms Variables                                                  */
/*----------------------------------------------------------------------*/

resource "aws_cloudwatch_metric_alarm" "cw_alarms" {
  for_each = nonsensitive(local.cw_alarms)

  alarm_name          = try(each.value.alarm_name, var.ecs_service_defaults.alarms_defaults.alarm_name)
  alarm_description   = try(each.value.alarm_description, var.ecs_service_defaults.alarms_defaults.alarm_description, null)
  actions_enabled     = try(each.value.actions_enabled, var.ecs_service_defaults.alarms_defaults.actions_enabled, true)
  comparison_operator = try(each.value.comparison_operator, var.ecs_service_defaults.alarms_defaults.comparison_operator, "GreaterThanOrEqualToThreshold")
  evaluation_periods  = try(each.value.evaluation_periods, var.ecs_service_defaults.alarms_defaults.evaluation_period, 5)
  threshold           = try(each.value.threshold, var.ecs_service_defaults.alarms_defaults.threshold, null)
  period              = try(each.value.period, var.ecs_service_defaults.alarms_defaults.period, null)
  unit                = try(each.value.unit, var.ecs_service_defaults.alarms_defaults.unit, null)
  namespace           = try(each.value.namespace, var.ecs_service_defaults.alarms_defaults.namespace, null)
  metric_name         = try(each.value.metric_name, var.ecs_service_defaults.alarms_defaults.metric_name, null)
  statistic           = try(each.value.statistic, var.ecs_service_defaults.alarms_defaults.statistic, null)
  extended_statistic  = try(each.value.extended_statistic, var.ecs_service_defaults.alarms_defaults.extended_statistic, null)
  dimensions          = try(each.value.dimensions, var.ecs_service_defaults.alarms_defaults.dimensions, null)
  treat_missing_data  = try(each.value.treat_missing_data, var.ecs_service_defaults.alarms_defaults.treat_missing_data, "notBreaching")

  alarm_actions = concat(try([data.aws_sns_topic.cw_alarms_sns_topic_name[0].arn], []), try(each.value.alarm_actions, var.ecs_service_defaults.alarms_defaults.alarm_actions, []))
  ok_actions    = concat(try([data.aws_sns_topic.cw_alarms_sns_topic_name[0].arn], []), try(each.value.ok_actions, var.ecs_service_defaults.alarms_defaults.ok_actions, []))

  # conflicts with metric_name
  dynamic "metric_query" {
    for_each = try(each.value.metric_query, var.ecs_service_defaults.alarms_defaults.metric_query, [])
    content {
      id          = lookup(metric_query.value, "id")
      account_id  = lookup(metric_query.value, "account_id", null)
      label       = lookup(metric_query.value, "label", null)
      return_data = lookup(metric_query.value, "return_data", null)
      expression  = lookup(metric_query.value, "expression", null)
      period      = lookup(metric_query.value, "period", null)

      dynamic "metric" {
        for_each = lookup(metric_query.value, "metric", [])
        content {
          metric_name = lookup(metric.value, "metric_name")
          namespace   = lookup(metric.value, "namespace")
          period      = lookup(metric.value, "period")
          stat        = lookup(metric.value, "stat")
          unit        = lookup(metric.value, "unit", null)
          dimensions  = lookup(metric.value, "dimensions", null)
        }
      }
    }
  }
  threshold_metric_id = try(each.value.threshold_metric_id, var.ecs_service_defaults.alarms_defaults.threshold_metric_id, null)

  tags = merge(try(each.value.tags, {}), local.common_tags, try(each.value.alarms_tags, {}))
}

/*----------------------------------------------------------------------*/
/* General EventBridge Alarms                                           */
/*----------------------------------------------------------------------*/

locals {
  eb_alarms_default = {
    "task-stopped" = {
      event_bus_name = local.default_event_bus_name # to control EventBridge Bus and related resources
      description    = "ECS Task Restart"
      event_pattern = jsonencode({
        "source" : ["aws.ecs"],
        "detail-type" : ["ECS Task State Change"],
        "detail" : {
          "desiredStatus" : ["STOPPED"],
          "lastStatus" : ["STOPPED"],
          "stopCode" : ["TaskFailedToStart", "EssentialContainerExited"]
        }
      })
      # targets_sns = ["arn-sns-1", "arn-sns-2"]  ## Can add multiple sns targets to same rule. If you not specify, it will use the default sns topic.
    }
    "capacity-unavailable" = {
      event_bus_name = local.default_event_bus_name # to control EventBridge Bus and related resources
      description    = "Capacity for ECS is unavailable at this time."
      event_pattern = jsonencode({
        "source" : ["aws.ecs"],
        "detail-type" : ["ECS Service Action"],
        "detail" : {
          "eventName" : ["SERVICE_TASK_PLACEMENT_FAILURE"],
        }
      })
      # targets_sns = ["arn-sns-1", "arn-sns-2"]  ## Can add multiple sns targets to same rule. If you not specify, it will use the default sns topic.
    }
  }

  eb_alarms_default_parameters_tmp = [
    for service_name, values in try(var.ecs_service_parameters, {}) : [
      for alarm, value in try(local.eb_alarms_default, {}) : {
        "${service_name}-${alarm}" = merge(
          value,
          {
            name           = "${service_name}-${alarm}"
            name_prefix    = try(values.alarms_eb_overrides[alarm].name_prefix, value.name_prefix, null)
            description    = try(values.alarms_eb_overrides[alarm].description, value.description)
            event_bus_name = try(values.alarms_eb_overrides[alarm].event_bus_name, value.event_bus_name)
            event_pattern = jsonencode(
              merge(
                jsondecode(try(values.alarms_eb_overrides[alarm].event_pattern, value.event_pattern)),
                {
                  detail = merge(
                    try(jsondecode(try(values.alarms_eb_overrides[alarm].event_pattern, value.event_pattern)).detail, {}),
                    {
                      group = ["service:${local.common_name}-${service_name}"]
                    }
                  )
                }
              )
            )
            targets_sns         = try(values.alarms_eb_overrides[alarm].targets_sns, value.targets_sns, [])
            schedule_expression = try(values.alarms_eb_overrides[alarm].schedule_expression, value.schedule_expression, null)
            force_destroy       = try(values.alarms_eb_overrides[alarm].force_destroy, value.force_destroy, false)
            role_arn            = try(values.alarms_eb_overrides[alarm].role_arn, value.role_arn, null)
            state               = try(values.alarms_eb_overrides[alarm].state, value.state, null)
          }
        )
      } if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, false) && !contains(try(values.alarms_eb_disabled, []), alarm)
    ]
  ]
  eb_alarms_default_parameters = merge(flatten(local.eb_alarms_default_parameters_tmp)...)

  eb_alarms_custom_tmp = [
    for service_name, values in try(var.ecs_service_parameters, {}) : [
      for alarm, value in try(values.alarms_eb_custom, {}) : {
        "${service_name}-${alarm}" = merge(
          value,
          {
            name           = "${service_name}-${alarm}"
            name_prefix    = try(value.name_prefix, null)
            description    = try(value.description)
            event_bus_name = try(value.event_bus_name, local.default_event_bus_name)
            event_pattern = jsonencode(
              merge(
                jsondecode(try(value.event_pattern, "{}")),
                {
                  detail = merge(
                    try(jsondecode(try(value.event_pattern, "{}")).detail, {}),
                    {
                      group = ["service:${local.common_name}-${service_name}"]
                    }
                  )
                }
              )
            )
            targets_sns         = try(value.targets_sns, [])
            schedule_expression = try(value.schedule_expression, null)
            force_destroy       = try(value.force_destroy, false)
            role_arn            = try(value.role_arn, null)
            state               = try(value.state, null)
          }
        )
      } if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, false)
    ]
  ]
  eb_alarms_custom = merge(flatten(local.eb_alarms_custom_tmp)...)


  eb_alarms = merge(
    local.eb_alarms_default_parameters,
    local.eb_alarms_custom
  )
}

data "aws_cloudwatch_event_bus" "this" {
  for_each = nonsensitive(local.eb_alarms)

  name = each.value.event_bus_name
}

resource "aws_cloudwatch_event_rule" "eb_alarms" {
  for_each = nonsensitive(local.eb_alarms)

  name                = each.value.name
  description         = each.value.description
  event_pattern       = each.value.event_pattern
  name_prefix         = each.value.name_prefix
  schedule_expression = each.value.schedule_expression
  event_bus_name      = data.aws_cloudwatch_event_bus.this[each.key].name
  force_destroy       = each.value.force_destroy
  role_arn            = each.value.role_arn
  state               = each.value.state

  tags = merge(try(each.value.tags, {}), local.common_tags)
}

/*----------------------------------------------------------------------*/
/* Targets SNS                                                          */
/*----------------------------------------------------------------------*/

locals {

  enable_eb_alarms_sns_default = length(local.eb_alarms) > 0 && anytrue([
    for _, value in local.eb_alarms : length(value.targets_sns) == 0
  ]) ? 1 : 0

  alarm_targets_sns_tmp = [
    for alarm_name, alarm_value in local.eb_alarms : [
      for target in length(alarm_value.targets_sns) > 0 ? alarm_value.targets_sns : [data.aws_sns_topic.default[0].arn] : {
        "${alarm_name}-${target}" = {
          rule_name      = aws_cloudwatch_event_rule.eb_alarms[alarm_name].name
          target_arn     = target
          event_bus_name = alarm_value.event_bus_name
          force_destroy  = alarm_value.force_destroy
        }
      }
    ]
  ]

  alarm_targets_sns = merge(flatten(local.alarm_targets_sns_tmp)...)
}

data "aws_sns_topic" "default" {
  count = local.enable_eb_alarms_sns_default
  name  = local.default_sns_topic_name
}
resource "aws_cloudwatch_event_target" "target_sns" {
  for_each = nonsensitive(local.alarm_targets_sns)

  rule           = each.value.rule_name
  arn            = each.value.target_arn
  event_bus_name = each.value.event_bus_name
  force_destroy  = each.value.force_destroy
}
