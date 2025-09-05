variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)

}

variable "create" {
  description = "(Required)"
  type        = bool
}

variable "eventbridge_name" {
  description = "(Required) Name of EventBridge Rule"
  type        = string
}

variable "eventbridge_arn" {
  description = "(Required) ARN of EventBridge Rule"
  type        = string
}

variable "task_definition_arn" {
  description = "(Required) ARN of Task definition"
  type        = string
}
