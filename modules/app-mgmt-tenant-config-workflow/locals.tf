locals {
  app_tenant_iterations = csvdecode(file("./data/tenant-configuration.csv"))

  distinct_tenants = toset(distinct([for tenant in local.app_tenant_iterations : tenant.TENANT_NAME]))

  application_profile_list = {
    for key, value in {
      for iteration in local.app_tenant_iterations : iteration.TENANT_NAME => iteration.MACRO_SEGMENTATION_ZONE...
    }
    : key => distinct(value)
  }

  network_centric_epgs_bds_list = {
    for iteration in local.app_tenant_iterations :
    "${iteration.TENANT_NAME}.${iteration.APPLICATION_NAME}.${iteration.MACRO_SEGMENTATION_ZONE}" => {
      TENANT_NAME             = iteration.TENANT_NAME
      APPLICATION_NAME        = iteration.APPLICATION_NAME
      MACRO_SEGMENTATION_ZONE = iteration.MACRO_SEGMENTATION_ZONE
      VLAN_ID                 = iteration.VLAN_ID
      BD_FLOOD                = lower(iteration.BD_FLOOD)
      INBOUND_PORTS = distinct(flatten([
        split(";", iteration.INBOUND_PORTS)
      ]))
      OUTBOUND_PORTS = distinct(flatten([
        split(";", iteration.OUTBOUND_PORTS)
      ]))
      PORTS = distinct(flatten([
        split(";", iteration.INBOUND_PORTS),
        split(";", iteration.OUTBOUND_PORTS)
      ]))
      ZONE_TRANSIT_VLAN_ID         = iteration.ZONE_TRANSIT_VLAN_ID
      ZONE_TRANSIT_SUBNET          = iteration.ZONE_TRANSIT_SUBNET
    }
  }

  inbound_port_pairs = flatten([
    for tenant_app, details in local.network_centric_epgs_bds_list : [
      for port in details.INBOUND_PORTS : {
        TENANT_NAME             = details.TENANT_NAME
        APPLICATION_NAME        = details.APPLICATION_NAME
        MACRO_SEGMENTATION_ZONE = details.MACRO_SEGMENTATION_ZONE
        INBOUND_PORT            = port
      }
    ]
  ])

  inbound_port_map = {
    for idx, val in local.inbound_port_pairs :
    "${val.TENANT_NAME}-${val.APPLICATION_NAME}-${val.MACRO_SEGMENTATION_ZONE}-${val.INBOUND_PORT}" => val
  }

  outbound_port_pairs = flatten([
    for tenant_app, details in local.network_centric_epgs_bds_list : [
      for port in details.OUTBOUND_PORTS : {
        TENANT_NAME             = details.TENANT_NAME
        APPLICATION_NAME        = details.APPLICATION_NAME
        MACRO_SEGMENTATION_ZONE = details.MACRO_SEGMENTATION_ZONE
        OUTBOUND_PORT           = port
      }
    ]
  ])

  outbound_port_map = {
    for idx, val in local.outbound_port_pairs :
    "${val.TENANT_NAME}-${val.APPLICATION_NAME}-${val.MACRO_SEGMENTATION_ZONE}-${val.OUTBOUND_PORT}" => val
  }

  protocol_port_tenant_list = distinct(flatten([
    for tenant_app, details in local.network_centric_epgs_bds_list :
    [for pp in details.PORTS : "${details.TENANT_NAME}.${pp}"]
  ]))

  distinct_protocol_port_tenant_pairs = {
    for item in local.protocol_port_tenant_list : item => {
      TENANT_NAME = split(".", item)[0]
      PROTOCOL    = lower(split(":", split(".", item)[1])[0])
      PORT        = try(split(":", split(".", item)[1])[1], "")
    }
  }


  bd_subnets_list = {
    for i in local.app_tenant_iterations :
    "${i.TENANT_NAME}-${i.APPLICATION_NAME}-${i.MACRO_SEGMENTATION_ZONE}-${i.SUBNET}" => {
      TENANT_NAME             = i.TENANT_NAME
      APPLICATION_NAME        = i.APPLICATION_NAME
      MACRO_SEGMENTATION_ZONE = i.MACRO_SEGMENTATION_ZONE
      VLAN_ID                 = i.VLAN_ID
      BD_FLOOD                = lower(i.BD_FLOOD)
      SUBNETS                 = split(";", trimspace(i.SUBNET))
    }
  }

  bd_subnet_ips = flatten([
    for item_key, item in local.bd_subnets_list : [
      for subnet in item.SUBNETS : {
        TENANT_NAME             = item.TENANT_NAME
        APPLICATION_NAME        = item.APPLICATION_NAME
        MACRO_SEGMENTATION_ZONE = item.MACRO_SEGMENTATION_ZONE
        VLAN_ID                 = item.VLAN_ID
        BD_FLOOD                = item.BD_FLOOD
        SUBNET                  = subnet
        GW_IP                   = cidrhost(subnet, 1)
        MASK                    = split("/", subnet)[1]
      }
    ]
  ])

}
