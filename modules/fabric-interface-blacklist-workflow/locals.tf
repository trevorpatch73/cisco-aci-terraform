locals {
  fabric_interface_blacklist_iterations = csvdecode(file("./data/fabric-interface-blacklist.csv"))

  AciFabricInterfaceBlacklist = {
    for fabric_interface_blacklist_iteration in local.fabric_interface_blacklist_iterations : "${fabric_interface_blacklist_iteration.SWITCH_NODE_ID}.${fabric_interface_blacklist_iteration.SWITCH_FEX_ID}.${fabric_interface_blacklist_iteration.SWITCH_INTERFACE_ID}" => {
      SWITCH_NAME         = fabric_interface_blacklist_iteration.SWITCH_NAME
      SWITCH_POD_ID       = fabric_interface_blacklist_iteration.SWITCH_POD_ID
      SWITCH_NODE_ID      = fabric_interface_blacklist_iteration.SWITCH_NODE_ID
      SWITCH_FEX_ID       = fabric_interface_blacklist_iteration.SWITCH_FEX_ID
      SWITCH_INTERFACE_ID = fabric_interface_blacklist_iteration.SWITCH_INTERFACE_ID
      SNOW_RECORD         = fabric_interface_blacklist_iteration.SNOW_RECORD
    }
  }

  FilteredAciFabricInterfaceBlacklist = {
    for key, value in local.AciFabricInterfaceBlacklist : key => value
    if value.SWITCH_FEX_ID == "0"
  }

  FilteredAciFabricFexInterfaceBlacklist = {
    for key, value in local.AciFabricInterfaceBlacklist : key => value
    if value.SWITCH_FEX_ID != "0"
  }

}