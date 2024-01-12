######### IMPORTS #########

data "aci_attachable_access_entity_profile" "dataLocalAciAttachableEntityProfileIteration" {
    for_each = local.distinct_tenants
    
    name  = join("_", [each.value, "AAEP"])
}

data "aci_attachable_access_entity_profile" "dataLocalAciGobalAAEP" {
    name  = "GLOBAL_AAEP"
}

data "aci_leaf_interface_profile" "dataLocalAciFabricAccessLeafInterfaceProfileIteration" {
  for_each  = local.distinct_switch_nodes
  
  name      = join("_", [each.value, "INTPROF"])
}

######### POLICIES #########

resource "aci_lacp_policy" "localAciLacpActivePolicy" {
  name        = "LACP_ACTIVE"
  description = "ACI Nodes actively sends LACP packets to negotiate automatic bundling of links"
  annotation  = "ORCHESTRATOR:TERRAFORM"
  ctrl        = ["susp-individual", "load-defer", "graceful-conv"]
  max_links   = "16"
  min_links   = "1"
  mode        = "active"
}

######### GLOBAL #########

resource "aci_access_port_selector" "localAciPhysInterfaceSelectorIteration" {
  for_each                  = local.PhysInterfaceSelectors_UniqueList
  
  leaf_interface_profile_dn = data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].id
  name                      = join("_", ["Eth", each.value.ACI_NODE_SLOT, each.value.ACI_NODE_PORT])
  access_port_selector_type = "range"
  annotation                = "ORCHESTRATOR:TERRAFORM"
}

resource "aci_access_port_block" "localAciPhysInterfaceSelectorPortBlockIteration" {
  for_each                  = local.PhysInterfaceSelectors_UniqueList

  access_port_selector_dn           = aci_access_port_selector.localAciPhysInterfaceSelectorIteration[each.key].id
  name                              = join("_", ["Eth", each.value.ACI_NODE_SLOT, each.value.ACI_NODE_PORT])
  annotation                        = "ORCHESTRATOR:TERRAFORM"
  from_card                         = "${each.value.ACI_NODE_SLOT}"
  from_port                         = "${each.value.ACI_NODE_PORT}"
  to_card                           = "${each.value.ACI_NODE_SLOT}"
  to_port                           = "${each.value.ACI_NODE_PORT}"
}

######### NONBOND L2 PORTS #########

resource "aci_leaf_access_port_policy_group" "localAciTenantPhysAccessPortPolicyGroupIteration" {
  for_each    = local.TenantAccessPortPolicyGroup_UniqueList
  
  name        = join("_",[each.value.TENANT_NAME, each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "INT_POL_GRP"])
  description = join(" ",["Affects all", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "interface policy settings within tenant", each.value.TENANT_NAME])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  
  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id
}

resource "aci_rest" "localAciRestTenantNonBondIntSelectIntPolAssocIteration" {
  for_each = local.TenantNonBondIntSelectIntPolAssoc_UniqueList

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_port_policy_group.localAciTenantPhysAccessPortPolicyGroupIteration["${each.value.TENANT_NAME}.${each.value.ENDPOINT_MAKE}.${each.value.ENDPOINT_MODEL}.${each.value.ENDPOINT_OS}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}

resource "aci_leaf_access_port_policy_group" "localAciGlobalPhysAccessPortPolicyGroupIteration" {
  for_each    = local.GlobalAccessPortPolicyGroup_UniqueList
  
  name        = join("_",["GLOBAL", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "INT_POL_GRP"])
  description = join(" ",["Affects all", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "interface policy settings across the entire fabric."])
  annotation  = "ORCHESTRATOR:TERRAFORM"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id
}

resource "aci_rest" "localAciRestGlobalNonBondIntSelectIntPolAssocIteration" {
  for_each = local.GlobalNonBondIntSelectIntPolAssoc_UniqueList

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_port_policy_group.localAciGlobalPhysAccessPortPolicyGroupIteration["GLOBAL.${each.value.ENDPOINT_MAKE}.${each.value.ENDPOINT_MODEL}.${each.value.ENDPOINT_OS}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}

######### PORT-CHANNEL L2 Ports #########

resource "aci_leaf_access_bundle_policy_group" "localAciTenantPhysPortChannelPolicyGroup" {
  for_each    = local.TenantPortChannelPolicyGroup_UniqueList

  name        = join("_",["PC", each.value.TENANT_NAME, each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = "Single Homed Portchannel from Single ACI Node to Multiple NICs on Single Endpoint"
  lag_t       = "link"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
}

resource "aci_rest" "localAciRestTenantPCIntSelectIntPolAssocIteration" {
  for_each = local.TenantPCIntSelectIntPolAssoc_UniqueList

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciTenantPhysPortChannelPolicyGroup["${each.value.TENANT_NAME}.${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}

resource "aci_leaf_access_bundle_policy_group" "localAciGlobalPhysPortChannelPolicyGroup" {
  for_each    = local.GlobalPortChannelPolicyGroup_UniqueList

  name        = join("_",["PC", "GLOBAL", each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = "Single Homed Portchannel from Single ACI Node to Multiple NICs on Single Endpoint"
  lag_t       = "link"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
}

resource "aci_rest" "localAciRestGlobalPCIntSelectIntPolAssocIteration" {
  for_each = local.GlobalPCIntSelectIntPolAssoc_UniqueList

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciGlobalPhysPortChannelPolicyGroup["GLOBAL.${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}

######### VIRTUAL PORT-CHANNEL L2 PORTS #########

resource "aci_leaf_access_bundle_policy_group" "localAciTenantPhysVirtualPortChannelPolicyGroup" {
  for_each    = local.TenantVirtualPortChannelPolicyGroup_UniqueList

  name        = join("_",["VPC", each.value.TENANT_NAME, each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = "Dual Homed Portchannel from Two ACI Nodes to Multiple NICs on Single Endpoint"
  lag_t       = "node"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
}

resource "aci_rest" "localAciRestTenantVPCIntSelectIntPolAssocIteration" {
  for_each = local.TenantVPCIntSelectIntPolAssoc_UniqueList

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciTenantPhysVirtualPortChannelPolicyGroup["${each.value.TENANT_NAME}.${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}

resource "aci_leaf_access_bundle_policy_group" "localAciGlobalPhysVirtualPortChannelPolicyGroup" {
  for_each    = local.GlobalVirtualPortChannelPolicyGroup_UniqueList

  name        = join("_",["VPC", "GLOBAL", each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = "Dual Homed Portchannel from Two ACI Nodes to Multiple NICs on Single Endpoint"
  lag_t       = "node"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
}

resource "aci_rest" "localAciRestGlobalVPCIntSelectIntPolAssocIteration" {
  for_each = local.GlobalVPCIntSelectIntPolAssoc_UniqueList

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup["GLOBAL.${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF
}