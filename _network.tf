# Security Group
locals {
  security_group_ingress_rules_calculated_tmp = [
    for service_key, service_config in var.ecs_service_parameters : {
      "${service_key}" = {
        for container_key, container in try(service_config.containers, {}) :
        "${service_key}-${container_key}" => [{
          for port in try(container.ports, []) :
          "${service_key}-${port["container_port"]}" => {
            "from_port"   = try(port["host_port"], port["container_port"])
            "to_port"     = try(port["host_port"], port["container_port"])
            "ip_protocol" = try(port["protocol"], "tcp")
            "cidr_ipv4"   = try(port["cidr_blocks"][0], data.aws_vpc.this[service_key].cidr_block)
            "description" = "Service port"
          }
        }]
      }
    }
  ]
  security_group_ingress_rules_calculated = merge(flatten(local.security_group_ingress_rules_calculated_tmp)...)

  security_group_ingress_rules = {
    for service_key, containers in local.security_group_ingress_rules_calculated :
    service_key => merge([
      for container_key, rule_list in containers :
      rule_list[0]
    ]...)
  }

  security_group_egress_rules_default = {
    egress_all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    for service_key in keys(var.ecs_service_parameters) :
    "${service_key}" => local.security_group_egress_rules_default
  }
}