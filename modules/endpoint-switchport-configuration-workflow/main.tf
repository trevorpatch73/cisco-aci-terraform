######### DEPENDENCIES #########
resource "null_resource" "AutogenEndpointVpcConfigPython" {
  provisioner "local-exec" {
    command     = "python3 autogen-endpoint-vpc-config.py"
    working_dir = "${path.root}/scripts"
  }

  triggers = {
    csv_hash = filemd5("${path.root}/data/endpoint-switchport-configuration.csv")
  }
}

data "local_file" "localFileAutogenTenantEndpointVpcConfigPython" {
  filename   = "./data/autogen-tenant-endpoint-vpc-config.csv"
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
}

data "local_file" "localFileAutogenGlobalEndpointVpcConfigPython" {
  filename   = "./data/autogen-global-endpoint-vpc-config.csv"
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
}

######### IMPORTS #########

data "aci_attachable_access_entity_profile" "dataLocalAciAttachableEntityProfileIteration" {
    for_each = local.distinct_tenants
    
    name  = join("_", [each.value, "AAEP"])
    
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
}

data "aci_attachable_access_entity_profile" "dataLocalAciGobalAAEP" {
    name  = "GLOBAL_AAEP"
    
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
}

data "aci_leaf_interface_profile" "dataLocalAciFabricAccessLeafInterfaceProfileIteration" {
  for_each  = local.distinct_switch_nodes
  
  name      = join("_", [each.value, "INTPROF"])
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
}

data "aci_tenant" "dataLocalAciTenantIteration" {
  for_each = local.distinct_tenants
    
  name     = each.value
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]  
}

data "aci_application_profile" "dataLocalAciTenantApplicationProfileIteration" {
  for_each   = local.AppProf_Map
  
  tenant_dn  = data.aci_tenant.dataLocalAciTenantIteration["${each.value.TENANT_NAME}"].id
  name       = each.value.MACRO_SEGMENTATION_ZONE
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]  
}

data "aci_application_epg" "dataLocalAciTenantApplicationEndpointGroupIteration" {
  for_each   = local.AppEpg_Map
  
  application_profile_dn  = data.aci_application_profile.dataLocalAciTenantApplicationProfileIteration["${each.value.TENANT_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  name                    = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "aEPG"])
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]  
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
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]  
}

######### GLOBAL #########

resource "aci_access_port_selector" "localAciPhysInterfaceSelectorIteration" {
  for_each                  = local.PhysInterfaceSelectors_UniqueList
  
  leaf_interface_profile_dn = data.aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration[each.value.ACI_NODE_ID].id
  name                      = join("_", ["Eth", each.value.ACI_NODE_SLOT, each.value.ACI_NODE_PORT])
  access_port_selector_type = "range"
  annotation                = "ORCHESTRATOR:TERRAFORM"

  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
  
  lifecycle {
    ignore_changes = [relation_infra_rs_acc_base_grp]
  }  
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

  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
  
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

  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]

}

######### NONBOND L2 PORTS #########

resource "aci_leaf_access_port_policy_group" "localAciTenantPhysAccessPortPolicyGroupIteration" {
  for_each    = local.TenantAccessPortPolicyGroup_UniqueList
  
  name        = join("_",[each.value.TENANT_NAME, each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "INT_POL_GRP"])
  description = join(" ",["Affects all", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "interface policy settings within tenant", each.value.TENANT_NAME])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  
  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration[each.value.TENANT_NAME].id

  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]
  
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
    aci_leaf_access_port_policy_group.localAciTenantPhysAccessPortPolicyGroupIteration,
    null_resource.AutogenEndpointVpcConfigPython
  ]  

}

resource "aci_leaf_access_port_policy_group" "localAciGlobalPhysAccessPortPolicyGroupIteration" {
  for_each    = local.GlobalAccessPortPolicyGroup_UniqueList
  
  name        = join("_",["GLOBAL", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "INT_POL_GRP"])
  description = join(" ",["Affects all", each.value.ENDPOINT_MAKE, each.value.ENDPOINT_MODEL, each.value.ENDPOINT_OS, "interface policy settings across the entire fabric."])
  annotation  = "ORCHESTRATOR:TERRAFORM"

  #Attachable Access Entity Profile:
  relation_infra_rs_att_ent_p   = data.aci_attachable_access_entity_profile.dataLocalAciGobalAAEP.id
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]  
  
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

  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ] 

}

resource "aci_epg_to_static_path" "PhysNonBondIntSelectAppEpgStaticBindIteration" {
  for_each   = local.PhysNonBondIntSelectAppEpgStaticBind_Map

  application_epg_dn  = data.aci_application_epg.dataLocalAciTenantApplicationEndpointGroupIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}.${each.value.VLAN_ID}"].id
  tdn  = "topology/pod-${each.value.ACI_POD_ID}/paths-${each.value.ACI_NODE_ID}/pathep-[eth${each.value.ACI_NODE_SLOT}/${each.value.ACI_NODE_PORT}]"
  annotation = "ORCHESTRATOR:TERRAFORM"
  encap  = "vlan-${each.value.VLAN_ID}"
  instr_imedcy = "immediate"
  mode  = lower(each.value.DOT1Q_ENABLE) == "true" ? "regular" : "native"
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]   
  
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
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]   
  
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
    aci_leaf_access_bundle_policy_group.localAciTenantPhysPortChannelPolicyGroup,
    null_resource.AutogenEndpointVpcConfigPython
  ]  

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
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]  
  
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
    aci_leaf_access_bundle_policy_group.localAciGlobalPhysPortChannelPolicyGroup,
    null_resource.AutogenEndpointVpcConfigPython
  ]  

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
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]    
  
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
    aci_leaf_access_bundle_policy_group.localAciTenantPhysVirtualPortChannelPolicyGroup,
    null_resource.AutogenEndpointVpcConfigPython
  ]  

}

resource "aci_epg_to_static_path" "localAciTenantVpcIntSelectEpgAssoc" {
  for_each            = local.TenantVpcIntSelectEpgAssoc_List


  application_epg_dn  = data.aci_application_epg.dataLocalAciTenantApplicationEndpointGroupIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}.${each.value.VLAN_ID}"].id
  tdn  = "topology/pod-${each.value.ACI_POD_ID}/protpaths-${each.value.ODD_NODE_ID}-${each.value.EVEN_NODE_ID}/pathep-[${aci_leaf_access_bundle_policy_group.localAciTenantPhysVirtualPortChannelPolicyGroup["${each.value.TENANT_NAME}.${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].name}]"
  annotation = "ORCHESTRATOR:TERRAFORM"
  encap  = "vlan-${each.value.VLAN_ID}"
  instr_imedcy = "immediate"
  mode  = lower(each.value.DOT1Q_ENABLE) == "true" ? "regular" : "native"
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython,
    data.local_file.localFileAutogenTenantEndpointVpcConfigPython
  ]   
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
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython
  ]    
  
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
    aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup,
    null_resource.AutogenEndpointVpcConfigPython
  ]

}

resource "aci_epg_to_static_path" "localAciGlobalVpcIntSelectEpgAssoc" {
  for_each            = local.GlobalVpcIntSelectEpgAssoc_List


  application_epg_dn  = data.aci_application_epg.dataLocalAciTenantApplicationEndpointGroupIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}.${each.value.VLAN_ID}"].id
  tdn  = "topology/pod-${each.value.ACI_POD_ID}/protpaths-${each.value.ODD_NODE_ID}-${each.value.EVEN_NODE_ID}/pathep-[${aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup["${each.value.ENDPOINT_NAME}.${each.value.BOND_GROUP}"].name}]"
  annotation = "ORCHESTRATOR:TERRAFORM"
  encap  = "vlan-${each.value.VLAN_ID}"
  instr_imedcy = "immediate"
  mode  = lower(each.value.DOT1Q_ENABLE) == "true" ? "regular" : "native"
  
  depends_on = [
    null_resource.AutogenEndpointVpcConfigPython,
    data.local_file.localFileAutogenGlobalEndpointVpcConfigPython
  ]   
}