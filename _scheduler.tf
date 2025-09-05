/*----------------------------------------------------------------------*/
/* ECS Scheduler                                                        */
/*----------------------------------------------------------------------*/

locals {
  create_schedule = {
    for service_key, service in var.ecs_service_parameters :
    "${service_key}" => {
      "service_key"                = service_key
      "name"                       = "${local.common_name}-${service_key}"
      "schedule_expression"        = service.schedule_expression
      "aws_cloudwatch_event_input" = try(service.aws_cloudwatch_event_input, null)
      "create_ecs_lambda_trigger"  = service.create_ecs_lambda_trigger
    }
    if try(service.ecs_execution_type, null) == "schedule"

  }
}

resource "aws_cloudwatch_event_rule" "default" {
  for_each = local.create_schedule

  name                = each.value.name
  description         = ""
  schedule_expression = each.value.schedule_expression
}

resource "aws_cloudwatch_event_target" "default" {
  for_each = local.create_schedule

  target_id = each.value.name
  arn       = data.aws_ecs_cluster.this[each.key].id
  rule      = aws_cloudwatch_event_rule.default[each.key].name
  role_arn  = aws_iam_role.ecs_events[each.key].arn
  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1 # Ver si tomar otro valor aca
    task_definition_arn = module.ecs_service[each.key].task_definition_arn

    network_configuration {
      subnets          = data.aws_subnets.this[each.key].ids
      security_groups  = [module.ecs_service[each.key].security_group_id]
      assign_public_ip = false
    }
  }

  input = each.value.aws_cloudwatch_event_input
  # input = <<DOC
  # {
  # "containerOverrides": [
  #   {
  #     "name": "name-of-container-to-override",
  #     "command": ["bin/console", "scheduled-task"]
  #   }
  # ]
  # }
  # DOC
}

resource "aws_iam_role" "ecs_events" {
  for_each = local.create_schedule

  name               = "${each.value.name}-ecs-events"
  assume_role_policy = data.aws_iam_policy_document.ecs_events_assume_role_policy.json
  path               = "/"
  description        = ""
  tags               = local.common_tags
}

data "aws_iam_policy_document" "ecs_events_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
resource "aws_iam_policy" "ecs_events" {
  for_each = local.create_schedule

  name        = "${each.value.name}-ecs-events"
  policy      = data.aws_iam_policy.ecs_events.policy
  path        = "/"
  description = ""
}

data "aws_iam_policy" "ecs_events" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "ecs_events" {
  for_each = local.create_schedule

  role       = aws_iam_role.ecs_events[each.key].name
  policy_arn = aws_iam_policy.ecs_events[each.key].arn
}


module "ecs_lambda_trigger" {
  source = "./modules/aws/terraform-aws-ecs-lambda-trigger"

  for_each = local.create_schedule

  create = try(each.value.create_ecs_lambda_trigger, false)

  eventbridge_name    = aws_cloudwatch_event_rule.default[each.key].name
  eventbridge_arn     = aws_cloudwatch_event_rule.default[each.key].arn
  task_definition_arn = module.ecs_service[each.key].task_definition_arn

  tags = local.common_tags
}