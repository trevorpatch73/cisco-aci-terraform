resource "aci_fabric_node_member" "localAciFabricNodeMemberIteration" {
  for_each    = local.FilteredSwitchRoleAciFabricNodeMembers

  name        = each.value.SWITCH_NAME          #STRING
  serial      = each.value.SWITCH_SERIAL_NUMBER #STRING
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = each.value.SNOW_RECORD #STRING
  ext_pool_id = "0"
  fabric_id   = "1"
  node_id     = each.value.SWITCH_NODE_ID #INT
  node_type   = "unspecified"
  pod_id      = each.value.SWITCH_POD_ID #INT
  role        = each.value.SWITCH_ROLE   #STRING: leaf/spine
}

resource "aci_leaf_interface_profile" "localAciFabricAccessLeafInterfaceProfileIteration" {
  for_each    = local.FilteredLeafRoleAciFabricNodeMembers

  name        = join("_", [each.value.SWITCH_NODE_ID, "INTPROF"]) #INT
  description = each.value.SNOW_RECORD                            #STRING
  annotation  = "ORCHESTRATOR:TERRAFORM"
}

resource "aci_access_switch_policy_group" "localAciFabricAccessLeafSwitchPolicyGroupIteration" {
  for_each    = local.FilteredLeafRoleAciFabricNodeMembers

  name        = join("_", [each.value.SWITCH_NODE_ID, "SWPOLGRP"]) #INT
  description = each.value.SNOW_RECORD                             #STRING
  annotation  = "ORCHESTRATOR:TERRAFORM"

  relation_infra_rs_bfd_ipv4_inst_pol                    = "uni/infra/bfdIpv4Inst-default"
  relation_infra_rs_bfd_ipv6_inst_pol                    = "uni/infra/bfdIpv6Inst-default"
  relation_infra_rs_bfd_mh_ipv4_inst_pol                 = "uni/infra/bfdMhIpv4Inst-default"
  relation_infra_rs_bfd_mh_ipv6_inst_pol                 = "uni/infra/bfdMhIpv6Inst-default"
  relation_infra_rs_equipment_flash_config_pol           = "uni/infra/flashconfigpol-default"
  relation_infra_rs_fc_fabric_pol                        = "uni/infra/fcfabricpol-default"
  relation_infra_rs_fc_inst_pol                          = "uni/infra/fcinstpol-default"
  relation_infra_rs_iacl_leaf_profile                    = "uni/infra/iaclleafp-default"
  relation_infra_rs_l2_node_auth_pol                     = "uni/infra/nodeauthpol-default"
  relation_infra_rs_leaf_copp_profile                    = "uni/infra/coppleafp-default"
  relation_infra_rs_leaf_p_grp_to_cdp_if_pol             = "uni/infra/cdpIfP-default"
  relation_infra_rs_leaf_p_grp_to_lldp_if_pol            = "uni/infra/lldpIfP-default"
  relation_infra_rs_mon_node_infra_pol                   = "uni/infra/moninfra-default"
  relation_infra_rs_mst_inst_pol                         = "uni/infra/mstpInstPol-default"
  relation_infra_rs_poe_inst_pol                         = "uni/infra/poeInstP-default"
  relation_infra_rs_topoctrl_fast_link_failover_inst_pol = "uni/infra/fastlinkfailoverinstpol-default"
  relation_infra_rs_topoctrl_fwd_scale_prof_pol          = "uni/infra/fwdscalepol-default"
}

resource "aci_leaf_profile" "localAciFabricAccessLeafSwitchProfileIteration" {
  for_each    = local.FilteredLeafRoleAciFabricNodeMembers

  name                         = join("_", [each.value.SWITCH_NODE_ID, "SWPROF"]) #INT
  description                  = each.value.SNOW_RECORD                           #STRING
  annotation                   = "ORCHESTRATOR:TERRAFORM"

  leaf_selector {
    name                       = join("_", [each.value.SWITCH_NODE_ID, "LFSEL"])  #INT
    switch_association_type    = "range"
    node_block {
      name                     = join("_", ["blk", each.value.SWITCH_NODE_ID])
      from_                    = each.value.SWITCH_NODE_ID
      to_                      = each.value.SWITCH_NODE_ID
    }
  }

  relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.localAciFabricAccessLeafInterfaceProfileIteration[each.key].id]
}

resource "aci_rest" "localAciRestLeafSWPROFAssocSWPOLGRP" {
  for_each = local.TriggerlocalAciRestLeafSWPROFAssocSWPOLGRP

  path    = "/api/node/mo/uni/infra/nprof-${each.value.SWITCH_NODE_ID}_SWPROF/leaves-${each.value.SWITCH_NODE_ID}_LFSEL-typ-range.json"
  payload = <<EOF
{
  "infraLeafS": {
    "attributes": {
      "dn": "uni/infra/nprof-${each.value.SWITCH_NODE_ID}_SWPROF/leaves-${each.value.SWITCH_NODE_ID}_LFSEL-typ-range"
    },
    "children": [
      {
        "infraRsAccNodePGrp": {
          "attributes": {
            "tDn": "uni/infra/funcprof/accnodepgrp-${each.value.SWITCH_NODE_ID}_SWPOLGRP",
            "status": "created"
          },
          "children": []
        }
      }
    ]
  }
}
EOF

  depends_on = [
    aci_leaf_profile.localAciFabricAccessLeafSwitchProfileIteration,
    aci_access_switch_policy_group.localAciFabricAccessLeafSwitchPolicyGroupIteration
  ]
}

resource "aci_vpc_explicit_protection_group" "localAciVpcExplictProtectionGroupIteration" {
  for_each                          = local.UniqueVpcPeerGroupId

  name                              = join("_", [each.key, "VEPG"]) #INT
  annotation                        = "ORCHESTRATOR:TERRAFORM"
  switch1                           = split("-", each.key)[0]
  switch2                           = split("-", each.key)[1]
  vpc_domain_policy                 = "default"
  vpc_explicit_protection_group_id  = tostring(local.IndexConvertUniqueVpcPeerGroupId[each.key])
}

/*

# THESE ITEMS ARE COMMENTED OUT DUE TO THE PREFERENCE OF A DESIGN ENABLING
# VPCS TO ALLOCATE TWO DIFFERENT SWITCHPORTS/INTERFACE SELECTORS
# ON TWO DIFFERENT SWITCHES; WHICH IS CONSTRAINTED BY THE COMBINED
# METHODOLOGY THE CODE THAT FOLLOWS DEPLOYS AS BEST PRACTICE

resource "aci_leaf_interface_profile" "localAciFabricAccessLeafVPCInterfaceProfileIteration" {
  for_each   = local.UniqueVpcPeerGroupId

  name       = join("_", [each.key, "INTPROF"]) #INT
  annotation = "ORCHESTRATOR:TERRAFORM"
}

resource "aci_leaf_profile" "localAciFabricAccessLeafVPCSwitchProfileIteration" {
  for_each                     = local.UniqueVpcPeerGroupId

  name                         = join("_", [each.key, "SWPROF"]) #INT
  annotation                   = "ORCHESTRATOR:TERRAFORM"

  leaf_selector {
    name                       = join("_", [each.key, "LFSEL"])  #INT
    switch_association_type    = "range"
    node_block {
      name                     = "blk1"
      from_                    = split("-", each.key)[0]         #INT 
      to_                      = split("-", each.key)[1]         #INT
    }
  }

  relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.localAciFabricAccessLeafVPCInterfaceProfileIteration[each.key].id]
}

*/