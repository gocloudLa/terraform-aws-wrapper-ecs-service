# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform ECS Service Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-ecs-service.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-ecs-service.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-ecs-service/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
The Terraform Wrapper for ECS SERVICE is a comprehensive solution module for deploying containerized applications in the Amazon Elastic Container Service.

### ✨ Features

- 🔢 [Multiple Tasks](#multiple-tasks) - Supports multiple containers per service with shared Fargate resources

- 🔗 [Integration with ALB](#integration-with-alb) - Automated ALB integration with target groups, listeners, and health checks

- 🔗 [Integration with Multiple ALB](#integration-with-multiple-alb) - Configures multiple ALBs on same/different ports with health checks

- 🔗 [Integration with Service Discovery](#integration-with-service-discovery) - Supports integration with CloudMap / Service Discovery, automates integration.

- 🌐 [Integration with DNS](#integration-with-dns) - Automates DNS A record creation for ALB targets

- 🗂️ [Integration with EFS](#integration-with-efs) - Mounts EFS volumes for containers, shared across services

- 🗓️ [Scheduled Task Support](#scheduled-task-support) - Scheduled task execution based on cron schedule

- 🔔 [Logs Notification](#logs-notification) - Configures log subscription filter to notify on non-INFO/DEBUG events

- 🔔 [Alarm Notification](#alarm-notification) - Configures CPU/memory alarms and task restart alerts with SNS notifications



### 🔗 External Modules
| Name | Version |
|------|------:|
| [terraform-aws-modules/ecr/aws](https://github.com/terraform-aws-modules/ecr-aws) | 2.4.0 |
| [terraform-aws-modules/lambda/aws](https://github.com/terraform-aws-modules/lambda-aws) | 8.0.1 |
| [terraform-aws-modules/ssm-parameter/aws](https://github.com/terraform-aws-modules/ssm-parameter-aws) | 1.1.2 |



## 🚀 Quick Start
```hcl
ecs_service_parameters = {
  ExSimple = {
    # ecs_cluster_name                       = "dmc-prd-core-00"  # (Opcional) Auto Descubrimiento
    # vpc_name                               = "dmc-prd"          # (Opcional) Auto Descubrimiento
    # subnet_name                            = "dmc-prd-private*" # (Opcional) Auto Descubrimiento

    enable_autoscaling = false
    enable_execute_command = true   

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies = {
      ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    }
    tasks_iam_role_statements = [
      {
        actions   = ["s3:List*"]
        resources = ["arn:aws:s3:::*"]
      }
    ]
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
    task_exec_iam_role_policies = {}
    task_exec_iam_statements    = []

    ecs_task_volume = []

    containers = {
      app = {

        cloudwatch_log_group_retention_in_days = 7
        readonlyRootFilesystem               = false

        ports = {
          "port1" = {
            container_port = 80
            # protocol       = "tcp" # Default: tcp
            # cidr_blocks    = [""]  # Default: [vpc_cidr]
            load_balancer = {
              "alb1" = {
                alb_name = "dmc-prd-core-external-00"
                listener_rules = {
                  "rule1" = {
                    # priority          = 10
                    # actions = [{ type = "forward" }] # Default Action
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
}
```


## 🔧 Additional Features Usage

### Multiple Tasks
The module supports starting more than one container for each service.<br/>
In this way, the serverless hardware that runs the containers (fargate) is shared.<br/>
**IMPORTANT** two containers running in the same service can receive requests from the same load balancer, but it is a condition that the containers run on different ports.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExDouble {
    # ecs_cluster_name                       = "dmc-prd-core-00"
    # vpc_name                               = "dmc-prd"
    # subnet_name                            = "dmc-prd-private*"
    enable_autoscaling = false

    enable_execute_command = true

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies   = {}
    tasks_iam_role_statements = []
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
                alb_name = "dmc-prd-core-external-00"
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
}
```


</details>


### Integration with ALB
Supports integration with ALB, automates generation of target_groups and listener_rules.<br/>
Also provides health_check features to the configured endpoints.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExAlb = {
    # ecs_cluster_name                       = "dmc-prd-core-00"
    # vpc_name                               = "dmc-prd"
    # subnet_name                            = "dmc-prd-private*"
    enable_autoscaling                 = false

    enable_execute_command = true

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies   = {}
    tasks_iam_role_statements = []
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
                alb_name             = "dmc-prd-core-external-00"
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
}
```


</details>


### Integration with Multiple ALB
Supports integration with multiple ALBs configured to request multiple ALBs on the same port in the service or different ports, automates generation of target_groups and listener_rules.<br/>
It also provides health_check features for the configured endpoints.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExAlbMulti = {
    # ecs_cluster_name                       = "dmc-prd-core-00"
    # vpc_name                               = "dmc-prd"
    # subnet_name                            = "dmc-prd-private*"
    enable_autoscaling                 = false

    enable_execute_command = true

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies   = {}
    tasks_iam_role_statements = []
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
                alb_name          = "dmc-prd-core-external-00"
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
                alb_name          = "dmc-prd-core-external-00" # Puede otro ALB / Internal por ejemplo
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
}
```


</details>


### Integration with Service Discovery
Supports integration with CloudMap / Service Discovery, automates integration.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExCloudmap = {
    # ecs_cluster_name                       = "dmc-prd-core-00"
    # vpc_name                               = "dmc-prd"
    # subnet_name                            = "dmc-prd-private*"
    enable_autoscaling = false

    enable_execute_command = true

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies   = {}
    tasks_iam_role_statements = []
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
            # SOLO SE ADMITE UNO POR SERVICE
            service_discovery = {
              # record_name    = "" # Default: service_name
              namespace_name = "project1.internal"
            }
          }
        }
      }
    }
  }
}
```


</details>


### Integration with DNS
Supports integration with DNS Route53 + ALB<br/>
Automates the generation of DNS A (Alias) records pointing to the assigned load balancer


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExDns = {
    enable_autoscaling                 = false

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies   = {}
    tasks_iam_role_statements = []
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
            load_balancer = {
              "alb1" = {
                alb_name             = "dmc-prd-core-external-00"
                alb_listener_port    = 443
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
}
```


</details>


### Integration with EFS
Subscribe to the containers to mount an EFS (Elastic File System / NFS) volume previously generated at the project level or externally (manually generated).


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExEfs = {
    # ecs_cluster_name               = "dmc-prd-core-00"
    # vpc_name                       = "dmc-prd"
    # subnet_name                    = "dmc-prd-private*"
    enable_autoscaling = false

    enable_execute_command = true

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies   = {}
    tasks_iam_role_statements = []
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
    # admin / admin
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
                alb_name = "dmc-prd-core-external-00"
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
}
```


</details>


### Scheduled Task Support
A task is configured that, instead of running as a service, runs based on a schedule (scheduler / cron).


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExScheduler = {
    enable_autoscaling        = false
    ecs_execution_type        = "schedule"
    schedule_expression       = "cron(0/5 * * * ? *)" # Run every 5 minutes
    create_ecs_lambda_trigger = true

    # Policies que usan la tasks desde el codigo desarrollado
    tasks_iam_role_policies   = {}
    tasks_iam_role_statements = []
    # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
}
```


</details>


### Logs Notification
The module generates a subscription filter on the log_group of the services and sends the events that meet the search pattern to the notification lambda function generated from the foundation level by **wrapper_notifications**.<br/><br/>
Currently, it only searches in a Json log format and notifies if the severity of the event is different from "INFO" or "DEBUG". In the future, this will be configurable<br/>
```
Current Filter: "{ $.level != \"INFO\" && $.level != \"DEBUG\" }"

```


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExNotifications = {
    ...
    logs_notifications = true
    # filter_pattern           = "\" \"" # Match everything
    ...

    containers = {
      app = {
        ...
      }
    }
  }
}
```


</details>


### Alarm Notification
The module allows the creation of alarms for CPU and Memory usage via cloudwatch and the creation of alarms by EventBridge to capture restarts of an ECS task. Both subscribe to an SNS for notification and also support changing any alarm value, disabling it, or creating a custom alarm.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
    ExAlarms = {
      # ecs_cluster_name                       = "dmc-prd-core-00"  # (Opcional) Auto Descubrimiento
      # vpc_name                               = "dmc-prd"          # (Opcional) Auto Descubrimiento
      # subnet_name                            = "dmc-prd-private*" # (Opcional) Auto Descubrimiento

      enable_autoscaling     = false
      enable_execute_command = true

      # ALARMS CONFIGURATION
      enable_alarms = true # Default: false
      alarms_cw_overrides = {
        # "warning-CPUUtilization" = {
        #   "actions_enabled"    = true
        #   "evaluation_periods" = 2
        #   "threshold"          = 30
        #   "period"             = 180
        #   "treat_missing_data" = "ignore"
        # }
      }
      alarms_cw_disabled = [
        #"critical-CPUUtilization", "warning-MemoryUtilization"
      ]
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

      # alarms_eb_disabled = ["ExAlarms-task-stopped"]

      alarms_eb_overrides = {
        # "ExAlarms-task-stopped" = {
        #   #create_bus = true
        #   event_pattern = jsonencode({
        #     "source" : ["aws.ecs"],
        #     "detail-type" : ["ECS Task State Change"],
        #     "detail" : {
        #       "group" : ["service:${local.common_name}-ExAlarms"]
        #       "desiredStatus" : ["STOPPED"]
        #     }
        #   })
        # }
      }
      alarms_eb_custom = {
        # "fast-task-stopped" = {
        #   create_bus = false
        #   name       = "ecs-fast-stop"
        #   description = "ECS Task Restart"
        #   event_pattern = jsonencode({
        #     "source" : ["aws.ecs"],
        #     "detail-type" : ["ECS Task State Change"],
        #     "detail" : {
        #       "group" : ["service:${local.common_name}-ExAlarms"]
        #       "lastStatus" : ["STOPPED"],
        #       "$or" : [
        #         {
        #           "stoppedReason" : [{
        #             "wildcard" : "*Error*"
        #             }, {
        #             "wildcard" : "*error*"
        #             }, {
        #             "wildcard" : "*Failed*"
        #           }]
        #         },
        #         {
        #           "containers" : {
        #             "exitCode" : [{
        #               "anything-but" : [0]
        #             }]
        #           }
        #         }
        #       ]
        #     }
        #   })
        # }
      }

      # Policies que usan la tasks desde el codigo desarrollado
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      }
      tasks_iam_role_statements = [
        {
          actions   = ["s3:List*"]
          resources = ["arn:aws:s3:::*"]
        }
      ]
      # Policies que usa el servicio para poder iniciar tasks (ecr / ssm / etc)
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
                  alb_name = "dmc-prd-core-external-00"
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
```


</details>











---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la
- 🐛 **Issues**: [GitHub Issues](https://github.com/gocloudLa/issues)

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 