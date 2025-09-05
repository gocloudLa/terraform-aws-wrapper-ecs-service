locals {
  task_definition_arn = replace(var.task_definition_arn, regex("[^:]*$", var.task_definition_arn), "*")
}