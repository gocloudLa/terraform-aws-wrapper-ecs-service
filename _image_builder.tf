locals {
  image_builders_tmp = [
    for service_key, service in var.ecs_service_parameters : {
      for container_key, container in try(service.containers, {}) :
      "${service_key}-${container_key}" => {
        "service_key"   = service_key
        "container_key" = container_key
        "config"        = container.image_builder
        "arm"           = upper(try(service.runtime_platform.cpu_architecture, var.ecs_service_defaults.runtime_platform.cpu_architecture, "X86_64")) == "ARM64"
        "has_image"     = can(container.image)
      }
      if can(container.image_builder) && try(container.image_builder.enable, true) == true
    }
  ]
  image_builders = merge(flatten(local.image_builders_tmp)...)
}

# Fails the plan when the container cannot receive a built image.
resource "terraform_data" "image_builder_checks" {
  for_each = local.image_builders

  lifecycle {
    precondition {
      condition     = !each.value.has_image
      error_message = "Container ${each.key}: `image` and `image_builder` are mutually exclusive."
    }
    precondition {
      condition     = contains(keys(local.create_ecr_repository), each.key)
      error_message = "Container ${each.key}: `image_builder` requires the ECR repository (create_ecr_repository = true)."
    }
  }
}

module "ecs_image_builder" {
  source = "./modules/aws/terraform-aws-ecs-image-builder"

  for_each = local.image_builders

  name      = "${local.common_name}-${each.key}"
  vpc_id    = data.aws_vpc.this[each.value.service_key].id
  subnet_id = sort(tolist(data.aws_subnets.this[each.value.service_key].ids))[0]

  repository_name = module.ecr[each.key].repository_name
  repository_url  = module.ecr[each.key].repository_url

  image_tag           = try(each.value.config.image_tag, "")
  parent_image        = try(each.value.config.parent_image, "")
  commands            = try(each.value.config.commands, [])
  files               = try(each.value.config.files, {})
  directories         = try(each.value.config.directories, {})
  entrypoint          = try(each.value.config.entrypoint, [])
  cmd                 = try(each.value.config.cmd, [])
  dockerfile_template = try(each.value.config.dockerfile_template, null)
  bucket_name         = try(each.value.config.bucket_name, lower("${local.common_name}-${each.value.service_key}-${each.value.container_key}-ib-content"))
  instance_type       = try(each.value.config.instance_type, each.value.arm ? "t4g.medium" : "t3.medium")
  image_tests_enabled = try(each.value.config.image_tests_enabled, false)

  tags = merge(local.common_tags, { workload = each.value.service_key }, try(each.value.config.tags, null))

  depends_on = [terraform_data.image_builder_checks]
}
