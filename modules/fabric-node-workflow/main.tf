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