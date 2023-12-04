locals {
  fabric_node_membership_iterations = csvdecode(file("./data/fabric-node-membership.csv"))

  AciFabricNodeMembers = {
    for fabric_node_membership_iteration in local.fabric_node_membership_iterations : fabric_node_membership_iteration.SWITCH_SERIAL_NUMBER => {
      SWITCH_NAME          = fabric_node_membership_iteration.SWITCH_NAME
      SWITCH_SERIAL_NUMBER = fabric_node_membership_iteration.SWITCH_SERIAL_NUMBER
      SWITCH_ROLE          = fabric_node_membership_iteration.SWITCH_ROLE
      SWITCH_POD_ID        = fabric_node_membership_iteration.SWITCH_POD_ID
      SWITCH_NODE_ID       = fabric_node_membership_iteration.SWITCH_NODE_ID
      VPC_PEER_GROUP       = fabric_node_membership_iteration.VPC_PEER_GROUP
      SNOW_RECORD          = fabric_node_membership_iteration.SNOW_RECORD
    }
  }

  FilteredSwitchRoleAciFabricNodeMembers = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "leaf" ||  value.SWITCH_ROLE == "spine"
  }
  
  FilteredLeafRoleAciFabricNodeMembers = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "leaf"
  }
  
  UniqueVpcPeerGroupId = toset(distinct([for value in local.FilteredLeafRoleAciFabricNodeMembers : value.VPC_PEER_GROUP]))
  
}