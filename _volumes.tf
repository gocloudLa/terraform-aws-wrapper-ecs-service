locals {
  # ARMO OBJETO PARA CREAR ecs_task_volume
  ecs_task_volume_efs_tmp = [
    for service_name, service_config in var.ecs_service_parameters :
    [
      for volume_key, volume_values in can(service_config.ecs_task_volume_efs) ? service_config.ecs_task_volume_efs : {} :

      {
        "${service_name}-${volume_key}" = {
          "efs_name"   = volume_values.efs_name
          "name"       = service_name
          "volume_key" = volume_key
        }
      }

    ]
  ]
  ecs_task_volume_efs = merge(flatten(local.ecs_task_volume_efs_tmp)...)
}
# output "a_local_ecs_task_volume_efs" {
#   value = local.ecs_task_volume_efs
# }
# RES
# locals {
#   a_local_ecs_task_volume_efs = {
#     ExEfs-example = {
#       efs_name   = "dmc-prd-example-00"
#       name       = "ExEfs"
#       volume_key = "example"
#     }
#     ExEfs-root    = {
#       efs_name   = "dmc-prd-example-00"
#       name       = "ExEfs"
#       volume_key = "root"
#     }
#   }
# }

data "aws_efs_file_system" "this" {
  for_each = local.ecs_task_volume_efs
  tags = {
    Name = each.value.efs_name
  }
}
# output "b_data_aws_efs_file_system_this" {
#   value = data.aws_efs_file_system.this
# }
# RES
# locals {
#   b_data_aws_efs_file_system_this = {
#     ExEfs-example = {
#       arn                             = "arn:aws:elasticfilesystem:us-east-1:565219270600:file-system/fs-0ec342fcd31a68eeb"
#       availability_zone_id            = ""
#       availability_zone_name          = ""
#       creation_token                  = "terraform-20240208215827433500000001"
#       dns_name                        = "fs-0ec342fcd31a68eeb.efs.us-east-1.amazonaws.com"
#       encrypted                       = true
#       file_system_id                  = "fs-0ec342fcd31a68eeb"
#       id                              = "fs-0ec342fcd31a68eeb"
#       kms_key_id                      = "arn:aws:kms:us-east-1:565219270600:key/0bc4852d-c811-4142-8db9-46da75c9f1b4"
#       lifecycle_policy                = []
#       name                            = "dmc-prd-example-00"
#       performance_mode                = "generalPurpose"
#       provisioned_throughput_in_mibps = 0
#       size_in_bytes                   = 6144
#       tags                            = {
#         Name        = "dmc-prd-example-00"
#         company     = "dmc"
#         created-by  = "GoCloud.la"
#         environment = "Production"
#         project     = "example"
#         provisioner = "terraform"
#       }
#       throughput_mode                 = "bursting"
#     }
#     ExEfs-root    = {
#       arn                             = "arn:aws:elasticfilesystem:us-east-1:565219270600:file-system/fs-0ec342fcd31a68eeb"
#       availability_zone_id            = ""
#       availability_zone_name          = ""
#       creation_token                  = "terraform-20240208215827433500000001"
#       dns_name                        = "fs-0ec342fcd31a68eeb.efs.us-east-1.amazonaws.com"
#       encrypted                       = true
#       file_system_id                  = "fs-0ec342fcd31a68eeb"
#       id                              = "fs-0ec342fcd31a68eeb"
#       kms_key_id                      = "arn:aws:kms:us-east-1:565219270600:key/0bc4852d-c811-4142-8db9-46da75c9f1b4"
#       lifecycle_policy                = []
#       name                            = "dmc-prd-example-00"
#       performance_mode                = "generalPurpose"
#       provisioned_throughput_in_mibps = 0
#       size_in_bytes                   = 6144
#       tags                            = {
#         Name        = "dmc-prd-example-00"
#         company     = "dmc"
#         created-by  = "GoCloud.la"
#         environment = "Production"
#         project     = "example"
#         provisioner = "terraform"
#       }
#       throughput_mode                 = "bursting"
#     }
#   }
# }

data "aws_efs_access_points" "this" {
  for_each       = local.ecs_task_volume_efs
  file_system_id = data.aws_efs_file_system.this[each.key].file_system_id
}
# output "c_data_aws_efs_access_points_this" {
#   value = data.aws_efs_access_points.this
# }
# RES
# locals {
#   c_data_aws_efs_access_points_this = {
#     ExEfs-example = {
#       arns           = [
#           "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0cf598f67f3fdc7e3",
#           "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0e7f43ce387f3cb01",
#         ]
#       file_system_id = "fs-0ec342fcd31a68eeb"
#       id             = "fs-0ec342fcd31a68eeb"
#       ids            = [
#           "fsap-0cf598f67f3fdc7e3",
#           "fsap-0e7f43ce387f3cb01",
#         ]
#     }
#     ExEfs-root    = {
#       arns           = [
#         "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0cf598f67f3fdc7e3",
#         "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0e7f43ce387f3cb01",
#       ]
#       file_system_id = "fs-0ec342fcd31a68eeb"
#       id             = "fs-0ec342fcd31a68eeb"
#       ids            = [
#         "fsap-0cf598f67f3fdc7e3",
#         "fsap-0e7f43ce387f3cb01",
#       ]
#     }
#   }
# }

locals {
  aws_efs_access_points_tmp = [
    for key, value in local.ecs_task_volume_efs :
    {
      for id in data.aws_efs_access_points.this[key].ids : "${key}-${id}" => {
        "object_key"       = key
        "access_point_id"  = id
        "key"              = key
        "ecs_service_name" = value.name
      }
    }
  ]
  aws_efs_access_points = merge(flatten(local.aws_efs_access_points_tmp)...)
}
# output "d_local_aws_efs_access_points" {
#   value = local.aws_efs_access_points
# }
# RES
# locals {
#   d_local_aws_efs_access_points = {
#     ExEfs-example-fsap-0cf598f67f3fdc7e3 = {
#       access_point_id  = "fsap-0cf598f67f3fdc7e3"
#       ecs_service_name = "ExEfs"
#       key              = "ExEfs-example"
#       object_key       = "ExEfs-example"
#     }
#     ExEfs-example-fsap-0e7f43ce387f3cb01 = {
#       access_point_id  = "fsap-0e7f43ce387f3cb01"
#       ecs_service_name = "ExEfs"
#       key              = "ExEfs-example"
#       object_key       = "ExEfs-example"
#     }
#     ExEfs-root-fsap-0cf598f67f3fdc7e3    = {
#       access_point_id  = "fsap-0cf598f67f3fdc7e3"
#       ecs_service_name = "ExEfs"
#       key              = "ExEfs-root"
#       object_key       = "ExEfs-root"
#     }
#     ExEfs-root-fsap-0e7f43ce387f3cb01    = {
#       access_point_id  = "fsap-0e7f43ce387f3cb01"
#       ecs_service_name = "ExEfs"
#       key              = "ExEfs-root"
#       object_key       = "ExEfs-root"
#     }
#   }
# }

data "aws_efs_access_point" "this" {
  for_each        = local.aws_efs_access_points
  access_point_id = each.value.access_point_id
}
# output "e_data_aws_efs_access_point_this" {
#   value = data.aws_efs_access_point.this
# }
# RES
# locals {
#   e_data_aws_efs_access_point_this =  {
#     ExEfs-example-fsap-0cf598f67f3fdc7e3 = {
#       access_point_id = "fsap-0cf598f67f3fdc7e3"
#       arn             = "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0cf598f67f3fdc7e3"
#       file_system_arn = "arn:aws:elasticfilesystem:us-east-1:565219270600:file-system/fs-0ec342fcd31a68eeb"
#       file_system_id  = "fs-0ec342fcd31a68eeb"
#       id              = "fsap-0cf598f67f3fdc7e3"
#       owner_id        = "565219270600"
#       posix_user      = []
#       tags            = {
#         Name        = "root"
#         company     = "dmc"
#         created-by  = "GoCloud.la"
#         environment = "Production"
#         project     = "example"
#         provisioner = "terraform"
#       }
#     }
#     ExEfs-example-fsap-0e7f43ce387f3cb01 = {
#       access_point_id = "fsap-0e7f43ce387f3cb01"
#       arn             = "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0e7f43ce387f3cb01"
#       file_system_arn = "arn:aws:elasticfilesystem:us-east-1:565219270600:file-system/fs-0ec342fcd31a68eeb"
#       file_system_id  = "fs-0ec342fcd31a68eeb"
#       id              = "fsap-0e7f43ce387f3cb01"
#       owner_id        = "565219270600"
#       posix_user      = []
#       tags            = {
#         Name        = "example"
#         company     = "dmc"
#         created-by  = "GoCloud.la"
#         environment = "Production"
#         project     = "example"
#         provisioner = "terraform"
#       }
#     }
#     ExEfs-root-fsap-0cf598f67f3fdc7e3    = {
#       access_point_id = "fsap-0cf598f67f3fdc7e3"
#       arn             = "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0cf598f67f3fdc7e3"
#       file_system_arn = "arn:aws:elasticfilesystem:us-east-1:565219270600:file-system/fs-0ec342fcd31a68eeb"
#       file_system_id  = "fs-0ec342fcd31a68eeb"
#       id              = "fsap-0cf598f67f3fdc7e3"
#       owner_id        = "565219270600"
#       posix_user      = []
#       tags            = {
#         Name        = "root"
#         company     = "dmc"
#         created-by  = "GoCloud.la"
#         environment = "Production"
#         project     = "example"
#         provisioner = "terraform"
#       }
#     }
#     ExEfs-root-fsap-0e7f43ce387f3cb01    = {
#       access_point_id = "fsap-0e7f43ce387f3cb01"
#       arn             = "arn:aws:elasticfilesystem:us-east-1:565219270600:access-point/fsap-0e7f43ce387f3cb01"
#       file_system_arn = "arn:aws:elasticfilesystem:us-east-1:565219270600:file-system/fs-0ec342fcd31a68eeb"
#       file_system_id  = "fs-0ec342fcd31a68eeb"
#       id              = "fsap-0e7f43ce387f3cb01"
#       owner_id        = "565219270600"
#       posix_user      = []
#       tags            = {
#         Name        = "example"
#         company     = "dmc"
#         created-by  = "GoCloud.la"
#         environment = "Production"
#         project     = "example"
#         provisioner = "terraform"
#       }
#     }
#   }
# }

locals {
  aws_efs_access_point_tmp = flatten([
    for k, v in values(data.aws_efs_access_point.this) : [
      {
        "${v.file_system_id}-${v.tags.Name}" = {
          access_point_id = v.access_point_id
        }
      }
    ]
  ])
  aws_efs_access_point = merge(flatten(local.aws_efs_access_point_tmp)...)
}
# output "f_local_aws_efs_access_point" {
#   value = local.aws_efs_access_point
# }
# RES
# locals {
#   f_local_aws_efs_access_point = {
#     fs-0ec342fcd31a68eeb-example = {
#       access_point_id = "fsap-0e7f43ce387f3cb01"
#     }
#     fs-0ec342fcd31a68eeb-root    = {
#       access_point_id = "fsap-0cf598f67f3fdc7e3"
#     }
#   }
# }

locals {
  container_module_ecs_task_volume_efs = {
    for service_name, service_config in var.ecs_service_parameters :
    service_name => {
      for access_point, volume_config in try(service_config.ecs_task_volume_efs, {}) :
      access_point => {
        name = access_point
        efs_volume_configuration = {
          file_system_id     = data.aws_efs_access_points.this["${service_name}-${access_point}"].file_system_id
          transit_encryption = try(volume_config.transit_encryption, "ENABLED")
          authorization_config = {
            access_point_id = local.aws_efs_access_point["${data.aws_efs_access_points.this["${service_name}-${access_point}"].file_system_id}-${volume_config.access_point}"].access_point_id
          }
        }
      }
    }
  }
}
locals {
  app_container_definition_mount_points_efs = {
    for service_key, service_config in var.ecs_service_parameters :
    service_key => {
      for container_key, container in try(service_config.containers, {}) :
      container_key => [
        for mount_points_efs_key, mount_points_efs_value in try(container.mount_points_efs, {}) :
        {
          "sourceVolume"  = mount_points_efs_key
          "containerPath" = mount_points_efs_value.container_path
          "readOnly"      = mount_points_efs_value.read_only
        }
      ]
    }
  }
}

# output "g_local_container_module_ecs_task_volume_efs" {
#   value = local.container_module_ecs_task_volume_efs
# }

# output "h_local_app_container_definition_mount_points_efs" {
#   value = local.app_container_definition_mount_points_efs
# }