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
      alarms_tags = {
        "alarm-level" = "CRIT"
      }
    }
  }
  cw_alarms_default_tmp = merge([
    for service_name, values in try(var.ecs_service_parameters, []) : {
      for alarm, value in try(local.cw_alarms_default, {}) :
      "${service_name}-${alarm}" =>
      merge(
        value,
        {
          alarm_name          = "ECS-${alarm}-${local.common_name}-${service_name}"
          alarm_description   = "Service[${service_name}] ${value.description}"
          actions_enabled     = try(values.alarms_cw_overrides[alarm].actions_enabled, true)
          comparison_operator = try(values.alarms_cw_overrides[alarm].comparison_operator, value.comparison_operator, "GreaterThanOrEqualToThreshold")
          datapoints_to_alarm = try(values.alarms_cw_overrides[alarm].datapoints_to_alarm, value.datapoints_to_alarm, 5)
          evaluation_periods  = try(values.alarms_cw_overrides[alarm].evaluation_periods, value.evaluation_periods, 5)
          namespace           = try(values.alarms_cw_overrides[alarm].namespace, value.namespace, "AWS/ECS")
          metric_name         = try(values.alarms_cw_overrides[alarm].metric_name, value.metric_name)
          threshold           = try(values.alarms_cw_overrides[alarm].threshold, value.threshold)
          statistic           = try(values.alarms_cw_overrides[alarm].statistic, value.statistic, null)
          extended_statistic  = try(values.alarms_cw_overrides[alarm].extended_statistic, value.extended_statistic, null)
          period              = try(values.alarms_cw_overrides[alarm].period, value.period, 60)
          unit                = try(values.alarms_cw_overrides[alarm].unit, value.unit)
          treat_missing_data  = try(values.alarms_cw_overrides[alarm].treat_missing_data, "notBreaching")
          dimensions = {
            ClusterName = try(values.ecs_cluster_name, local.default_ecs_cluster_name)
            ServiceName = module.ecs_service["${service_name}"].name
          }
          ok_actions    = try(values.alarms_cw_overrides[alarm].ok_actions, var.ecs_service_defaults.cw_alarms_defaults.ok_actions, [])
          alarm_actions = try(values.alarms_cw_overrides[alarm].alarm_actions, var.ecs_service_defaults.cw_alarms_defaults.alarm_actions, [])
          alarms_tags   = merge(try(values.alarms_cw_overrides[alarm].alarms_tags, value.alarms_tags), { "alarm-service-name" = "${local.common_name}-${service_name}" })
      }) if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, var.ecs_service_defaults.enable_alarms, false) && !contains(try(values.alarms_cw_disabled, var.ecs_service_defaults.cw_alarms_defaults.alarms_cw_disabled, []), alarm)
    }
  ]...)

  cw_alarms_custom_tmp = merge([
    for service_name, values in try(var.ecs_service_parameters, []) : {
      for alarm, value in try(values.alarms_cw_custom, {}) :
      "${service_name}-${alarm}" => merge(
        value,
        {
          alarm_name          = "ECS-${alarm}-${local.common_name}-${service_name}"
          alarm_description   = "Service[${service_name}] ${value.description}"
          actions_enabled     = try(value.actions_enabled, true)
          comparison_operator = try(value.comparison_operator, "GreaterThanOrEqualToThreshold")
          datapoints_to_alarm = try(value.datapoints_to_alarm, 5)
          evaluation_periods  = try(value.evaluation_periods, 5)
          namespace           = try(value.namespace, "AWS/ECS")
          metric_name         = try(value.metric_name, null)
          threshold           = try(value.threshold, null)
          statistic           = try(value.statistic, null)
          extended_statistic  = try(value.extended_statistic, null)
          period              = try(value.period, 60)
          unit                = try(value.unit, null)
          treat_missing_data  = try(value.treat_missing_data, "notBreaching")
          dimensions = try(value.dimensions, {
            ClusterName = try(values.ecs_cluster_name, local.default_ecs_cluster_name)
            ServiceName = module.ecs_service["${service_name}"].name
          })
          ok_actions    = try(value.ok_actions, var.ecs_service_defaults.cw_alarms_defaults.ok_actions, [])
          alarm_actions = try(value.alarm_actions, var.ecs_service_defaults.cw_alarms_defaults.alarm_actions, [])
          alarms_tags   = merge(try(values.alarms_cw_overrides[alarm].alarms_tags, value.alarms_tags), { "alarm-service-name" = "${local.common_name}-${service_name}" })
        }
      ) if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, var.ecs_service_defaults.enable_alarms, false)
    }
  ]...)

  cw_alarms = merge(
    local.cw_alarms_default_tmp,
    local.cw_alarms_custom_tmp
  )


}

/*----------------------------------------------------------------------*/
/* SNS Alarms Variables                                                 */
/*----------------------------------------------------------------------*/

locals {
  enable_alarms_sns_default = anytrue([
    for _, alarm_value in local.cw_alarms :
    length(alarm_value.ok_actions) == 0 || length(alarm_value.alarm_actions) == 0
  ]) ? 1 : 0
}

data "aws_sns_topic" "alarms_sns_topic_name" {
  count = local.enable_alarms_sns_default
  name  = local.default_sns_topic_name
}

/*----------------------------------------------------------------------*/
/* CW Alarms Variables                                                  */
/*----------------------------------------------------------------------*/

resource "aws_cloudwatch_metric_alarm" "cw_alarms" {
  for_each = nonsensitive(local.cw_alarms)

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.alarm_description
  actions_enabled     = each.value.actions_enabled
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm
  threshold           = each.value.threshold
  period              = each.value.period
  unit                = each.value.unit
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  statistic           = each.value.statistic
  extended_statistic  = each.value.extended_statistic
  dimensions          = each.value.dimensions
  treat_missing_data  = each.value.treat_missing_data

  alarm_actions = length(each.value.alarm_actions) == 0 ? [data.aws_sns_topic.alarms_sns_topic_name[0].arn] : each.value.alarm_actions
  ok_actions    = length(each.value.ok_actions) == 0 ? [data.aws_sns_topic.alarms_sns_topic_name[0].arn] : each.value.ok_actions

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
            targets_sns         = try(values.alarms_eb_overrides[alarm].targets_sns, var.ecs_service_defaults.eb_alarms_defaults.targets_sns, [])
            schedule_expression = try(values.alarms_eb_overrides[alarm].schedule_expression, value.schedule_expression, null)
            force_destroy       = try(values.alarms_eb_overrides[alarm].force_destroy, value.force_destroy, false)
            role_arn            = try(values.alarms_eb_overrides[alarm].role_arn, value.role_arn, null)
            state               = try(values.alarms_eb_overrides[alarm].state, value.state, null)
          }
        )
      } if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, var.ecs_service_defaults.enable_alarms, false) && !contains(try(values.alarms_eb_disabled, var.ecs_service_defaults.eb_alarms_defaults.alarms_eb_disabled, []), alarm)
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
            targets_sns         = try(value.targets_sns, var.ecs_service_defaults.eb_alarms_defaults.targets_sns, [])
            schedule_expression = try(value.schedule_expression, null)
            force_destroy       = try(value.force_destroy, false)
            role_arn            = try(value.role_arn, null)
            state               = try(value.state, null)
          }
        )
      } if can(var.ecs_service_parameters) && var.ecs_service_parameters != {} && try(values.enable_alarms, var.ecs_service_defaults.enable_alarms, false)
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
