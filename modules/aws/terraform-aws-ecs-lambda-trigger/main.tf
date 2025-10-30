module "ecs_lambda_trigger_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.1.2"

  create_function = var.create
  function_name   = "trigger_${var.eventbridge_name}"
  description     = "Lambda function that runs a task of ${var.eventbridge_name} ecs scheduled task."
  handler         = "app.handler"
  runtime         = "python3.9"
  timeout         = 10

  source_path = "${path.module}/lambdas/ecs_lambda_trigger"

  attach_network_policy = false

  environment_variables = { "EVENTBRIDGE_NAME" : var.eventbridge_name }

  attach_policy_statements = true
  policy_statements = {
    event = {
      effect    = "Allow",
      actions   = ["events:Describe*", "events:List*"],
      resources = ["${var.eventbridge_arn}"]
    },
    ecs_run = {
      effect    = "Allow",
      actions   = ["ecs:RunTask"],
      resources = ["${local.task_definition_arn}"]
    },
    ecs_tag = {
      effect  = "Allow",
      actions = ["ecs:TagResource"],
      condition = {
        stringequals_condition = {
          test     = "StringEquals"
          variable = "ecs:CreateAction"
          values   = ["RunTask"]
        }
      }
      resources = ["*"]
    },
    iam = {
      effect  = "Allow",
      actions = ["iam:PassRole"],
      condition = {
        stringlike_condition = {
          test     = "StringLike"
          variable = "iam:PassedToService"
          values   = ["ecs-tasks.amazonaws.com"]
        }
      }
      resources = ["*"]
    }
  }
  tags = var.tags
}