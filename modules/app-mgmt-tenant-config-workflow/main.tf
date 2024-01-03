//  ------------- START SECTION: GUARDRAILS --------------- 
// ALL RESOURCES MUST BE DEPENDENT ON THESE FOR YOUR OWN HEALTH
resource "null_resource" "GlobalFabricVlanUniquenessCheckerPython" {
  provisioner "local-exec" {
    command = "python3 global-fabric-vlan-uniqueness-checker.py"
    working_dir = "${path.root}/scripts"
  }

  triggers = {
    csv_hash = filemd5("${path.root}/data/app-mgmt-tenant-configuration.csv")
  }
}

// ------------- END SECTION: GUARDRAILS ---------------

resource "aci_tenant" "localAciAppMgmtTenantIteration" {
    for_each = local.distinct_tenants
    
    name        = each.value
    description = join (" ",[each.value, "tenant was created via Terraform from a CI/CD Pipeline."])
    annotation  = "ORCHESTRATOR:TERRAFORM"
    
    depends_on = [
        null_resource.GlobalFabricVlanUniquenessCheckerPython
    ]    
}

resource "aci_application_profile" "localAciApplicationProfileIteration" {
    for_each = {
        for i in flatten([
            for TENANT_NAME, MACRO_SEGMENTATION_ZONES in local.application_profile_list:[
                for MACRO_SEGMENTATION_ZONE in MACRO_SEGMENTATION_ZONES: {
                    TENANT_NAME   = TENANT_NAME
                    APPLICATION_PROFILE_NAME = MACRO_SEGMENTATION_ZONE
                }
            ]
        ]):
        "${i.TENANT_NAME}.${i.APPLICATION_PROFILE_NAME}" => {
            TENANT_NAME = i.TENANT_NAME
            APPLICATION_PROFILE_NAME = i.APPLICATION_PROFILE_NAME
        }
    }
    
    tenant_dn   = aci_tenant.localAciAppMgmtTenantIteration[each.value.TENANT_NAME].id
    name        = each.value.APPLICATION_PROFILE_NAME
    annotation  = "ORCHESTRATOR:TERRAFORM"
    description = join (" ",[each.value.APPLICATION_PROFILE_NAME, "application profile was created as a macro-segmentation zone via Terraform from a CI/CD Pipeline."])

    depends_on = [
        null_resource.GlobalFabricVlanUniquenessCheckerPython
    ]    
}

resource "aci_bridge_domain" "localAciBridgeDomainIteration" {
    for_each = {
        for i in flatten([
            for TENANT_NAME, VLAN_IDs in local.bridge_domain_list:[
                for VLAN_ID in VLAN_IDs: {
                    TENANT_NAME   = TENANT_NAME
                    BRIDGE_DOMAIN_NAME = join("_",["VLAN", VLAN_ID, "BD"])
                }
            ]
        ]):
        "${i.TENANT_NAME}.${i.BRIDGE_DOMAIN_NAME}" => {
            TENANT_NAME = i.TENANT_NAME
            BRIDGE_DOMAIN_NAME = i.BRIDGE_DOMAIN_NAME
        }
    }
    
    tenant_dn   = aci_tenant.localAciAppMgmtTenantIteration[each.value.TENANT_NAME].id
    name        = each.value.BRIDGE_DOMAIN_NAME
    annotation  = "ORCHESTRATOR:TERRAFORM"
    description = join (" ",[each.value.BRIDGE_DOMAIN_NAME, "bridge domain was created as a VLAN for a macro-segmentation zone via Terraform from a CI/CD Pipeline."])
    
    depends_on = [
        null_resource.GlobalFabricVlanUniquenessCheckerPython
    ]
}