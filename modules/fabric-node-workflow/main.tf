resource "aci_fabric_node_member" "localAciFabricNodeMemberIteration" {
  for_each    = local.FilteredSwitchRoleAciFabricNodeMembers

  name        = each.value.SWITCH_NAME            #STRING
  serial      = each.value.SWITCH_SERIAL_NUMBER   #STRING
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = each.value.SNOW_RECORD            #STRING
  ext_pool_id = "0"
  fabric_id   = "1"
  node_id     = each.value.SWITCH_NODE_ID         #INT
  node_type   = "unspecified"                     
  pod_id      = each.value.SWITCH_POD_ID          #INT
  role        = each.value.SWITCH_ROLE            #STRING: leaf/spine
}

resource "aci_leaf_interface_profile" "localAciFabricAccessLeafInterfaceProfileIteration" {
  for_each    = local.FilteredLeafRoleAciFabricNodeMembers

  name        = join("_", [each.value.SWITCH_NODE_ID, "INTPROF"])   #INT
  description = each.value.SNOW_RECORD                              #STRING
  annotation  = "ORCHESTRATOR:TERRAFORM"
}

resource "aci_leaf_profile" "localAciFabricAccessLeafSwitchProfileIteration" {
  for_each    = local.FilteredLeafRoleAciFabricNodeMembers

  name        = join("_", [each.value.SWITCH_NODE_ID, "SWPROF"])                 #INT
  description = each.value.SNOW_RECORD                                           #STRING
  annotation  = "ORCHESTRATOR:TERRAFORM"

  leaf_selector {
    name                    = join("_", [each.value.SWITCH_NODE_ID, "LFSEL"])    #INT
    switch_association_type = "range"
    node_block {
      name  = "blk1"
      from_ = each.value.SWITCH_NODE_ID
      to_   = each.value.SWITCH_NODE_ID
    }
  }
  
  relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.localAciFabricAccessLeafInterfaceProfileIteration[each.key].id]
}

resource "aci_leaf_interface_profile" "localAciFabricAccessLeafVPCInterfaceProfileIteration" {
  for_each    = local.UniqueVpcPeerGroupId

  name        = join("_", [each.key, "INTPROF"])   #INT
  annotation  = "ORCHESTRATOR:TERRAFORM"
}

resource "aci_leaf_profile" "localAciFabricAccessLeafVPCSwitchProfileIteration" {
  for_each    = local.UniqueVpcPeerGroupId
  
  name        = join("_", [each.key, "SWPROF"])                 #INT
  annotation  = "ORCHESTRATOR:TERRAFORM"

  leaf_selector {
    name                    = join("_", [each.key, "LFSEL"])    #INT
    switch_association_type = "range"
    node_block {
      name  = "blk1"
      from_ = split("-", each.key)[0]       #INT 
      to_   = split("-", each.key)[1]       #INT
    }
  }
  
  relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.localAciFabricAccessLeafVPCInterfaceProfileIteration[each.key].id]
}
