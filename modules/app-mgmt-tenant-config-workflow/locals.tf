locals {
  app_tenant_iterations = csvdecode(file("./data/app-mgmt-tenant-configuration.csv"))
  
  distinct_tenants = toset(distinct([for tenant in local.app_tenant_iterations: tenant.TENANT_NAME]))

    application_profile_list = {
      for key, value in {
          for iteration in local.app_tenant_iterations : iteration.TENANT_NAME => iteration.MACRO_SEGMENTATION_ZONE...
      }
      : key => distinct(value)
    }

  network_centric_epgs_bds_list = {
      for iteration in local.app_tenant_iterations : "${iteration.TENANT_NAME}.${iteration.APPLICATION_NAME}.${iteration.MACRO_SEGMENTATION_ZONE}" => {
          TENANT_NAME             = iteration.TENANT_NAME
          APPLICATION_NAME        = iteration.APPLICATION_NAME
          MACRO_SEGMENTATION_ZONE = iteration.MACRO_SEGMENTATION_ZONE
          VLAN_ID                 = iteration.VLAN_ID
          BD_FLOOD                = lower(iteration.BD_FLOOD)
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
