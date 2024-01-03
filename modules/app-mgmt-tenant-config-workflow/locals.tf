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
    }
  }

}