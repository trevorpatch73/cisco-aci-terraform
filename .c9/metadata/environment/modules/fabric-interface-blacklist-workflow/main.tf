{"filter":false,"title":"main.tf","tooltip":"/modules/fabric-interface-blacklist-workflow/main.tf","undoManager":{"mark":0,"position":0,"stack":[[{"start":{"row":0,"column":0},"end":{"row":19,"column":1},"action":"insert","lines":["resource \"aci_interface_blacklist\" \"localAciFabricInterfaceBlacklist\" {","  for_each    = local.FilteredAciFabricInterfaceBlacklist","","  annotation  = \"ORCHESTRATOR:TERRAFORM\"","  pod_id      = each.value.SWITCH_POD_ID        #INT","  node_id     = each.value.SWITCH_NODE_ID       #INT","  interface   = each.value.SWITCH_INTERFACE_ID  #STRING","","}","","resource \"aci_interface_blacklist\" \"localAciFabricFexInterfaceBlacklist\" {","  for_each    = local.FilteredAciFabricFexInterfaceBlacklist","","  annotation  = \"ORCHESTRATOR:TERRAFORM\"","  pod_id      = each.value.SWITCH_POD_ID        #INT","  node_id     = each.value.SWITCH_NODE_ID       #INT","  fex_id      = each.value.SWITCH_FEX_ID        #INT ","  interface   = each.value.SWITCH_INTERFACE_ID  #STRING","","}"],"id":1}]]},"ace":{"folds":[],"scrolltop":0,"scrollleft":0,"selection":{"start":{"row":19,"column":1},"end":{"row":19,"column":1},"isBackwards":false},"options":{"guessTabSize":true,"useWrapMode":false,"wrapToView":true},"firstLineState":0},"timestamp":1697739072212,"hash":"7bd78eb2e53920ba7fe6d48c39afc7edfbbd68fc"}