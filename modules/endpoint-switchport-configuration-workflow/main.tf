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

data "aci_tenant" "dataLocalAciTenantIteration" {
  for_each = local.distinct_tenants
    
  name     = each.value
  
}

data "aci_application_profile" "dataLocalAciTenantApplicationProfileIteration" {
  for_each   = local.AppProf_Map
  
  tenant_dn  = data.aci_tenant.dataLocalAciTenantIteration["${each.value.TENANT_NAME}"].id
  name       = each.value.MACRO_SEGMENTATION_ZONE
  
}

data "aci_application_epg" "dataLocalAciTenantApplicationEndpointGroupIteration" {
  for_each   = local.AppEpg_Map
  
  application_profile_dn  = data.aci_application_profile.dataLocalAciTenantApplicationProfileIteration["${each.value.TENANT_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  name                    = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "aEPG"])
  
}

data "aci_l3_outside" "dataLocalAciTenantAppProfVrfL3OutProfNgfwIteration" {
  for_each  = local.ExternalOutside_Map
  
  tenant_dn = data.aci_tenant.dataLocalAciTenantIteration["${each.value.TENANT_NAME}"].id
  name      = join("_", [each.value.TENANT_NAME, each.value.MACRO_SEGMENTATION_ZONE, "VRF", "NGFW", "L3OUT"])
}

######### POLICIES #########

resource "aci_lacp_policy" "localAciLacpActivePolicy" {
  name        = "LACP_ACTIVE"
  description = "ACI Nodes actively sends LACP packets to negotiate automatic bundling of links"
  annotation  = "orchestrator:terraform"
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
  annotation                = "orchestrator:terraform"
  
  lifecycle {
    ignore_changes = [
      relation_infra_rs_acc_base_grp,
      leaf_interface_profile_dn
    ]
  }  
}

resource "aci_access_port_block" "localAciPhysInterfaceSelectorPortBlockIteration" {
  for_each                  = local.PhysInterfaceSelectors_UniqueList

  access_port_selector_dn           = aci_access_port_selector.localAciPhysInterfaceSelectorIteration[each.key].id
  name                              = join("_", ["Eth", each.value.ACI_NODE_SLOT, each.value.ACI_NODE_PORT])
  annotation                        = "orchestrator:terraform"
  from_card                         = "${each.value.ACI_NODE_SLOT}"
  from_port                         = "${each.value.ACI_NODE_PORT}"
  to_card                           = "${each.value.ACI_NODE_SLOT}"
  to_port                           = "${each.value.ACI_NODE_PORT}"


  
  lifecycle {
    ignore_changes = [
      description,
      relation_infra_rs_acc_bndl_subgrp
    ]
  }   
}

resource "aci_rest" "localAciRestPhysIntSelectDescIteration" {
  for_each = local.PhysIntSelectDesc_Map

  path = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/portblk-${aci_access_port_block.localAciPhysInterfaceSelectorPortBlockIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}.json"

  payload = <<EOF
{
  "infraPortBlk": {
    "attributes": {
      "dn": "uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/portblk-${aci_access_port_block.localAciPhysInterfaceSelectorPortBlockIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}",
      "descr": "${join(" ", [each.value.ENDPOINT_NAME, each.value.ENDPOINT_NIC])}"
    },
    "children": []
  }
}
EOF

}

resource "aci_access_port_selector" "localAciExtInterfaceSelectorIteration" {
  for_each                  = local.ExtInterfaceSelectors_UniqueList
  
  leaf_interface_profile_dn = data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].id
  name                      = join("_", ["Eth", each.value.ACI_NODE_SLOT, each.value.ACI_NODE_PORT])
  access_port_selector_type = "range"
  annotation                = "orchestrator:terraform"
  
  lifecycle {
    ignore_changes = [
      relation_infra_rs_acc_base_grp,
      leaf_interface_profile_dn
    ]
  }  
}

resource "aci_access_port_block" "localAciExtInterfaceSelectorPortBlockIteration" {
  for_each                  = local.ExtInterfaceSelectors_UniqueList

  access_port_selector_dn           = aci_access_port_selector.localAciExtInterfaceSelectorIteration[each.key].id
  name                              = join("_", ["Eth", each.value.ACI_NODE_SLOT, each.value.ACI_NODE_PORT])
  annotation                        = "orchestrator:terraform"
  from_card                         = "${each.value.ACI_NODE_SLOT}"
  from_port                         = "${each.value.ACI_NODE_PORT}"
  to_card                           = "${each.value.ACI_NODE_SLOT}"
  to_port                           = "${each.value.ACI_NODE_PORT}"


  
  lifecycle {
    ignore_changes = [
      description,
      relation_infra_rs_acc_bndl_subgrp
    ]
  }   
}

resource "aci_rest" "localAciRestExtIntSelectDescIteration" {
  for_each = local.ExtIntSelectDesc_Map

  path = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciExtInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/portblk-${aci_access_port_block.localAciExtInterfaceSelectorPortBlockIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}.json"

  payload = <<EOF
{
  "infraPortBlk": {
    "attributes": {
      "dn": "uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciExtInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/portblk-${aci_access_port_block.localAciExtInterfaceSelectorPortBlockIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}",
      "descr": "${join(" ", [each.value.ENDPOINT_NAME, each.value.ENDPOINT_NIC])}"
    },
    "children": []
  }
}
EOF

}

######### NONBOND L2 PORTS #########

resource "aci_leaf_access_port_policy_group" "localAciTenantPhysAccessPortPolicyGroupIteration" {
  for_each    = local.TenantAccessPortPolicyGroup_UniqueList
  
  name        = join("_",[each.value.TENANT_NAME, each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "INT_POL_GRP"])
  description = join(" ",["Affects all", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "interface policy settings within tenant", each.value.TENANT_NAME])
  annotation  = "orchestrator:terraform"
  
  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id

  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }  
  
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

  depends_on = [
    aci_access_port_selector.localAciPhysInterfaceSelectorIteration,
    aci_leaf_access_port_policy_group.localAciTenantPhysAccessPortPolicyGroupIteration
  ]  

}

resource "aci_leaf_access_port_policy_group" "localAciGlobalPhysAccessPortPolicyGroupIteration" {
  for_each    = local.GlobalAccessPortPolicyGroup_UniqueList
  
  name        = join("_",["GLOBAL", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "INT_POL_GRP"])
  description = join(" ",["Affects all", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "interface policy settings across the entire fabric."])
  annotation  = "orchestrator:terraform"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id

  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }  
  
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

resource "aci_epg_to_static_path" "PhysNonBondIntSelectAppEpgStaticBindIteration" {
  for_each   = local.PhysNonBondIntSelectAppEpgStaticBind_Map

  application_epg_dn  = data.aci_application_epg.dataLocalAciTenantApplicationEndpointGroupIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}.${each.value.VLAN_ID}"].id
  tdn  = "topology/pod-${each.value.ACI_POD_ID}/paths-${each.value.ACI_NODE_ID}/pathep-[eth${each.value.ACI_NODE_SLOT}/${each.value.ACI_NODE_PORT}]"
  annotation = "orchestrator:terraform"
  encap  = "vlan-${each.value.VLAN_ID}"
  instr_imedcy = "immediate"
  mode  = lower(each.value.DOT1Q_ENABLE) == "true" ? "regular" : "native"

  lifecycle {
    ignore_changes = [application_epg_dn]
  }  
  
}

######### PORT-CHANNEL L2 Ports #########

resource "aci_leaf_access_bundle_policy_group" "localAciTenantPhysPortChannelPolicyGroup" {
  for_each    = local.TenantPortChannelPolicyGroup_UniqueList

  name        = join("_",["PC", each.value.TENANT_NAME, each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "orchestrator:terraform"
  description = "Single Homed Portchannel from Single ACI Node to Multiple NICs on Single Endpoint"
  lag_t       = "link"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
  
  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }     
  
}

resource "aci_rest" "localAciRestTenantPCIntSelectIntPolAssocIteration" {
  for_each = local.TenantPCIntSelectIntPolAssoc_Map

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

  depends_on = [
    aci_access_port_selector.localAciPhysInterfaceSelectorIteration,
    aci_leaf_access_bundle_policy_group.localAciTenantPhysPortChannelPolicyGroup
  ]  

}

resource "aci_leaf_access_bundle_policy_group" "localAciGlobalPhysPortChannelPolicyGroup" {
  for_each    = local.GlobalPortChannelPolicyGroup_UniqueList

  name        = join("_",["PC", "GLOBAL", each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "orchestrator:terraform"
  description = "Single Homed Portchannel from Single ACI Node to Multiple NICs on Single Endpoint"
  lag_t       = "link"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
  
  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }    
  
}

resource "aci_rest" "localAciRestGlobalPCIntSelectIntPolAssocIteration" {
  for_each = local.GlobalPCIntSelectIntPolAssoc_Map

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciGlobalPhysPortChannelPolicyGroup["${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF

  depends_on = [
    aci_access_port_selector.localAciPhysInterfaceSelectorIteration,
    aci_leaf_access_bundle_policy_group.localAciGlobalPhysPortChannelPolicyGroup
  ]  

}

######### VIRTUAL PORT-CHANNEL L2 PORTS #########

resource "aci_leaf_access_bundle_policy_group" "localAciTenantPhysVirtualPortChannelPolicyGroup" {
  for_each    = local.TenantVirtualPortChannelPolicyGroup_UniqueList

  name        = join("_",["VPC", each.value.TENANT_NAME, each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "orchestrator:terraform"
  description = "Dual Homed Portchannel from Two ACI Nodes to Multiple NICs on Single Endpoint"
  lag_t       = "node"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
  
  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }       
  
}

resource "aci_rest" "localAciRestTenantVPCIntSelectIntPolAssocIteration" {
  for_each = local.TenantVPCIntSelectIntPolAssoc_Map

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

  depends_on = [
    aci_access_port_selector.localAciPhysInterfaceSelectorIteration,
    aci_leaf_access_bundle_policy_group.localAciTenantPhysVirtualPortChannelPolicyGroup
  ]  

}

resource "aci_epg_to_static_path" "localAciTenantVpcIntSelectEpgAssoc" {
  for_each            = local.TenantVpcIntSelectEpgAssoc_List


  application_epg_dn  = data.aci_application_epg.dataLocalAciTenantApplicationEndpointGroupIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}.${each.value.VLAN_ID}"].id
  tdn  = "topology/pod-${each.value.ACI_POD_ID}/protpaths-${each.value.ODD_NODE_ID}-${each.value.EVEN_NODE_ID}/pathep-[${aci_leaf_access_bundle_policy_group.localAciTenantPhysVirtualPortChannelPolicyGroup["${each.value.TENANT_NAME}.${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].name}]"
  annotation = "orchestrator:terraform"
  encap  = "vlan-${each.value.VLAN_ID}"
  instr_imedcy = "immediate"
  mode  = lower(each.value.DOT1Q_ENABLE) == "true" ? "regular" : "native"

  lifecycle {
    ignore_changes = [application_epg_dn]
  }    
   
}

resource "aci_leaf_access_bundle_policy_group" "localAciGlobalPhysVirtualPortChannelPolicyGroup" {
  for_each    = local.GlobalVirtualPortChannelPolicyGroup_UniqueList

  name        = join("_",["VPC", "GLOBAL", each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "orchestrator:terraform"
  description = "Dual Homed Portchannel from Two ACI Nodes to Multiple NICs on Single Endpoint"
  lag_t       = "node"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id

  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }  
  
}

resource "aci_rest" "localAciRestGlobalVPCIntSelectIntPolAssocIteration" {
  for_each = local.GlobalVPCIntSelectIntPolAssoc_Map

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciPhysInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup["${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF

  depends_on = [
    aci_access_port_selector.localAciPhysInterfaceSelectorIteration,
    aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup
  ]

}

resource "aci_epg_to_static_path" "localAciGlobalVpcIntSelectEpgAssoc" {
  for_each            = local.GlobalVpcIntSelectEpgAssoc_List


  application_epg_dn  = data.aci_application_epg.dataLocalAciTenantApplicationEndpointGroupIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}.${each.value.VLAN_ID}"].id
  tdn  = "topology/pod-${each.value.ACI_POD_ID}/protpaths-${each.value.ODD_NODE_ID}-${each.value.EVEN_NODE_ID}/pathep-[${aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup["${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].name}]"
  annotation = "orchestrator:terraform"
  encap  = "vlan-${each.value.VLAN_ID}"
  instr_imedcy = "immediate"
  mode  = lower(each.value.DOT1Q_ENABLE) == "true" ? "regular" : "native"

  lifecycle {
    ignore_changes = [application_epg_dn]
  }  
   
}

######### L3 Out #########

resource "aci_leaf_access_bundle_policy_group" "localAciTenantExtVirtualPortChannelPolicyGroup" {
  for_each    = local.TenantExtVirtualPortChannelPolicyGroup_UniqueList

  name        = join("_",["VPC", each.value.TENANT_NAME, each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "orchestrator:terraform"
  description = "Dual Homed Portchannel from Two ACI Nodes to Multiple NICs on Single Endpoint"
  lag_t       = "node"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id
  
  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }       
  
}


resource "aci_rest" "localAciRestTenantExtVPCIntSelectIntPolAssocIteration" {
  for_each = local.TenantExtVPCIntSelectIntPolAssoc_Map

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciExtInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciTenantExtVirtualPortChannelPolicyGroup["${each.value.TENANT_NAME}.${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF

  depends_on = [
    aci_access_port_selector.localAciExtInterfaceSelectorIteration,
    aci_leaf_access_bundle_policy_group.localAciTenantExtVirtualPortChannelPolicyGroup
  ]  

}


resource "aci_leaf_access_bundle_policy_group" "localAciGlobalExtPhysVirtualPortChannelPolicyGroup" {
  for_each    = local.GlobalExtVirtualPortChannelPolicyGroup_UniqueList

  name        = join("_",["VPC", "GLOBAL", each.value.ENDPOINT_NAME, "BOND", each.value.BOND_GROUP, "INT_POL_GRP"])
  annotation  = "orchestrator:terraform"
  description = "Dual Homed Portchannel from Two ACI Nodes to Multiple NICs on Single Endpoint"
  lag_t       = "node"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id
  
  # LACP Policy:
  relation_infra_rs_lacp_pol = aci_lacp_policy.localAciLacpActivePolicy.id

  lifecycle {
    ignore_changes = [relation_infra_rs_att_ent_p]
  }  
  
}

resource "aci_rest" "localAciRestGlobalExtVPCIntSelectIntPolAssocIteration" {
  for_each = local.GlobalExtVPCIntSelectIntPolAssoc_Map

  path       = "/api/node/mo/uni/infra/accportprof-${data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].name}/hports-${aci_access_port_selector.localAciExtInterfaceSelectorIteration["${each.value.ACI_NODE_ID}.${each.value.ACI_NODE_SLOT}.${each.value.ACI_NODE_PORT}"].name}-typ-range/rsaccBaseGrp.json"
  payload = <<EOF
{
  "infraRsAccBaseGrp": {
    "attributes": {
      "tDn": "${aci_leaf_access_bundle_policy_group.localAciGlobalExtPhysVirtualPortChannelPolicyGroup["${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].id}",
      "status": "created,modified"
    },
    "children": []
  }
}
EOF

  depends_on = [
    aci_access_port_selector.localAciPhysInterfaceSelectorIteration,
    aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup
  ]

}

resource "aci_logical_node_profile" "localAciTenantNgfwL3OutNodeProfileIteration" {
  for_each    = local.TenantExtNodeProfNgfwExtEpgAssoc_List
  
  l3_outside_dn = data.aci_l3_outside.dataLocalAciTenantAppProfVrfL3OutProfNgfwIteration["${each.value.TENANT_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  description   = join(" ", ["Node Profile for", join("-", [each.value.ODD_NODE_ID, each.value.EVEN_NODE_ID]), "as specified by Terraform CICD pipeline."])
  name          = join("_", [join("-", [each.value.ODD_NODE_ID, each.value.EVEN_NODE_ID]), "NODE", "PROF"])
  annotation    = "orchestrator:terraform"
  target_dscp   = "unspecified"
  
  lifecycle {
    ignore_changes = [l3_outside_dn]
  }  
}

resource "aci_logical_interface_profile" "localAciTenantNgfwL3OutNodeProfIntProfIteration" {
  for_each    = local.TenantExtNodeProfNgfwExtEpgAssoc_List
  
  logical_node_profile_dn               = aci_logical_node_profile.localAciTenantNgfwL3OutNodeProfileIteration[each.key].id
  description                           = join(" ", ["Interface Profile for", join("-", [each.value.ODD_NODE_ID, each.value.EVEN_NODE_ID]), "as specified by Terraform CICD pipeline."])
  name                                  = join("_", [join("-", [each.value.ODD_NODE_ID, each.value.EVEN_NODE_ID]), "NODE", "INT", "PROF"])
  annotation                            = "orchestrator:terraform"
  prio                                  = "unspecified"
}


resource "aci_l3out_path_attachment" "localAciTenantNgfwL3OutNodeProfIntProfSviVpcPathIteration" {
  for_each  = local.TenantExtNodeProfNgfwPathAssoc_List

  logical_interface_profile_dn  = aci_logical_interface_profile.localAciTenantNgfwL3OutNodeProfIntProfIteration["${each.value.ODD_NODE_ID}.${each.value.EVEN_NODE_ID}.${each.value.ACI_POD_ID}.${each.value.TENANT_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  target_dn  = lower(each.value.MULTI_TENANT) == "true" ? "topology/pod-${each.value.ACI_POD_ID}/protpaths-${each.value.ODD_NODE_ID}-${each.value.EVEN_NODE_ID}/pathep-[${aci_leaf_access_bundle_policy_group.localAciGlobalExtPhysVirtualPortChannelPolicyGroup["${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].name}]" : null
  if_inst_t = "ext-svi"
  description = join(" ", ["Interface Configuration for", join("-", [each.value.ODD_NODE_ID, each.value.EVEN_NODE_ID]), "as specified by Terraform CICD pipeline."])
  annotation  = "orchestrator:terraform"
  autostate = "disabled"
  encap  = "vlan-${each.value.VLAN_ID}"
  encap_scope = "local"
  ipv6_dad = "disabled"
  ll_addr  = "::"
  mac  = "0F:0F:0F:0F:FF:FF"
  mode = "regular"
  mtu = "inherit"
  target_dscp = "unspecified"
}

resource "aci_l3out_vpc_member" "localAciTenantNgfwL3OutNodeProfIntProfSviVpcMemberAIteration" {
  for_each  = local.TenantExtNodeProfNgfwPathAssoc_List
  
  leaf_port_dn  = aci_l3out_path_attachment.localAciTenantNgfwL3OutNodeProfIntProfSviVpcPathIteration[each.key].id
  side  = "A"
  addr  = "${each.value.ODD_NODE_IP}"
  annotation  = "orchestrator:terraform"
  ipv6_dad = "disabled"
  ll_addr  = "::"
  description = join(" ", ["Interface Configuration for", each.value.ODD_NODE_ID, "as specified by Terraform CICD pipeline."])
}

resource "aci_l3out_vpc_member" "localAciTenantNgfwL3OutNodeProfIntProfSviVpcMemberBIteration" {
  for_each  = local.TenantExtNodeProfNgfwPathAssoc_List
  
  leaf_port_dn  = aci_l3out_path_attachment.localAciTenantNgfwL3OutNodeProfIntProfSviVpcPathIteration[each.key].id
  side  = "B"
  addr  = "${each.value.EVEN_NODE_IP}"
  annotation  = "orchestrator:terraform"
  ipv6_dad = "disabled"
  ll_addr  = "::"
  description = join(" ", ["Interface Configuration for", each.value.EVEN_NODE_ID, "as specified by Terraform CICD pipeline."])
}

resource "aci_l3out_path_attachment_secondary_ip" "localAciTenantNgfwL3OutNodeProfIntProfSviVpcSecIpAIteration" {
  for_each  = local.TenantExtNodeProfNgfwPathAssoc_List
  
  l3out_path_attachment_dn = aci_l3out_vpc_member.localAciTenantNgfwL3OutNodeProfIntProfSviVpcMemberAIteration[each.key].id
  addr                     = "${each.value.SECONDARY_IP}"
  annotation               = "orchestrator:terraform"
  description              = join(" ", ["Interface Configuration for", join("-", [each.value.ODD_NODE_ID, each.value.EVEN_NODE_ID]), "as specified by Terraform CICD pipeline."])
  ipv6_dad                 = "disabled"
  dhcp_relay               = "disabled"
}

resource "aci_l3out_path_attachment_secondary_ip" "localAciTenantNgfwL3OutNodeProfIntProfSviVpcSecIpBIteration" {
  for_each  = local.TenantExtNodeProfNgfwPathAssoc_List
  
  l3out_path_attachment_dn = aci_l3out_vpc_member.localAciTenantNgfwL3OutNodeProfIntProfSviVpcMemberBIteration[each.key].id
  addr                     = "${each.value.SECONDARY_IP}"
  annotation               = "orchestrator:terraform"
  description              = join(" ", ["Interface Configuration for", join("-", [each.value.ODD_NODE_ID, each.value.EVEN_NODE_ID]), "as specified by Terraform CICD pipeline."])
  ipv6_dad                 = "disabled"
  dhcp_relay               = "disabled"
}

resource "aci_logical_node_to_fabric_node" "localAciL3OutNodeProfFabOddNodeAssocIteration" {
  for_each    = local.TenantExtNodeProfNgfwFabNodeAssoc_List

  logical_node_profile_dn   = aci_logical_node_profile.localAciTenantNgfwL3OutNodeProfileIteration["${each.value.ODD_NODE_ID}.${each.value.EVEN_NODE_ID}.${each.value.ACI_POD_ID}.${each.value.TENANT_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  tdn                       = "topology/pod-${each.value.ACI_POD_ID}/node-${each.value.ODD_NODE_ID}"
  annotation                = "orchestrator:terraform"
  config_issues             = "none"
  rtr_id                    = "${each.value.ODD_NODE_IP}"
  rtr_id_loop_back          = "yes"  
}

resource "aci_logical_node_to_fabric_node" "localAciL3OutNodeProfFabEvenNodeAssocIteration" {
  for_each    = local.TenantExtNodeProfNgfwFabNodeAssoc_List

  logical_node_profile_dn   = aci_logical_node_profile.localAciTenantNgfwL3OutNodeProfileIteration["${each.value.ODD_NODE_ID}.${each.value.EVEN_NODE_ID}.${each.value.ACI_POD_ID}.${each.value.TENANT_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  tdn                       = "topology/pod-${each.value.ACI_POD_ID}/node-${each.value.EVEN_NODE_ID}"
  annotation                = "orchestrator:terraform"
  config_issues             = "none"
  rtr_id                    = "${each.value.EVEN_NODE_IP}"
  rtr_id_loop_back          = "yes"  
}