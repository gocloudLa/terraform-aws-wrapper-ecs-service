locals {
  # ARMO OBJETO PARA SERVICE DISCOVERY
  service_discovery_tmp = [
    for service_name, service_config in var.ecs_service_parameters :
    [
      for container_name, container_config in service_config.containers :
      [
        for port_key, port_values in try(container_config.ports, {}) :
        {
          "${service_name}-${container_name}-${port_key}" = {
            "service_name"   = service_name
            "container_name" = container_name
            "name"           = "${local.common_name}-${service_name}-${port_values.container_port}"
            "port_key"       = port_key
            "port_values"    = port_values
          }
        }
        if can(port_values.service_discovery)
      ]
    ]
  ]
  service_discovery = merge(flatten(local.service_discovery_tmp)...)

  # ARMO OBJETO PARA SERVICE REGISTRIES
  service_registries = {
    for key, value in local.service_discovery :
    value.service_name => {
      container_name = value.container_name
      container_port = value.port_values.container_port
      port           = try(value.port_values.host_port, null)
      registry_arn   = try(aws_service_discovery_service.this["${value.service_name}-${value.container_name}-${value.port_key}"].arn, null)
    }
  }
}

data "aws_service_discovery_dns_namespace" "this" {
  for_each = local.service_discovery

  name = try(each.value.port_values.service_discovery.namespace_name, "internal")
  type = "DNS_PRIVATE"
}

resource "aws_service_discovery_service" "this" {
  for_each = local.service_discovery
  name     = try(each.value.port_values.service_discovery.record_name, each.value.service_name)

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.this[each.key].id

    dns_records {
      ttl  = try(each.value.port_values.service_discovery.record_ttl, 10)
      type = "A"
    }

    dns_records {
      ttl  = try(each.value.port_values.service_discovery.record_ttl, 10)
      type = "SRV"
    }


    routing_policy = try(each.value.port_values.service_discovery.routing_policy_type, "MULTIVALUE")
  }

  force_destroy = try(each.value.port_values.service_discovery.force_destroy, true)

}