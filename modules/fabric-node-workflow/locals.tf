locals {
  fabric_node_membership_iterations = csvdecode(file("./data/fabric-node-membership.csv"))

  AciFabricNodeMembers = {
    for fabric_node_membership_iteration in local.fabric_node_membership_iterations : fabric_node_membership_iteration.SWITCH_SERIAL_NUMBER => {
      ACI_REST_TRIGGER     = lower(fabric_node_membership_iteration.ACI_REST_TRIGGER)
      SWITCH_NAME          = fabric_node_membership_iteration.SWITCH_NAME
      SWITCH_SERIAL_NUMBER = fabric_node_membership_iteration.SWITCH_SERIAL_NUMBER
      SWITCH_ROLE          = fabric_node_membership_iteration.SWITCH_ROLE
      SWITCH_POD_ID        = fabric_node_membership_iteration.SWITCH_POD_ID
      SWITCH_NODE_ID       = fabric_node_membership_iteration.SWITCH_NODE_ID
      VPC_PEER_GROUP       = fabric_node_membership_iteration.VPC_PEER_GROUP
      NODE_MGMT_ADDR       = fabric_node_membership_iteration.NODE_MGMT_ADDR
      NODE_MGMT_GW         = fabric_node_membership_iteration.NODE_MGMT_GW
      SNOW_RECORD          = fabric_node_membership_iteration.SNOW_RECORD
    }
  }

  FilteredSwitchRoleAciFabricNodeMembers = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "leaf" || value.SWITCH_ROLE == "spine"
  }

  FilteredLeafRoleAciFabricNodeMembers = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "leaf"
  }

  FilteredOddSpines = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "spine" && tonumber(value.SWITCH_NODE_ID) % 2 == 1
  }

  FilteredEvenSpines = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "spine" && tonumber(value.SWITCH_NODE_ID) % 2 == 0
  }

  FilteredOddLeafs = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "leaf" && tonumber(value.SWITCH_NODE_ID) % 2 == 1
  }

  FilteredEvenLeafs = {
    for key, value in local.AciFabricNodeMembers : key => value
    if value.SWITCH_ROLE == "leaf" && tonumber(value.SWITCH_NODE_ID) % 2 == 0
  }

  UniqueVpcPeerGroupId = toset(distinct([for value in local.FilteredLeafRoleAciFabricNodeMembers : value.VPC_PEER_GROUP]))

  ConvertUniqueVpcPeerGroupId = tolist(local.UniqueVpcPeerGroupId)

  IndexConvertUniqueVpcPeerGroupId = {
    for idx, group_id in local.ConvertUniqueVpcPeerGroupId : group_id => idx + 1
  }

  TriggerlocalAciRestLeafSWPROFAssocSWPOLGRP = {
    for key, value in local.FilteredLeafRoleAciFabricNodeMembers : key => value
    if value.ACI_REST_TRIGGER == "true"
  }


  contract_node_oob_mgmt_rule_iterations = csvdecode(file("./data/contract-node-oob-mgmt_rules.csv"))

  AciNodeOobMgmtRules = {
    for contract_node_oob_mgmt_rule_iteration in local.contract_node_oob_mgmt_rule_iterations : contract_node_oob_mgmt_rule_iteration.RULE_NAME => {
      SNOW_RECORD = contract_node_oob_mgmt_rule_iteration.SNOW_RECORD
      RULE_NAME   = contract_node_oob_mgmt_rule_iteration.RULE_NAME
      PROTOCOL    = lower(contract_node_oob_mgmt_rule_iteration.PROTOCOL)
      PORT        = contract_node_oob_mgmt_rule_iteration.PORT
    }
  }

  FilteredProtocolTcpUdp = {
    for key, value in local.AciNodeOobMgmtRules : key => value
    if value.PROTOCOL == "tcp" || value.PROTOCOL == "udp"
  }

  FilteredProtocolIcmp = {
    for key, value in local.AciNodeOobMgmtRules : key => value
    if value.PROTOCOL == "icmp"
  }

}