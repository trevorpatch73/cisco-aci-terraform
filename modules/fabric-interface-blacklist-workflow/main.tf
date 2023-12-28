resource "aci_interface_blacklist" "localAciFabricInterfaceBlacklist" {
  for_each = local.FilteredAciFabricInterfaceBlacklist

  annotation = "ORCHESTRATOR:TERRAFORM"
  pod_id     = each.value.SWITCH_POD_ID       #INT
  node_id    = each.value.SWITCH_NODE_ID      #INT
  interface  = each.value.SWITCH_INTERFACE_ID #STRING

}

resource "aci_interface_blacklist" "localAciFabricFexInterfaceBlacklist" {
  for_each = local.FilteredAciFabricFexInterfaceBlacklist

  annotation = "ORCHESTRATOR:TERRAFORM"
  pod_id     = each.value.SWITCH_POD_ID       #INT
  node_id    = each.value.SWITCH_NODE_ID      #INT
  fex_id     = each.value.SWITCH_FEX_ID       #INT 
  interface  = each.value.SWITCH_INTERFACE_ID #STRING

}