{"filter":false,"title":"main.tf","tooltip":"/modules/fabric-node-workflow/main.tf","undoManager":{"mark":0,"position":0,"stack":[[{"start":{"row":0,"column":0},"end":{"row":13,"column":1},"action":"insert","lines":["resource \"aci_fabric_node_member\" \"localAciFabricNodeMemberIteration\" {","  for_each    = local.FilteredSwitchRoleAciFabricNodeMembers","","  name        = each.value.SWITCH_NAME            #STRING","  serial      = each.value.SWITCH_SERIAL_NUMBER   #STRING","  annotation  = \"ORCHESTRATOR:TERRAFORM\"","  description = each.value.SNOW_RECORD            #STRING","  ext_pool_id = \"0\"","  fabric_id   = \"1\"","  node_id     = each.value.SWITCH_NODE_ID         #INT","  node_type   = \"unspecified\"                     ","  pod_id      = each.value.SWITCH_POD_ID          #INT","  role        = each.value.SWITCH_ROLE            #STRING: leaf/spine","}"],"id":1}]]},"ace":{"folds":[],"scrolltop":0,"scrollleft":0,"selection":{"start":{"row":0,"column":0},"end":{"row":13,"column":1},"isBackwards":true},"options":{"guessTabSize":true,"useWrapMode":false,"wrapToView":true},"firstLineState":0},"timestamp":1697566674987,"hash":"e3fcaffa2ffd9530890de8a52d70abcb5737886c"}