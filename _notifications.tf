/*----------------------------------------------------------------------*/
/* CloudWatch Log Nitifications                                         */
/*----------------------------------------------------------------------*/
locals {
  create_logs_notifications_tmp = [
    for service_key, service in var.ecs_service_parameters : {
      for container_key, container in service.containers :
      "${service_key}-${container_key}" => {
        "service_key"                 = service_key
        "container_key"               = container_key
        "filter_pattern"              = try(container.filter_pattern, null)
        "repository_name"             = try(container.repository_name, null)
        "repository_lifecycle_policy" = try(container.repository_lifecycle_policy, null)
      }
      if try(container.enable_logs_notifications, false) == true
    }
  ]
  create_logs_notifications = merge(flatten(local.create_logs_notifications_tmp)...)

}

data "aws_lambda_function" "notifications" {
  count         = local.create_logs_notifications == {} ? 0 : 1
  function_name = "${local.common_name_prefix}-notifications"
}

resource "aws_lambda_permission" "notifications" {
  for_each = local.create_logs_notifications

  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.notifications[0].function_name
  principal     = "logs.${data.aws_region.current.region}.amazonaws.com"
  source_arn    = format("%s:*", module.ecs_service[each.value.service_key].container_definitions[each.value.container_key].cloudwatch_log_group_arn)
}

resource "aws_cloudwatch_log_subscription_filter" "notifications" {
  for_each        = local.create_logs_notifications
  destination_arn = data.aws_lambda_function.notifications[0].arn
  filter_pattern  = each.value.filter_pattern != null ? each.value.filter_pattern : "{ $.level != \"INFO\" && $.level != \"DEBUG\" }"
  log_group_name  = module.ecs_service[each.value.service_key].container_definitions[each.value.container_key].cloudwatch_log_group_name
  name            = "notifications"
  # depends_on      = [aws_lambda_permission.notifications[each.key]]
}