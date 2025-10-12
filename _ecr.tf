locals {
  create_ecr_repository_tmp = [
    for service_key, service in var.ecs_service_parameters : {
      for container_key, container in service.containers :
      "${service_key}-${container_key}" => {
        "service_key"                                      = service_key
        "container_key"                                    = container_key
        "repository_name"                                  = try(container.repository_name, null)
        "repository_lifecycle_policy"                      = try(container.repository_lifecycle_policy, null)
        "repository_image_tag_mutability"                  = try(container.repository_image_tag_mutability, "MUTABLE")
        "repository_image_tag_mutability_exclusion_filter" = try(container.repository_image_tag_mutability_exclusion_filter, null)
        "repository_read_access_arns"                      = try(container.repository_read_access_arns, [])
        "repository_read_write_access_arns"                = try(container.repository_read_write_access_arns, [])
        # Registry Scanning Configuration
        "manage_registry_scanning_configuration"          = try(container.manage_registry_scanning_configuration, false)
        "registry_scan_type"                              = try(container.registry_scan_type, "ENHANCED")
        "registry_scan_rules"                             = try(container.registry_scan_rules, null)
        # Registry Replication Configuration
        "create_registry_replication_configuration"       = try(container.create_registry_replication_configuration, false)
        "registry_replication_rules"                       = try(container.registry_replication_rules, null)
      }
      if(try(container.create_ecr_repository, true) == true && !can(container.image))
    }
  ]
  create_ecr_repository = merge(flatten(local.create_ecr_repository_tmp)...)
}

module "ecr" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "3.1.0"
  for_each = local.create_ecr_repository

  repository_name = lower(each.value.repository_name != null ? each.value.repository_name : "${local.common_name}-${each.value.service_key}-${each.value.container_key}")

  create_lifecycle_policy = true
  repository_lifecycle_policy = each.value.repository_lifecycle_policy != null ? each.value.repository_lifecycle_policy : jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  repository_read_access_arns                      = each.value.repository_read_access_arns
  repository_read_write_access_arns                = each.value.repository_read_write_access_arns
  repository_image_tag_mutability                  = each.value.repository_image_tag_mutability
  repository_image_tag_mutability_exclusion_filter = each.value.repository_image_tag_mutability_exclusion_filter
  repository_force_delete                          = true

  # Registry Scanning Configuration
  manage_registry_scanning_configuration = each.value.manage_registry_scanning_configuration
  registry_scan_type                     = each.value.registry_scan_type
  registry_scan_rules                    = each.value.registry_scan_rules

  # Registry Replication Configuration
  create_registry_replication_configuration = each.value.create_registry_replication_configuration
  registry_replication_rules                = each.value.registry_replication_rules

  tags = local.common_tags
}

output "ecr" {
  value = module.ecr
}