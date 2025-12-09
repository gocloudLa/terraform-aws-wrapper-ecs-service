# ENVIRONMENT
locals {

  app_container_definition_environment_tmp = [
    for service_key, service in var.ecs_service_parameters : {
      for container_key, container in service.containers :
      "${service_key}-${container_key}" => [
        for key, value in try(merge(try(container.map_environment, {}), try(local.map_environment_secrets_md5["${service_key}-${container_key}"], {})), []) :
        {
          "name"  = key
          "value" = value
        }
      ]
    }
  ]
  app_container_definition_environment = merge(flatten(local.app_container_definition_environment_tmp)...)
}

# SECRETS
locals {
  app_container_definition_secrets_tmp = [
    for service_key, service in var.ecs_service_parameters : {
      for container_key, container in service.containers :
      "${service_key}-${container_key}" => [
        for key, value in try(container.map_secrets, []) :
        {
          "name"      = key
          "valueFrom" = lookup(local.app_container_definition_secrets_map["${service_key}-${container_key}"], key)
        }
      ]
    }
  ]
  app_container_definition_secrets = merge(flatten(local.app_container_definition_secrets_tmp)...)
}


locals {
  app_container_definition_port_mappings_tmp = [
    for service_key, service in var.ecs_service_parameters : {
      for container_key, container in service.containers :
      "${service_key}-${container_key}" => [
        for port in try(container.ports, []) :
        {
          "containerPort" = try(port["container_port"], null)
          "hostPort"      = try(port["host_port"], port["container_port"])
          "protocol"      = try(port["protocol"], "tcp")
        }
      ]
    }
  ]

  app_container_definition_port_mappings = merge(flatten(local.app_container_definition_port_mappings_tmp)...)

  container_definitions_tmp = [
    for service_key, service_config in var.ecs_service_parameters : {
      "${service_key}" = {
        for container_key, container in try(service_config.containers, {}) :
        "${container_key}" => merge(
          container,
          { environment = local.app_container_definition_environment["${service_key}-${container_key}"] },
          { secrets = local.app_container_definition_secrets["${service_key}-${container_key}"] },
          { portMappings = local.app_container_definition_port_mappings["${service_key}-${container_key}"] },
          { mountPoints = local.app_container_definition_mount_points_efs["${service_key}"]["${container_key}"] },
          { image = try(module.ecr["${service_key}-${container_key}"].repository_url, container.image) },
          { readonlyRootFilesystem = try(container.readonlyRootFilesystem, false) },
          { user = try(container.user, null) }, # FIX, sin esto el modulo le pone user = 0 y rompen los contenedores bitnami/redis:7.0.10 y bitnami/openldap:2.6.4-debian-11-r4
          { essential = try(container.essential, true) },
          { restartPolicy = try(container.restartPolicy, {
            enabled = false
            # ignoredExitCodes     = [1]
            # restartAttemptPeriod = 60
          }) }
        )
      }
    }
  ]
  container_definitions = merge(flatten(local.container_definitions_tmp)...)
}
