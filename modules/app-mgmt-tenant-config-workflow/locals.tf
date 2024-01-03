locals {
    app_tenant_iterations = csvdecode(file("./data/app-mgmt-tenant-configuration.csv"))
    
    distinct_tenants = toset(distinct([for tenant in local.app_tenant_iterations: tenant.TENANT_NAME]))
  
    application_profile_list = {
      for key, value in {
          for iteration in local.app_tenant_iterations : iteration.TENANT_NAME => iteration.MACRO_SEGMENTATION_ZONE...
      }
      : key => distinct(value)
    }    

    bridge_domain_list = {
      for key, value in {
          for iteration in local.app_tenant_iterations : iteration.TENANT_NAME => iteration.VLAN_ID...
      }
      : key => distinct(value)
    }

}