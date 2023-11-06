{"filter":false,"title":"locals.tf","tooltip":"/modules/fabric-interface-blacklist-workflow/locals.tf","undoManager":{"mark":3,"position":3,"stack":[[{"start":{"row":0,"column":0},"end":{"row":24,"column":1},"action":"insert","lines":["locals {","  fabric_interface_blacklist_iterations = csvdecode(file(\"./data/fabric-interface-blacklist.csv\"))","","  AciFabricInterfaceBlacklist = {","    for fabric_interface_blacklist_iteration in local.fabric_interface_blacklist_iterations : \"${fabric_interface_blacklist_iteration.SWITCH_NODE_ID}.${fabric_interface_blacklist_iteration.SWITCH_FEX_ID}.${fabric_interface_blacklist_iteration.SWITCH_INTERFACE_ID}\" => {","      SWITCH_NAME          = fabric_interface_blacklist_iteration.SWITCH_NAME","      SWITCH_POD_ID        = fabric_interface_blacklist_iteration.SWITCH_POD_ID","      SWITCH_NODE_ID       = fabric_interface_blacklist_iteration.SWITCH_NODE_ID","      SWITCH_FEX_ID        = fabric_interface_blacklist_iteration.SWITCH_FEX_ID","      SWITCH_INTERFACE_ID  = fabric_interface_blacklist_iteration.SWITCH_INTERFACE_ID","      SNOW_RECORD          = fabric_interface_blacklist_iteration.SNOW_RECORD","    }","  }","","  FilteredAciFabricInterfaceBlacklist = {","    for key, value in local.AciFabricInterfaceBlacklist : key => value","    if value.SWITCH_FEX_ID == \"0\"","  }","","FilteredAciFabricFexInterfaceBlacklist = {","    for key, value in local.AciFabricInterfaceBlacklist : key => value","    if value.SWITCH_FEX_ID != \"0\"","  }","","}"],"id":1}],[{"start":{"row":19,"column":0},"end":{"row":19,"column":4},"action":"insert","lines":["    "],"id":2}],[{"start":{"row":19,"column":0},"end":{"row":19,"column":4},"action":"remove","lines":["    "],"id":3}],[{"start":{"row":19,"column":0},"end":{"row":19,"column":1},"action":"insert","lines":[" "],"id":4}]]},"ace":{"folds":[],"scrolltop":0,"scrollleft":0,"selection":{"start":{"row":0,"column":0},"end":{"row":24,"column":1},"isBackwards":true},"options":{"guessTabSize":true,"useWrapMode":false,"wrapToView":true},"firstLineState":0},"timestamp":1697739051340,"hash":"602162153e17cf3f224c53523024cf253a6db168"}