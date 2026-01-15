# Security Group
locals {
  security_group_ingress_rules_calculated_tmp = [
    for service_key, service_config in var.ecs_service_parameters : {
      "${service_key}" = {
        for container_key, container in try(service_config.containers, {}) :
        "${service_key}-${container_key}" => [
          [
            for port in try(container.ports, []) :
            {
              for cidr_index, cidr_block in try(can(port["cidr_blocks"]) && length(port["cidr_blocks"]) > 0 ? port["cidr_blocks"] : [data.aws_vpc.this[service_key].cidr_block], [data.aws_vpc.this[service_key].cidr_block]) :
              "${service_key}-${port["container_port"]}-${cidr_index}" => {
                "from_port"   = try(port["host_port"], port["container_port"])
                "to_port"     = try(port["host_port"], port["container_port"])
                "ip_protocol" = try(port["protocol"], "tcp")
                "cidr_ipv4"   = cidr_block
                "description" = "Service port"
              }
            }
          ]
        ]
      }
    }
  ]

  security_group_ingress_rules_calculated = merge(flatten(local.security_group_ingress_rules_calculated_tmp)...)

  security_group_ingress_rules_calculated_final = {
    for service_key, containers in local.security_group_ingress_rules_calculated :
    service_key => merge([
      for container_key, rule_list in containers :
      merge(flatten(rule_list)...)
    ]...)
  }

  security_group_ingress_rules = {
    for service_key, service_config in var.ecs_service_parameters :
    service_key => try(service_config.security_group_ingress_rules, var.ecs_service_defaults.security_group_ingress_rules, local.security_group_ingress_rules_calculated_final[service_key])
  }
}

locals {
  security_group_egress_rules_default = {
    egress_all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    for service_key, service_config in var.ecs_service_parameters :
    service_key => try(service_config.security_group_egress_rules, var.ecs_service_defaults.security_group_egress_rules, local.security_group_egress_rules_default)
  }
}