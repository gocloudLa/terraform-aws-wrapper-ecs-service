locals {
  # ARMO OBJETO PARA CREAR EL SECRET
  app_container_definition_secrets_create_tmp = [
    for service_name, service_config in var.ecs_service_parameters :
    [
      for container_name, container_config in service_config.containers :
      [
        for secret_key, secret_value in can(container_config.map_secrets) ? container_config.map_secrets : {} :
        {
          "${service_name}-${container_name}-${secret_key}" = {
            name  = secret_key
            value = secret_value
          }
        }
      ]
    ]
  ]
  app_container_definition_secrets_create = merge(flatten(local.app_container_definition_secrets_create_tmp)...)

}

module "ssm_parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "2.0.0"

  for_each = local.app_container_definition_secrets_create

  name            = can(each.value.name) ? "${local.common_name}-${each.key}" : null
  value           = try(each.value.value, null)
  values          = try(each.value.values, [])
  type            = try(each.value.type, null)
  secure_type     = try(each.value.secure_type, true)
  description     = try(each.value.description, null)
  tier            = try(each.value.tier, null)
  key_id          = try(each.value.key_id, null)
  allowed_pattern = try(each.value.allowed_pattern, null)
  data_type       = try(each.value.data_type, null)
  overwrite       = true

  tags = local.common_tags
}

# ARMO OBJETO PARA PASAR TASKDEFINITION
locals {
  app_container_definition_secrets_map_tmp = [
    for service_key, service in var.ecs_service_parameters : {
      for container_key, container in service.containers :
      "${service_key}-${container_key}" => {
        for secret_key, secret_value in try(container.map_secrets, {}) :
        secret_key => module.ssm_parameter["${service_key}-${container_key}-${secret_key}"].ssm_parameter_arn
      }
    }
  ]

  app_container_definition_secrets_map = merge(flatten(local.app_container_definition_secrets_map_tmp)...)
}

# ARMO OBJETO CON MD5 DE SECRETOS PARA INYECTAR COMO VARIABLE DE ENTORNO
locals {
  map_environment_secrets_md5 = length(local.app_container_definition_secrets_create) > 0 ? {
    "SECRETS_MD5" = md5(jsonencode(local.app_container_definition_secrets_create))
  } : {}

}
