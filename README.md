# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform ECS Service Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-ecs-service/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-ecs-service.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-ecs-service.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-ecs-service/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
The Terraform Wrapper for ECS SERVICE is a comprehensive, production-ready solution module for deploying and managing containerized applications in Amazon Elastic Container Service (ECS).

This module provides enterprise-grade features including automated load balancer integration, service discovery, persistent storage with EFS, comprehensive monitoring and alerting, scheduled task execution, and seamless DNS management. Built with security best practices and operational excellence in mind, it simplifies complex ECS deployments while maintaining flexibility and scalability.


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

- 🔍 [ECR Registry Scanning & Replication](#ecr-registry-scanning-&-replication) - Advanced ECR registry scanning and cross-region replication capabilities

- 🌐 [NLB (Network Load Balancing) integration](#nlb-(network-load-balancing)-integration) - Attach ECS services to existing Network Load Balancer target groups

- 🔗 [Multi-Port Load Balancing for ECS Services](#multi-port-load-balancing-for-ecs-services) - Expose multiple container ports through ALB and NLB



### 🔗 External Modules
| Name | Version |
|------|------:|
| <a href="https://github.com/terraform-aws-modules/terraform-aws-ecr" target="_blank">terraform-aws-modules/ecr/aws</a> | 3.2.0 |
| <a href="https://github.com/terraform-aws-modules/terraform-aws-lambda" target="_blank">terraform-aws-modules/lambda/aws</a> | 8.1.2 |
| <a href="https://github.com/terraform-aws-modules/terraform-aws-ssm-parameter" target="_blank">terraform-aws-modules/ssm-parameter/aws</a> | 2.1.0 |



## 🚀 Quick Start
```hcl
ecs_service_parameters = {
  ExSimple = {
    # ecs_cluster_name                       = "dmc-prd-core-00"  # (Optional) Auto Discovery
    # vpc_name                               = "dmc-prd"          # (Optional) Auto Discovery
    # subnet_name                            = "dmc-prd-private*" # (Optional) Auto Discovery

    enable_autoscaling = false
    enable_execute_command = true   

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
                alb_name          = "dmc-prd-core-external-00" # Can be another ALB / Internal for example
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
Enables seamless integration with AWS CloudMap (Service Discovery) for service-to-service communication within your VPC.<br/>
Automatically registers ECS services with CloudMap namespaces, allowing services to discover and communicate with each other using DNS names.<br/>
**Note**: Only one service discovery configuration is allowed per ECS service.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExCloudmap = {
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
Enables containers to mount EFS (Elastic File System / NFS) volumes for persistent, shared storage across multiple services and tasks.<br/>
Supports mounting previously created EFS volumes at the project level or externally managed volumes.<br/>
Provides flexible configuration for read-only and read-write access points, enabling data sharing and persistence across container restarts.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
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
Configures ECS tasks to run on a scheduled basis using cron expressions instead of running as continuous services.<br/>
Supports integration with AWS Lambda triggers for enhanced scheduling capabilities and monitoring.<br/>
Perfect for batch jobs, data processing tasks, maintenance operations, and other time-based workloads.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExScheduler = {
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
}
```


</details>


### Logs Notification
Automatically creates CloudWatch Logs subscription filters for ECS service log groups to monitor and alert on critical events.<br/>
Integrates with the **wrapper_notifications** Lambda function from the foundation level to send notifications when log events match specific patterns.<br/><br/>
**Current Capabilities:**
- Monitors JSON-formatted logs for severity levels other than "INFO" or "DEBUG"
- Sends real-time notifications for ERROR, WARN, FATAL, and other critical log levels
- Configurable filter patterns (future enhancement)

**Current Filter Pattern:**
```
"{ $.level != \"INFO\" && $.level != \"DEBUG\" }"
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
Comprehensive monitoring and alerting system for ECS services using CloudWatch and EventBridge integrations.<br/><br/>
**CloudWatch Alarms:**
- CPU and Memory utilization monitoring with configurable thresholds
- Support for custom alarm configurations and overrides
- Ability to disable specific alarms or create custom metrics

**EventBridge Integration:**
- Automatic detection of ECS task restarts and failures
- Configurable event patterns for different failure scenarios
- Real-time notifications for task state changes

**Notification Features:**
- SNS integration for multi-channel notifications (email, SMS, Slack, etc.)
- Customizable alarm tags for organization and routing
- Support for both warning and critical alert levels


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
    ExAlarms = {
      # ecs_cluster_name                       = "dmc-prd-core-00"  # (Optional) Auto Discovery
      # vpc_name                               = "dmc-prd"          # (Optional) Auto Discovery
      # subnet_name                            = "dmc-prd-private*" # (Optional) Auto Discovery

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


### ECR Registry Scanning & Replication
Provides comprehensive ECR registry management with advanced scanning and replication features.<br/><br/>

**Registry Scanning Configuration:**
- Enhanced or Basic scanning types with configurable rules
- Support for SCAN_ON_PUSH and CONTINUOUS_SCAN frequencies
- Wildcard and prefix-based filtering for targeted scanning

**Registry Replication Configuration:**
- Cross-region image replication for disaster recovery and performance
- Configurable destination regions and registry IDs
- Repository filtering for selective replication

**Image Tag Mutability:**
- Configurable tag mutability settings (MUTABLE, IMMUTABLE, etc.)
- Exclusion filters for specific tag patterns
- Support for wildcard-based tag filtering


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExEcrAdvanced = {
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
        # Registry Scanning Configuration
        manage_registry_scanning_configuration = true
        registry_scan_type                     = "ENHANCED"
        registry_scan_rules = [
          {
            scan_frequency = "SCAN_ON_PUSH"
            filter = [
              {
                filter      = "prod-*"
                filter_type = "WILDCARD"
              },
              {
                filter      = "release-*"
                filter_type = "WILDCARD"
              }
            ]
          },
          {
            scan_frequency = "CONTINUOUS_SCAN"
            filter = [
              {
                filter      = "latest"
                filter_type = "WILDCARD"
              }
            ]
          }
        ]

        # Registry Replication Configuration
        create_registry_replication_configuration = true
        registry_replication_rules = [
          {
            destinations = [
              {
                region      = "us-west-2"
                registry_id = "012345678901"
              },
              {
                region      = "eu-west-1"
                registry_id = "012345678901"
              }
            ]
            repository_filters = [
              {
                filter      = "prod-microservice"
                filter_type = "PREFIX_MATCH"
              }
            ]
          }
        ]

        # Image Tag Mutability
        repository_image_tag_mutability = "MUTABLE_WITH_EXCLUSION"
        repository_image_tag_mutability_exclusion_filter = [
          {
            filter      = "latest*"
            filter_type = "WILDCARD"
          },
          {
            filter      = "dev-*"
            filter_type = "WILDCARD"
          },
          {
            filter      = "qa-*"
            filter_type = "WILDCARD"
          }
        ]

        map_environment = {}
        map_secrets     = {}
        mount_points    = []
      }
    }
  }
}


</details>


### NLB (Network Load Balancing) integration
Enables ECS services to attach containers directly to existing **Network Load Balancer (NLB)** target groups.<br/><br/>

**Use Case:**
- Integrate existing ECS services into pre-provisioned network infrastructures.
- Attach multiple containers to different target groups across NLB.

**Key Details:**
- Target groups must be **created beforehand** (the module only attaches to them).


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExNlbAttach = {
    enable_autoscaling     = false
    enable_execute_command = true

    containers = {
      app = {
        image                 = "public.ecr.aws/docker/library/nginx:latest"
        create_ecr_repository = false

        ports = {
          "port1" = {
            container_port = 80

            load_balancer = {
              # Attach to an existing Network Load Balancer target group
              "nlb1" = {
                alb_name            = "dmc-prd-example-NlbExample01"
                target_group_attach = "dmc-prd-example-nlb-tcp-80" # Must exist beforehand
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


### Multi-Port Load Balancing for ECS Services
Enables ECS services to map **multiple container ports** to different **Application Load Balancer (ALB)** and **Network Load Balancer (NLB)** target groups.<br/><br/>

**Use Case:**
- Expose several ports of the same container using different load balancers.

**Key Details:**
- **ALB**: Target groups and listener rules are **created automatically** by the module.
- **NLB**: Target groups must be **created before**; the module only attaches containers to them.


<details><summary>Configuration Code</summary>

```hcl
ecs_service_parameters = {
  ExMultiPortLb = {
    enable_autoscaling = false
    enable_execute_command = true

    containers = {
      app = {
        image                 = "public.ecr.aws/docker/library/nginx:latest"
        create_ecr_repository = false
        ports = {
          # Multi Port configuration por Applications Load Balancers (ALB)
          "port1" = {
            container_port = 80
            load_balancer = {
              "alb1" = {
                alb_name                 = "dmc-prd-example-ExExternal01"
                target_group_custom_name = "custom-name" # Default: "${local.common_name}-${service_name}-${port_values.container_port}-${alb_key}"
                alb_listener_port        = 443
                deregistration_delay     = 300
                slow_start               = 30
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
                        host_headers = ["ExMultiPortLb.${local.zone_public}"]
                      }
                    ]
                  }
                }
              }
            }
          }
          "port2" = {
            container_port = 88
            load_balancer = {
              "alb2" = {
                alb_name                 = "dmc-prd-example-ExExternal01" # Can be another LB
                target_group_custom_name = "custom-name-2" # Default: "${local.common_name}-${service_name}-${port_values.container_port}-${alb_key}"
                alb_listener_port        = 443
                deregistration_delay     = 300
                slow_start               = 30
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
                        host_headers = ["ExMultiPortLb2.${local.zone_public}"]
                      }
                    ]
                  }
                }
              }
            }
          }
          # Multi Port configuration por Network Load Balancers (NLB)
          "nlb-tcp" = {
            container_port = 27000
            load_balancer = {
              "tcp" = {
                alb_name              = "dmc-prd-example-NlbExample01"
                target_group_attach   = "dmc-prd-example-nlb-tcp-27000"
              }
            }
          }
          "nlb-udp" = {
            container_port = 27001
            load_balancer = {
              "udp" = {
                alb_name              = "dmc-prd-example-NlbExample01"
                target_group_attach   = "dmc-prd-example-nlb-udp-27001"
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




## 📑 Inputs
| Name                                             | Description                                                                                                                                | Type     | Default                                                                                                              | Required |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ | -------- | -------------------------------------------------------------------------------------------------------------------- | -------- |
| name                                             | ECS service instance name.                                                                                                                 | `string` | `"${local.common_name}-${each.key}"`                                                                                 | no       |
| alarms                                           | Alarms associated with the ECS service (e.g., CloudWatch).                                                                                 | `map`    | `{}`                                                                                                                 | no       |
| assign_public_ip                                 | Indicates whether a public IP should be assigned to the ECS task.                                                                          | `bool`   | `false`                                                                                                              | no       |
| autoscaling_max_capacity                         | Maximum auto-scaling capacity for the ECS service.                                                                                         | `number` | `10`                                                                                                                 | no       |
| autoscaling_min_capacity                         | Minimum auto-scaling capacity for the ECS service.                                                                                         | `number` | `1`                                                                                                                  | no       |
| autoscaling_policies                             | Auto-scaling policies defined for CPU and memory.                                                                                          | `map`    | `Default configuration for CPU and memory`                                                                           | no       |
| autoscaling_scheduled_actions                    | Scheduled actions for auto-scaling.                                                                                                        | `map`    | `{}`                                                                                                                 | no       |
| availability_zone_rebalancing                    | Automatically redistributes tasks within a service between availability zones.                                                             | `string` | `"DISABLED"`                                                                                                         | no       |
| cluster_arn                                      | ARN of the ECS cluster to which the service belongs.                                                                                       | `string` | `data.aws_ecs_cluster.this[each.key].id`                                                                             | no       |
| container_definitions                            | Container definitions for the ECS service.                                                                                                 | `list`   | `local.container_definitions[each.key]`                                                                              | no       |
| cpu                                              | CPU units for the ECS service.                                                                                                             | `number` | `1024`                                                                                                               | no       |
| create                                           | Indicates whether the ECS service should be created.                                                                                       | `bool`   | `true`                                                                                                               | no       |
| create_iam_role                                  | Indicates whether an IAM role should be created for the service.                                                                           | `bool`   | `true`                                                                                                               | no       |
| create_infrastructure_iam_role                   | Indicates whether an IAM role should be created for the infrastructure.                                                                    | `bool`   | `false`                                                                                                              | no       |
| create_security_group                            | Indicates whether a security group should be created.                                                                                      | `bool`   | `true`                                                                                                               | no       |
| create_service                                   | Indicates whether the ECS service should be created.                                                                                       | `bool`   | `false`                                                                                                              | no       |
| create_task_definition                           | Indicates whether the task definition for the ECS service should be created.                                                               | `bool`   | `true`                                                                                                               | no       |
| create_task_exec_iam_role                        | Indicates whether an IAM role should be created for task execution.                                                                        | `bool`   | `true`                                                                                                               | no       |
| create_task_exec_policy                          | Indicates whether a policy should be created for task execution.                                                                           | `bool`   | `true`                                                                                                               | no       |
| create_tasks_iam_role                            | Indicates whether an IAM role should be created for tasks.                                                                                 | `bool`   | `true`                                                                                                               | no       |
| deployment_circuit_breaker                       | Circuit breaker configuration for deployments.                                                                                             | `map`    | `{}`                                                                                                                 | no       |
| deployment_controller                            | Deployment controller for the ECS service.                                                                                                 | `map`    | `{}`                                                                                                                 | no       |
| deployment_maximum_percent                       | Maximum percentage of deployment during updates.                                                                                           | `number` | `200`                                                                                                                | no       |
| deployment_minimum_healthy_percent               | Minimum percentage of healthy instances during deployment.                                                                                 | `number` | `66`                                                                                                                 | no       |
| desired_count                                    | Desired number of running instances of the service.                                                                                        | `number` | `1 (or 0 if ecs_execution_type is "schedule")`                                                                       | no       |
| enable_autoscaling                               | Indicates whether auto-scaling should be enabled.                                                                                          | `bool`   | `true (or false if ecs_execution_type is "schedule")`                                                                | no       |
| enable_ecs_managed_tags                          | Indicates whether ECS-managed tags should be enabled.                                                                                      | `bool`   | `true`                                                                                                               | no       |
| enable_execute_command                           | Indicates whether the execute command should be enabled on the ECS service.                                                                | `bool`   | `true`                                                                                                               | no       |
| enable_fault_injection                           | Allows fault injection and accepts fault injection requests from task containers.                                                          | `bool`   | `false`                                                                                                              | no       |
| ephemeral_storage                                | Ephemeral storage configuration for the ECS service.                                                                                       | `map`    | `{}`                                                                                                                 | no       |
| external_id                                      | External ID for the ECS service.                                                                                                           | `string` | `null`                                                                                                               | no       |
| family                                           | Family of the ECS task definition.                                                                                                         | `string` | `null`                                                                                                               | no       |
| force_delete                                     | Indicates whether to force deletion of the ECS service.                                                                                    | `bool`   | `null`                                                                                                               | no       |
| force_new_deployment                             | Indicates whether to force a new deployment of the ECS service.                                                                            | `bool`   | `true`                                                                                                               | no       |
| health_check_grace_period_seconds                | Grace period for service health checks.                                                                                                    | `number` | `null`                                                                                                               | no       |
| iam_role_arn                                     | ARN of the IAM role associated with the ECS service.                                                                                       | `string` | `null`                                                                                                               | no       |
| iam_role_description                             | Description of the IAM role associated with the ECS service.                                                                               | `string` | `null`                                                                                                               | no       |
| iam_role_name                                    | Name of the IAM role associated with the ECS service.                                                                                      | `string` | `null`                                                                                                               | no       |
| iam_role_path                                    | Path of the IAM role associated with the ECS service.                                                                                      | `string` | `null`                                                                                                               | no       |
| iam_role_permissions_boundary                    | Permissions boundary of the IAM role associated with the ECS service.                                                                      | `string` | `null`                                                                                                               | no       |
| iam_role_statements                              | Permission statements for the IAM role.                                                                                                    | `list`   | `[]`                                                                                                                 | no       |
| iam_role_tags                                    | Tags for the IAM role.                                                                                                                     | `map`    | `{}`                                                                                                                 | no       |
| iam_role_use_name_prefix                         | Indicates whether to use a prefix for the IAM role name.                                                                                   | `bool`   | `true`                                                                                                               | no       |
| ignore_task_definition_changes                   | Indicates whether to ignore changes in the task definition.                                                                                | `bool`   | `false`                                                                                                              | no       |
| infrastructure_iam_role_arn                      | ARN of the IAM role for infrastructure.                                                                                                    | `string` | `null`                                                                                                               | no       |
| infrastructure_iam_role_name                     | Name of the IAM role for infrastructure.                                                                                                   | `string` | `null`                                                                                                               | no       |
| infrastructure_iam_role_use_name_prefix          | Indicates whether to use a prefix for the infrastructure IAM role name.                                                                    | `bool`   | `false`                                                                                                              | no       |
| infrastructure_iam_role_path                     | Path of the IAM role for infrastructure.                                                                                                   | `string` | `null`                                                                                                               | no       |
| infrastructure_iam_role_description              | Description of the IAM role for infrastructure.                                                                                            | `string` | `null`                                                                                                               | no       |
| infrastructure_iam_role_permissions_boundary     | Permissions boundary of the IAM role for infrastructure.                                                                                   | `string` | `null`                                                                                                               | no       |
| infrastructure_iam_role_tags                     | Tags for the infrastructure IAM role.                                                                                                      | `map`    | `null`                                                                                                               | no       |
| ipc_mode                                         | IPC mode for the container.                                                                                                                | `string` | `null`                                                                                                               | no       |
| launch_type                                      | Launch type of the ECS service.                                                                                                            | `string` | `"FARGATE"`                                                                                                          | no       |
| load_balancer                                    | Load balancer configuration.                                                                                                               | `map`    | `local.load_balancer_calculated[each.key]`                                                                           | no       |
| memory                                           | Memory allocated to the ECS service container (in MiB).                                                                                    | `number` | `2048`                                                                                                               | no       |
| network_mode                                     | Network mode for the container.                                                                                                            | `string` | `"awsvpc"`                                                                                                           | no       |
| ordered_placement_strategy                       | Ordered placement strategy for instances.                                                                                                  | `map`    | `{}`                                                                                                                 | no       |
| pid_mode                                         | PID mode for the container.                                                                                                                | `string` | `null`                                                                                                               | no       |
| placement_constraints                            | Placement constraints for the ECS service.                                                                                                 | `list`   | `{}`                                                                                                                 | no       |
| platform_version                                 | Platform version for the ECS service.                                                                                                      | `string` | `null`                                                                                                               | no       |
| propagate_tags                                   | Indicates whether tags should be propagated to the service.                                                                                | `string` | `null`                                                                                                               | no       |
| proxy_configuration                              | Proxy configuration for the ECS service.                                                                                                   | `map`    | `null`                                                                                                               | no       |
| requires_compatibilities                         | Required compatibilities for the ECS service.                                                                                              | `list`   | `["FARGATE"]`                                                                                                        | no       |
| runtime_platform                                 | Runtime platform for the container.                                                                                                        | `map`    | `{ operating_system_family = "LINUX", cpu_architecture = "X86_64" }`                                                 | no       |
| scale                                            | Scaling configuration for the ECS service.                                                                                                 | `map`    | `{}`                                                                                                                 | no       |
| scheduling_strategy                              | Scheduling strategy for the ECS service.                                                                                                   | `string` | `null`                                                                                                               | no       |
| security_group_description                       | Description for the security group.                                                                                                        | `string` | `null`                                                                                                               | no       |
| security_group_ids                               | Security group IDs associated with the ECS service.                                                                                        | `list`   | `[]`                                                                                                                 | no       |
| security_group_name                              | Name of the security group associated with the ECS service.                                                                                | `string` | `null`                                                                                                               | no       |
| security_group_ingress_rules                     | Ingress rules for the security group.                                                                                                      | `map`    | `local.security_group_rules_calculated[each.key]`                                                                    | no       |
| security_group_tags                              | Tags for the security group.                                                                                                               | `map`    | `{}`                                                                                                                 | no       |
| security_group_use_name_prefix                   | Indicates whether to use a prefix for the security group name.                                                                             | `bool`   | `true`                                                                                                               | no       |
| service_connect_configuration                    | Service Connect configuration.                                                                                                             | `map`    | `{}`                                                                                                                 | no       |
| service_registries                               | Service registries associated with the ECS service.                                                                                        | `list`   | `local.service_registries[each.key]`                                                                                 | no       |
| service_tags                                     | Tags for the ECS service.                                                                                                                  | `map`    | `{}`                                                                                                                 | no       |
| skip_destroy                                     | Indicates whether to skip service destruction.                                                                                             | `bool`   | `null`                                                                                                               | no       |
| subnet_ids                                       | Subnet IDs associated with the ECS service.                                                                                                | `list`   | `data.aws_subnets.this[each.key].ids`                                                                                | no       |
| task_definition_arn                              | ARN of the task definition associated with the ECS service.                                                                                | `string` | `null`                                                                                                               | no       |
| task_definition_placement_constraints            | Placement constraints for the task definition.                                                                                             | `map`    | `{}`                                                                                                                 | no       |
| task_exec_iam_role_arn                           | ARN of the IAM role for task execution.                                                                                                    | `string` | `null`                                                                                                               | no       |
| task_exec_iam_role_description                   | Description of the IAM role for task execution.                                                                                            | `string` | `null`                                                                                                               | no       |
| task_exec_iam_role_max_session_duration          | Maximum session duration for the task execution IAM role.                                                                                  | `number` | `null`                                                                                                               | no       |
| task_exec_iam_role_name                          | Name of the IAM role for task execution.                                                                                                   | `string` | `null`                                                                                                               | no       |
| task_exec_iam_role_path                          | Path of the IAM role for task execution.                                                                                                   | `string` | `null`                                                                                                               | no       |
| task_exec_iam_role_permissions_boundary          | Permissions boundary for the task execution IAM role.                                                                                      | `string` | `null`                                                                                                               | no       |
| task_exec_iam_role_policies                      | Policies for the task execution IAM role.                                                                                                  | `list`   | `{}`                                                                                                                 | no       |
| task_exec_iam_role_tags                          | Tags for the task execution IAM role.                                                                                                      | `map`    | `{}`                                                                                                                 | no       |
| task_exec_iam_role_use_name_prefix               | Indicates whether to use a prefix for the task execution IAM role name.                                                                    | `bool`   | `true`                                                                                                               | no       |
| task_exec_iam_statements                         | IAM statements for the task execution role.                                                                                                | `list`   | `[]`                                                                                                                 | no       |
| task_exec_secret_arns                            | ARNs of secrets for task execution.                                                                                                        | `list`   | `["arn:aws:secretsmanager:*:*:secret:${local.common_name}-${each.key}-*"]`                                           | no       |
| task_exec_ssm_param_arns                         | ARNs of SSM parameters for task execution.                                                                                                 | `list`   | `["arn:aws:ssm:*:*:parameter/${local.common_name}-${each.key}-*"]`                                                   | no       |
| task_tags                                        | Tags for the tasks.                                                                                                                        | `map`    | `{}`                                                                                                                 | no       |
| tasks_iam_role_arn                               | ARN of the IAM role for tasks.                                                                                                             | `string` | `null`                                                                                                               | no       |
| tasks_iam_role_description                       | Description of the IAM role for tasks.                                                                                                     | `string` | `null`                                                                                                               | no       |
| tasks_iam_role_name                              | Name of the IAM role for tasks.                                                                                                            | `string` | `null`                                                                                                               | no       |
| tasks_iam_role_path                              | Path of the IAM role for tasks.                                                                                                            | `string` | `null`                                                                                                               | no       |
| tasks_iam_role_permissions_boundary              | Permissions boundary for the tasks IAM role.                                                                                               | `string` | `null`                                                                                                               | no       |
| tasks_iam_role_policies                          | Policies for the tasks IAM role.                                                                                                           | `list`   | `{}`                                                                                                                 | no       |
| tasks_iam_role_statements                        | IAM statements for the tasks role.                                                                                                         | `list`   | `[]`                                                                                                                 | no       |
| tasks_iam_role_tags                              | Tags for the tasks IAM role.                                                                                                               | `map`    | `{}`                                                                                                                 | no       |
| tasks_iam_role_use_name_prefix                   | Indicates whether to use a prefix for the tasks IAM role name.                                                                             | `bool`   | `true`                                                                                                               | no       |
| timeouts                                         | Timeout configuration for operations.                                                                                                      | `map`    | `{}`                                                                                                                 | no       |
| track_latest                                     | Whether to track the latest ACTIVE task definition in AWS or the one stored in state.                                                      | `bool`   | `true`                                                                                                               | no       |
| volume                                           | Volume configuration for the service.                                                                                                      | `list`   | `concat(try(local.container_module_ecs_task_volume_efs[each.key], []), try(each.value.service.ecs_task_volume, []))` | no       |
| volume_configuration                             | Configuration for volumes specified in the task definition. Currently supports Amazon EBS volumes.                                         | `map`    | `null`                                                                                                               | no       |
| vpc_lattice_configurations                       | VPC Lattice configuration for cross-account and cross-VPC service connectivity.                                                            | `map`    | `null`                                                                                                               | no       |
| wait_for_steady_state                            | Indicates whether to wait for a steady state.                                                                                              | `bool`   | `null`                                                                                                               | no       |
| wait_until_stable                                | Indicates whether to wait until the service is stable.                                                                                     | `bool`   | `null`                                                                                                               | no       |
| wait_until_stable_timeout                        | Timeout for waiting until the service is stable.                                                                                           | `number` | `null`                                                                                                               | no       |
| repository_name                                  | The name of the ECR repository.                                                                                                            | `string` | `null`                                                                                                               | no       |
| repository_lifecycle_policy                      | The policy document for ECR repository lifecycle.                                                                                          | `string` | `null`                                                                                                               | no       |
| repository_image_tag_mutability                  | The tag mutability setting for the repository.                                                                                             | `string` | `"MUTABLE"`                                                                                                          | no       |
| repository_image_tag_mutability_exclusion_filter | Configuration block that defines filters to specify which image tags can override the default tag mutability setting.                      | `list`   | `null`                                                                                                               | no       |
| repository_read_access_arns                      | The ARNs of the IAM users/roles that have read access to the repository.                                                                   | `list`   | `[]`                                                                                                                 | no       |
| repository_read_write_access_arns                | The ARNs of the IAM users/roles that have read/write access to the repository.                                                             | `list`   | `[]`                                                                                                                 | no       |
| manage_registry_scanning_configuration           | Determines whether the registry scanning configuration will be managed.                                                                    | `bool`   | `false`                                                                                                              | no       |
| registry_scan_type                               | The scanning type to set for the registry. Can be either ENHANCED or BASIC.                                                                | `string` | `"ENHANCED"`                                                                                                         | no       |
| registry_scan_rules                              | One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur. | `list`   | `null`                                                                                                               | no       |
| create_registry_replication_configuration        | Determines whether a registry replication configuration will be created.                                                                   | `bool`   | `false`                                                                                                              | no       |
| registry_replication_rules                       | The replication rules for a replication configuration. A maximum of 10 are allowed.                                                        | `list`   | `null`                                                                                                               | no       |
| tags                                             | A map of tags to assign to resources.                                                                                                      | `map`    | `{}`                                                                                                                 | no       |








---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 