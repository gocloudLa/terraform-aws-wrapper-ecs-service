variable "create" {
  type        = bool
  description = "Set to create resources."
  default     = true
}

variable "name" {
  type        = string
  description = "Name used for Image Builder resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to created resources."
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the build instance runs."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the build instance runs (needs outbound internet access)."
}

variable "repository_name" {
  type        = string
  description = "Name of the existing ECR repository that receives the image."
}

variable "repository_arn" {
  type        = string
  description = "ARN of the existing ECR repository that receives the image."
}

variable "repository_url" {
  type        = string
  description = "URL of the existing ECR repository that receives the image."
}

variable "parent_image" {
  type        = string
  description = "Base image of the build (e.g. public.ecr.aws/docker/library/nginx:1.27)."

  validation {
    condition     = length(var.parent_image) > 0
    error_message = "image_builder.parent_image is required."
  }
}

variable "commands" {
  type        = list(string)
  description = "Bash commands executed inside the build, in order."
  default     = []
}

variable "image_tag" {
  type        = string
  description = "Image tag and Image Builder version (x.y.z). A new build runs only when it changes."

  validation {
    condition     = can(regex("^[0-9]+[.][0-9]+[.][0-9]+$", var.image_tag))
    error_message = "image_builder.image_tag is required and must be a semantic version like 1.0.0."
  }
}

variable "files" {
  type = map(object({
    content = optional(string)
    source  = optional(string)
    mode    = optional(string, "0644")
  }))
  description = "Files written into the image. Key is the destination path; set content or source (local path)."
  default     = {}
}

variable "directories" {
  type        = map(string)
  description = "Local directories copied into the image. Key is the destination directory, value the local path."
  default     = {}
}

variable "entrypoint" {
  type        = list(string)
  description = "Dockerfile ENTRYPOINT (exec form). Empty keeps the parent image value."
  default     = []
}

variable "cmd" {
  type        = list(string)
  description = "Dockerfile CMD (exec form). Empty keeps the parent image value."
  default     = []
}

variable "dockerfile_template" {
  type        = string
  description = "Full Image Builder Dockerfile template. Overrides entrypoint and cmd."
  default     = null
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket that stages files copied into the image."
  default     = null
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type of the build instance (must match the target CPU architecture)."
  default     = "t3.medium"
}

variable "image_tests_enabled" {
  type        = bool
  description = "Run Image Builder tests on the build."
  default     = false
}
