module "wrapper_ecs_service" {

  source = "../../"

  /*----------------------------------------------------------------------*/
  /* General Variables                                                    */
  /*----------------------------------------------------------------------*/

  metadata = local.metadata

  /*----------------------------------------------------------------------*/
  /* ECS Service Parameters                                               */
  /*----------------------------------------------------------------------*/

  ecs_service_parameters = {
    ExSimple = {
      # ecs_cluster_name                       = "dmc-prd-core-00"  # (Optional) Auto Discovery
      # vpc_name                               = "dmc-prd"          # (Optional) Auto Discovery
      # subnet_name                            = "dmc-prd-private*" # (Optional) Auto Discovery

      enable_autoscaling     = false
      enable_execute_command = true

      # ALARMS CONFIGURATION
      enable_alarms = false # Default: false
      capacity_provider_strategy = {
        fargate_spot = {
          base              = null
          capacity_provider = "FARGATE_SPOT"
          weight            = 50
        }
      }

      # Policies used by tasks from the developed code
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      }
      tasks_iam_role_statements = [
        {
          actions   = ["s3:List*"]
          resources = ["arn:aws:s3:::*"]
        }
      ]
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []

      ecs_task_volume = []

      containers = {
        app = {
          cloudwatch_log_group_retention_in_days = 7
          readonlyRootFilesystem                 = false
          # if you want add ecr access to another accouunt
          #repository_read_access_arns            = [ "arn:aws:iam::account-id:root","arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" ]
          #repository_image_tag_mutability        = "IMMUTABLE"
          ports = {
            "port1" = {
              container_port = 80
              #host_port      = 80    # Default: container_port
              #protocol       = "tcp" # Default: tcp
              #cidr_blocks    = [""]  # Default: [vpc_cidr]
              load_balancer = {
                "alb1" = {
                  alb_name = "dmc-prd-example-ExExternal01"
                  #    #if you want set a target group custom name
                  #    target_group_custom_name = "${local.common_name}-ExSimpleEcr"
                  listener_rules = {
                    "rule1" = {
                      #        # priority          = 10
                      #        # actions = [{ type = "forward" }] # Default Action
                      conditions = [
                        {
                          host_headers = ["ExSimpleEcr.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
          map_environment = {
            "ENV_1" = "env_value_1"
            "ENV_1" = "env_value_2"
          }
          map_secrets = {
            "SECRET_ENV_1" = "secret_env_value_1"
            "SECRET_ENV_2" = "secret_env_value_2"
          }
          mount_points = []
        }
      }
    }

    ExDouble = {
      # ecs_cluster_name                       = "dmc-prd-core-00"
      # vpc_name                               = "dmc-prd"
      # subnet_name                            = "dmc-prd-private*"
      enable_autoscaling = false

      enable_execute_command = true

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []

      containers = {
        app = {
          map_environment = {}
          map_secrets     = {}
          mount_points    = []
          ports = {
            "port1" = {
              container_port = 80
              load_balancer = {
                "alb1" = {
                  alb_name = "dmc-prd-example-ExExternal01"
                  listener_rules = {
                    "rule1" = {
                      # priority          = 10
                      # actions = [{ type = "forward" }] # Default Action 
                      conditions = [
                        {
                          host_headers = ["ExDoubleEcr.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
        }
        web = {
          map_environment = {}
          map_secrets     = {}
          mount_points    = []
          ports = {
            "port1" = {
              container_port = 81
            }
          }
        }
      }
    }

    ExPubEcr = {
      # ecs_cluster_name                       = "dmc-prd-core-00"
      # vpc_name                               = "dmc-prd"
      # subnet_name                            = "dmc-prd-private*"
      enable_autoscaling = false

      enable_execute_command = true

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []


      ecs_task_volume = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/nginx:latest"
          create_ecr_repository = false
          map_environment       = {}
          map_secrets           = {}
          mount_points          = []
          ports = {
            "port1" = {
              container_port = 80
              load_balancer = {
                "alb1" = {
                  alb_name = "dmc-prd-example-ExExternal01"
                  listener_rules = {
                    "rule1" = {
                      # priority          = 10
                      # actions = [{ type = "forward" }] # Default Action
                      conditions = [
                        {
                          host_headers = ["ExPublicEcr.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    ExScheduler = {
      # ecs_cluster_name               = "dmc-prd-core-00"
      # vpc_name                       = "dmc-prd"
      # subnet_name                    = "dmc-prd-private*"
      enable_autoscaling        = false
      ecs_execution_type        = "schedule"
      schedule_expression       = "cron(0/5 * * * ? *)" # Run every 5 minutes
      create_ecs_lambda_trigger = true

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/alpine"
          create_ecr_repository = false
          command               = ["env"]
        }
      }
    }

    ExEfs = {
      # ecs_cluster_name               = "dmc-prd-core-00"
      # vpc_name                       = "dmc-prd"
      # subnet_name                    = "dmc-prd-private*"
      enable_autoscaling = false

      enable_execute_command = true

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []

      ecs_task_volume_efs = {
        root = {
          efs_name     = "dmc-prd-example-00"
          access_point = "root"
        }
        example = {
          efs_name     = "dmc-prd-example-00"
          access_point = "example"
        }
      }



      # https://dmc-prd-core-external-00.democorp.cloud/filebrowser/files/
      # admin / admin (default credentials)
      containers = {
        app = {
          image                 = "hurlenko/filebrowser:latest"
          create_ecr_repository = false

          map_environment = {
            "FB_BASEURL" = "/filebrowser"
          }
          map_secrets = {}
          mount_points_efs = {
            root = {
              container_path = "/data/root"
              read_only      = true
            }
            example = {
              container_path = "/data/example"
              read_only      = false
            }
          }
          ports = {
            "port1" = {
              container_port = 8080
              load_balancer = {
                "alb1" = {
                  alb_name = "dmc-prd-example-ExExternal01"
                  listener_rules = {
                    "rule1" = {
                      # priority          = 10
                      # actions = [{ type = "forward" }] # Default Action
                      conditions = [
                        {
                          path_patterns = [
                            "/filebrowser",
                            "/filebrowser/*",
                          ]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    ExAlb = {
      # ecs_cluster_name                       = "dmc-prd-core-00"
      # vpc_name                               = "dmc-prd"
      # subnet_name                            = "dmc-prd-private*"
      enable_autoscaling = false

      enable_execute_command = true

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []


      ecs_task_volume = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/nginx:latest"
          create_ecr_repository = false
          ports = {
            "port1" = {
              container_port = 80
              # host_port      = 80    # Default: container_port
              # protocol       = "tcp" # Default: tcp
              # cidr_blocks    = [""]  # Default: [vpc_cidr]
              load_balancer = {
                "alb1" = {
                  alb_name = "dmc-prd-example-ExExternal01"
                  # target_group_custom_name = "custom-name" # Default: "${local.common_name}-${service_name}-${port_values.container_port}-${alb_key}"
                  alb_listener_port    = 443
                  deregistration_delay = 300
                  slow_start           = 30
                  health_check = {
                    # # Default Values
                    # path                = "/"
                    # port                = "traffic-port"
                    # protocol            = "HTTP"
                    # matcher             = 200
                    # interval            = 30
                    # timeout             = 5
                    # healthy_threshold   = 3
                    # unhealthy_threshold = 3
                  }
                  listener_rules = {
                    "rule1" = {
                      # priority          = 10
                      # actions = [{ type = "forward" }] # Default Action
                      conditions = [
                        {
                          host_headers = ["ExAlb.${local.zone_public}"]
                        }
                      ]
                    }
                    # REDIRECT
                    # curl -v -H 'Host: ExAlb-redirect.democorp.cloud' https://{balancer_domain}
                    "rule2" = {
                      # priority          = 10
                      actions = [{
                        type        = "redirect"
                        host        = "google.com"
                        port        = 443
                        status_code = "HTTP_301"
                      }]
                      conditions = [
                        {
                          host_headers = ["ExAlb-redirect.${local.zone_public}"]
                        }
                      ]
                    }
                    # FIXED RESPONSE
                    # curl -v -H 'Host: ExAlb-fixed.democorp.cloud' https://{balancer_domain}
                    "rule3" = {
                      # priority          = 10
                      actions = [{
                        type         = "fixed-response"
                        message_body = "Unauthorized - Fixed Response"
                        status_code  = 401
                        content_type = "text/plain"
                      }]
                      conditions = [
                        {
                          host_headers = ["ExAlb-fixed.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
          map_environment = {}
          map_secrets     = {}
          mount_points    = []
        }
      }
    }

    AlbMulti = {
      # ecs_cluster_name                       = "dmc-prd-core-00"
      # vpc_name                               = "dmc-prd"
      # subnet_name                            = "dmc-prd-private*"
      enable_autoscaling = false

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []

      ecs_task_volume = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/nginx:latest"
          create_ecr_repository = false
          ports = {
            "port1" = {
              container_port = 80
              # protocol       = "tcp" # Default: tcp
              # cidr_blocks    = [""]  # Default: [vpc_cidr]
              load_balancer = {
                "alb1" = {
                  alb_name          = "dmc-prd-example-ExExternal01"
                  alb_listener_port = 443
                  dns_records = {
                    "AlbMulti1" = {
                      zone_name    = "${local.zone_public}"
                      private_zone = false
                    }
                  }
                  listener_rules = {
                    "rule1" = {
                      conditions = [
                        {
                          host_headers = ["AlbMulti1.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
                "alb2" = {
                  alb_name          = "dmc-prd-example-ExExternal01" # Can be another ALB / Internal for example
                  alb_listener_port = 443
                  dns_records = {
                    "AlbMulti2" = {
                      zone_name    = "${local.zone_public}"
                      private_zone = false
                    }
                  }
                  listener_rules = {
                    "rule1" = {
                      conditions = [
                        {
                          host_headers = ["AlbMulti2.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
          map_environment = {}
          map_secrets     = {}
          mount_points    = []
        }
      }
    }

    ExDns = {
      # ecs_cluster_name                       = "dmc-prd-core-00"
      # vpc_name                               = "dmc-prd"
      # subnet_name                            = "dmc-prd-private*"
      enable_autoscaling = false

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []

      ecs_task_volume = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/nginx:latest"
          create_ecr_repository = false
          ports = {
            "port1" = {
              container_port = 80
              # protocol       = "tcp" # Default: tcp
              # cidr_blocks    = [""]  # Default: [vpc_cidr]
              load_balancer = {
                "alb1" = {
                  alb_name          = "dmc-prd-example-ExExternal01"
                  alb_listener_port = 443
                  dns_records = {
                    "ExDns" = {
                      zone_name    = "${local.zone_public}"
                      private_zone = false
                    }
                  }
                  listener_rules = {
                    "rule1" = {
                      conditions = [
                        {
                          host_headers = ["ExDns.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
          map_environment = {}
          map_secrets     = {}
          mount_points    = []
        }
      }
    }

    ExNotifications = {
      # ecs_cluster_name                       = "dmc-prd-core-00"
      # vpc_name                               = "dmc-prd"
      # subnet_name                            = "dmc-prd-private*"
      enable_autoscaling = false

      enable_execute_command = true

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []


      ecs_task_volume = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/nginx:latest"
          create_ecr_repository = false
          map_environment       = {}
          map_secrets           = {}
          mount_points          = []

          enable_logs_notifications = true
          filter_pattern            = "\" \"" # Match everything
          # Default (filter_pattern): "{ $.level != \"INFO\" && $.level != \"DEBUG\" }" 
          # JSON Parser, Level not equal INFO or DEBUG
        }
      }
    }

    ExCloudmap = {
      # ecs_cluster_name   = "dmc-prd-core-00"
      # vpc_name           = "dmc-prd"
      # subnet_name        = "dmc-prd-private*"
      enable_autoscaling = false

      enable_execute_command = true

      # Policies used by tasks from the developed code
      tasks_iam_role_policies   = {}
      tasks_iam_role_statements = []
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []


      ecs_task_volume = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/nginx:latest"
          create_ecr_repository = false
          map_environment       = {}
          map_secrets           = {}
          mount_points          = []
          ports = {
            "port1" = {
              container_port = 80
              # ONLY ONE ALLOWED PER SERVICE
              service_discovery = {
                # record_name    = "" # Default: service_name
                namespace_name = "project1.internal"
              }
            }
          }
        }
      }
    }

    ExAlarms = {
      # ecs_cluster_name                       = "dmc-prd-core-00"  # (Optional) Auto Discovery
      # vpc_name                               = "dmc-prd"          # (Optional) Auto Discovery
      # subnet_name                            = "dmc-prd-private*" # (Optional) Auto Discovery

      enable_autoscaling     = false
      enable_execute_command = true

      # ALARMS CONFIGURATION
      enable_alarms = true # Default: false

      ##### CLOUDWATCH ALARMS 
      alarms_cw_overrides = {
        # "warning-CPUUtilization" = {
        #   "actions_enabled"    = true
        #   "evaluation_periods" = 2
        #   "threshold"          = 30
        #   "period"             = 180
        #   "treat_missing_data" = "ignore"
        # }
      }

      #alarms_cw_disabled = ["critical-CPUUtilization", "warning-CPUUtilization", "critical-MemoryUtilization", "warning-MemoryUtilization"] # if you need to disable an cw alarm

      alarms_cw_custom = {
        # "custom-CPUUtilization" = {
        #   description = "is using more than 80% of CPU"
        #   threshold   = 55 #0.000002
        #   unit        = "Percent"
        #   metric_name = "CPUUtilization"
        #   statistic   = "Average"
        #   namespace   = "AWS/ECS"
        #   period      = 60
        #   alarms_tags = {
        #     "alarm-level"   = "CRIT"
        #     "alarm-OU"      = "Paymets"
        #     "alarm-urgency" = "immediate"
        #   }
        # }
      }

      ##### EVENTBRIDGE ALARMS 

      ############# IMPORTANT #############
      # If you need to change the resource aws_cloudwatch_event_rule and terraform requires recreating the resource, you might get the following error:
      # deleting EventBridge Rule : operation error EventBridge: DeleteRule, https response error StatusCode: 400, api error ValidationException: Rule can't be deleted since it has targets.
      # issue: https://github.com/hashicorp/terraform-provider-aws/issues/18519
      # in this case you must delete the resource and recreate it with the necessary changes

      # alarms_eb_disabled = ["task-stopped"] # if you need to disable an eb alarm
      alarms_eb_overrides = {
        #"task-stopped" = {
        #description = "ECS Task Restart - override"
        #targets_sns = ["arn:sns-1", "arn:sns-2"] # optional. default: sns-account-default
        #   event_bus_name = "event-bus-custom" 
        #   event_pattern = jsonencode({
        #     "source" : ["aws.ecs"],
        #     "detail-type" : ["ECS Task State Change"],
        #     "detail" : {
        #       "desiredStatus" : ["RUNNING"]
        #     }
        #   })
        #}
      }
      alarms_eb_custom = {
        #"fast-task-stopped" = {
        #  event_bus_name = "event-bus-custom" # optional. default: "default"
        #  targets_sns = ["arn:sns-1", "arn:sns-2"] # optional. default: sns-account-default
        #  description = "ECS Task Restart custom"
        #  event_pattern = jsonencode({
        #    "source" : ["aws.ecs"],
        #    "detail-type" : ["ECS Task State Change"],
        #    "detail" : {
        #      "lastStatus" : ["STOPPED"],
        #      "$or" : [
        #        {
        #          "stoppedReason" : [{
        #            "wildcard" : "*Error*"
        #          }, {
        #            "wildcard" : "*error*"
        #          }, {
        #            "wildcard" : "*Failed*"
        #          }]
        #        },
        #        {
        #          "containers" : {
        #            "exitCode" : [{
        #              "anything-but" : [0]
        #            }]
        #          }
        #        }
        #      ]
        #    }
        #  })
        #}
      }

      capacity_provider_strategy = {
        fargate_spot = {
          base              = null
          capacity_provider = "FARGATE_SPOT"
          weight            = 50
        }
      }

      # Policies used by tasks from the developed code
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      }
      tasks_iam_role_statements = [
        {
          actions   = ["s3:List*"]
          resources = ["arn:aws:s3:::*"]
        }
      ]
      # Policies used by the service to start tasks (ecr / ssm / etc)
      task_exec_iam_role_policies = {}
      task_exec_iam_statements    = []

      ecs_task_volume = []

      containers = {
        app = {
          image                 = "public.ecr.aws/docker/library/nginx:latest"
          create_ecr_repository = false
          map_environment       = {}
          map_secrets           = {}
          mount_points          = []
          ports = {
            "port1" = {
              container_port = 80
              load_balancer = {
                "alb1" = {
                  alb_name = "dmc-prd-example-ExExternal01"
                  listener_rules = {
                    "rule1" = {
                      # priority          = 10
                      # actions = [{ type = "forward" }] # Default Action
                      conditions = [
                        {
                          host_headers = ["ExAlarms.${local.zone_public}"]
                        }
                      ]
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

  }
  /*
  ecs_service_defaults = {
    alarms_defaults = {
      # enable_alarms_notifications = true # Default: true
      alarms_sns_topic_name = "dmc-prd-alerts" # Default: "gcl-dev-core-alerts / ${metadata.key.client}-${metadata.key.env}-${metadata.key.project}-alerts"
      # alarm_actions = "dmc-prd-core-alerts"
      # ok_actions = "dmc-prd-core-alerts"
    }
    eb_alarms_defaults = {
      alarms_sns_topic_name = "dmc-prd-alerts" # Default: "gcl-dev-core-alerts / ${metadata.key.client}-${metadata.key.env}-${metadata.key.project}-alerts"
    }
  }*/
}