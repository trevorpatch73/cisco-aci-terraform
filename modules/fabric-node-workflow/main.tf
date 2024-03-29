resource "aci_fabric_node_member" "localAciFabricNodeMemberIteration" {
  for_each = local.FilteredSwitchRoleAciFabricNodeMembers

  name        = each.value.SWITCH_NAME          #STRING
  serial      = each.value.SWITCH_SERIAL_NUMBER #STRING
  annotation  = "orchestrator:terraform"
  description = each.value.SNOW_RECORD #STRING
  ext_pool_id = "0"
  fabric_id   = "1"
  node_id     = each.value.SWITCH_NODE_ID #INT
  node_type   = "unspecified"
  pod_id      = each.value.SWITCH_POD_ID #INT
  role        = each.value.SWITCH_ROLE   #STRING: leaf/spine
}

resource "aci_leaf_interface_profile" "localAciFabricAccessLeafInterfaceProfileIteration" {
  for_each = local.FilteredLeafRoleAciFabricNodeMembers

  name        = join("_", [each.value.SWITCH_NODE_ID, "INTPROF"]) #INT
  description = each.value.SNOW_RECORD                            #STRING
  annotation  = "orchestrator:terraform"
}

resource "aci_access_switch_policy_group" "localAciFabricAccessLeafSwitchPolicyGroupIteration" {
  for_each = local.FilteredLeafRoleAciFabricNodeMembers

  name        = join("_", [each.value.SWITCH_NODE_ID, "SWPOLGRP"]) #INT
  description = each.value.SNOW_RECORD                             #STRING
  annotation  = "orchestrator:terraform"

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
  for_each = local.FilteredLeafRoleAciFabricNodeMembers

  name        = join("_", [each.value.SWITCH_NODE_ID, "SWPROF"]) #INT
  description = each.value.SNOW_RECORD                           #STRING
  annotation  = "orchestrator:terraform"

  leaf_selector {
    name                    = join("_", [each.value.SWITCH_NODE_ID, "LFSEL"]) #INT
    switch_association_type = "range"
    node_block {
      name  = join("_", ["blk", each.value.SWITCH_NODE_ID])
      from_ = each.value.SWITCH_NODE_ID
      to_   = each.value.SWITCH_NODE_ID
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

resource "aci_vpc_domain_policy" "localAciVpcDomainPolicyIteration" {
  for_each = local.UniqueVpcPeerGroupId

  name       = join("_", [each.key, "VDP"]) #INT
  annotation = "orchestrator:terraform"
  dead_intvl = "200" #Default:200
}

resource "aci_vpc_explicit_protection_group" "localAciVpcExplictProtectionGroupIteration" {
  for_each = local.UniqueVpcPeerGroupId

  name                             = join("_", [each.key, "VEPG"]) #INT
  annotation                       = "orchestrator:terraform"
  switch1                          = split("-", each.key)[0]
  switch2                          = split("-", each.key)[1]
  vpc_domain_policy                = aci_vpc_domain_policy.localAciVpcDomainPolicyIteration[each.key].name
  vpc_explicit_protection_group_id = tostring(local.IndexConvertUniqueVpcPeerGroupId[each.key])
}

resource "aci_static_node_mgmt_address" "localAciStaticNodeMgmtAddrIteration" {
  for_each = local.FilteredSwitchRoleAciFabricNodeMembers

  management_epg_dn = aci_node_mgmt_epg.localAciNodeMgmtOobEPG.id
  t_dn              = "topology/pod-${aci_fabric_node_member.localAciFabricNodeMemberIteration[each.key].pod_id}/node-${aci_fabric_node_member.localAciFabricNodeMemberIteration[each.key].node_id}"
  type              = "out_of_band"
  description       = each.value.SNOW_RECORD #STRING
  addr              = each.value.NODE_MGMT_ADDR
  annotation        = "orchestrator:terraform"
  gw                = each.value.NODE_MGMT_GW
}

resource "aci_node_mgmt_epg" "localAciNodeMgmtOobEPG" {
  type                       = "out_of_band"
  management_profile_dn      = "uni/tn-mgmt/mgmtp-default"
  description                = "Author: Trevor Patch, Terraform Managed Node Out-of-Band Endpoint Group."
  name                       = "TF_MGD_NODE_OOB_EPG"
  annotation                 = "orchestrator:terraform"
  relation_mgmt_rs_oo_b_prov = [aci_rest_managed.localAciNodeMgmtOobCtr.dn]
}

resource "aci_rest_managed" "localAciNodeMgmtOobCtr" {
  dn         = "uni/tn-mgmt/oobbrc-TF_MGD_NODE_OOB_CTR"
  class_name = "vzOOBBrCP"
  content = {
    name  = "TF_MGD_NODE_OOB_CTR"
    descr = "Author: Trevor Patch, Terraform Managed Node Out-of-Band Interface Contract."
    #annotation = "orchestrator:terraform" #commented this out because it greated noise - Trevor Patch
    intent     = "install"
    prio       = "unspecified"
    scope      = "context"
    targetDscp = "unspecified"
  }
}

resource "aci_contract_subject" "localAciNodeMgmtOobCtrSubj" {
  contract_dn   = aci_rest_managed.localAciNodeMgmtOobCtr.id
  description   = "Author: Trevor Patch, Terraform Managed Node Out-of-Band Interface Contract Subject."
  name          = "TF_MGD_NODE_OOB_CTR_SUBJ"
  annotation    = "orchestrator:terraform"
  rev_flt_ports = "yes"
}

data "aci_tenant" "dataLocalAciTenantMgmt" {
  name = "mgmt"
}

resource "aci_filter" "localAciNodeMgmtOobCtrSubjFilt" {
  tenant_dn   = data.aci_tenant.dataLocalAciTenantMgmt.id
  description = "Author: Trevor Patch, Terraform Managed Node Out-of-Band Interface Contract Subject Filter."
  name        = "TF_MGD_NODE_OOB_CTR_SUBJ_FILT"
  annotation  = "orchestrator:terraform"
}

resource "aci_contract_subject_filter" "localAciNodeMgmtOobCtrSubjFiltAssoc" {
  contract_subject_dn = aci_contract_subject.localAciNodeMgmtOobCtrSubj.id
  filter_dn           = aci_filter.localAciNodeMgmtOobCtrSubjFilt.id
  action              = "permit"
  directives          = ["log"]
  priority_override   = "default"
}

resource "aci_filter_entry" "localAciNodeMgmtOobCtrSubjFiltAllowArpReq" {
  # Allows ARP REQUESTS INTO MANAGEMENT INTERFACES

  name        = "allow-arp-request"
  filter_dn   = aci_filter.localAciNodeMgmtOobCtrSubjFilt.id
  arp_opc     = "req"
  ether_t     = "arp"
  description = "Allows ARP Requests to/from the Terraform Managed Node Out-Of-Band Management Interface."
}

resource "aci_filter_entry" "localAciNodeMgmtOobCtrSubjFiltAllowArpReply" {
  # Allows ARP REPLIES INTO MANAGEMENT INTERFACES

  name        = "allow-arp-reply"
  filter_dn   = aci_filter.localAciNodeMgmtOobCtrSubjFilt.id
  arp_opc     = "reply"
  ether_t     = "arp"
  description = "Allows ARP Replies to/from the Terraform Managed Node Out-Of-Band Management Interface."
}

resource "aci_filter_entry" "localAciNodeMgmtOobCtrSubjFiltProtocolTcpUdpIteration" {
  for_each = local.FilteredProtocolTcpUdp

  name        = each.value.RULE_NAME
  filter_dn   = aci_filter.localAciNodeMgmtOobCtrSubjFilt.id
  ether_t     = "ipv4"
  stateful    = "yes"
  prot        = each.value.PROTOCOL
  d_from_port = each.value.PORT
  d_to_port   = each.value.PORT
  description = "${each.value.SNOW_RECORD} - Allows ${each.value.PROTOCOL}_${each.value.PORT} to/from the Terraform Managed Node Out-Of-Band Management Interface."
}

resource "aci_filter_entry" "localAciNodeMgmtOobCtrSubjFiltProtocolIcmpIteration" {
  for_each = local.FilteredProtocolIcmp

  name        = each.value.RULE_NAME
  filter_dn   = aci_filter.localAciNodeMgmtOobCtrSubjFilt.id
  ether_t     = "ipv4"
  stateful    = "yes"
  prot        = each.value.PROTOCOL
  description = "${each.value.SNOW_RECORD} - Allows ${each.value.PROTOCOL} to/from the Terraform Managed Node Out-Of-Band Management Interface."
}

/*
resource "null_resource" "localAciOddSpineNodeStageFirmware" {
  for_each = local.FilteredOddSpines

  provisioner "local-exec" {
    command = "python ./scripts/fabric-isolated-node-firmware.py"

    environment = {
      SWITCH_POD_ID  = each.value.SWITCH_POD_ID
      SWITCH_NODE_ID = each.value.SWITCH_NODE_ID
      TARGET_VERISON = var.ODD_SPINE_VERSION
    }
  }

  depends_on = [
    aci_fabric_node_member.localAciFabricNodeMemberIteration
  ]
}

resource "null_resource" "localAciEvenSpineNodeStageFirmware" {
  for_each = local.FilteredEvenSpines

  provisioner "local-exec" {
    command = "python ./scripts/fabric-isolated-node-firmware.py"

    environment = {
      SWITCH_POD_ID  = each.value.SWITCH_POD_ID
      SWITCH_NODE_ID = each.value.SWITCH_NODE_ID
      TARGET_VERISON = var.EVEN_SPINE_VERSION
    }
  }

  depends_on = [
    aci_fabric_node_member.localAciFabricNodeMemberIteration
  ]
}

resource "null_resource" "localAciOddLeafNodeStageFirmware" {
  for_each = local.FilteredOddLeafs

  provisioner "local-exec" {
    command = "python ./scripts/fabric-isolated-node-firmware.py"

    environment = {
      SWITCH_POD_ID  = each.value.SWITCH_POD_ID
      SWITCH_NODE_ID = each.value.SWITCH_NODE_ID
      TARGET_VERISON = var.ODD_LEAF_VERSION
    }
  }

  depends_on = [
    aci_fabric_node_member.localAciFabricNodeMemberIteration
  ]
}

resource "null_resource" "localAciEvenLeafNodeStageFirmware" {
  for_each = local.FilteredEvenLeafs

  provisioner "local-exec" {
    command = "python ./scripts/fabric-isolated-node-firmware.py"

    environment = {
      SWITCH_POD_ID  = each.value.SWITCH_POD_ID
      SWITCH_NODE_ID = each.value.SWITCH_NODE_ID
      TARGET_VERISON = var.EVEN_LEAF_VERSION
    }
  }

  depends_on = [
    aci_fabric_node_member.localAciFabricNodeMemberIteration
  ]
}

resource "aci_rest_managed" "localACIOddSpinestrigSchedP" {
  dn         = "uni/fabric/schedp-ODD_SPN_SCHD"
  class_name = "trigSchedP"
  content = {
    name   = "ODD_SPN_SCHD"
    status = "created,modified"
  }

  child {
    rn         = "abswinp-ODD_SPN_TRIG"
    class_name = "trigAbsWindowP"
    content = {
      name   = "ODD_SPN_TRIG"
      date   = timestamp() # UTC timestamp.
      status = "created,modified"
    }
  }

  depends_on = [
    aci_fabric_node_member.localAciFabricNodeMemberIteration
  ]
}

resource "aci_maintenance_policy" "localACIOddSpinesmaintMaintP" {
  name                   = "ODD_SPINES_MNTPOL"
  admin_st               = "triggered"
  description            = "This Maintenance Policy Defines the Firmware/Software Version for Odd Numbered Spines"
  annotation             = "orchestrator:terraform"
  graceful               = "yes"
  ignore_compat          = "yes"
  notif_cond             = "notifyNever"
  run_mode               = "pauseNever"
  version                = var.ODD_SPINE_VERSION
  version_check_override = "untriggered"

  relation_maint_rs_pol_scheduler = aci_rest_managed.localACIOddSpinestrigSchedP.dn
}

resource "aci_pod_maintenance_group" "localACIOddSpinesmaintMaintGrp" {
  name                       = "ODD_SPINES_MNTGRP"
  description                = "Associated with Maintenance Policy ${aci_maintenance_policy.localACIOddSpinesmaintMaintP.name}."
  annotation                 = "orchestrator:terraform"
  fwtype                     = "switch"
  pod_maintenance_group_type = "range"

  relation_maint_rs_mgrpp = aci_maintenance_policy.localACIOddSpinesmaintMaintP.id
}

resource "aci_maintenance_group_node" "localACIOddSpinesmaintMaintGrpNodeBlkIteration" {
  for_each = local.FilteredOddSpines

  name        = join("_", ["MaintGrpNodeBlk", each.value.SWITCH_NODE_ID])
  description = "Associated with Maintenance Group ${aci_pod_maintenance_group.localACIOddSpinesmaintMaintGrp.name}."
  annotation  = "orchestrator:terraform"
  from_       = each.value.SWITCH_NODE_ID
  to_         = each.value.SWITCH_NODE_ID

  pod_maintenance_group_dn = aci_pod_maintenance_group.localACIOddSpinesmaintMaintGrp.id
}

resource "aci_rest_managed" "localACIEvenSpinestrigSchedP" {
  dn         = "uni/fabric/schedp-EVEN_SPN_SCHD"
  class_name = "trigSchedP"
  content = {
    name   = "EVEN_SPN_SCHD"
    status = "created,modified"
  }

  child {
    rn         = "abswinp-EVEN_SPN_TRIG"
    class_name = "trigAbsWindowP"
    content = {
      name   = "EVEN_SPN_TRIG"
      date   = timestamp() # UTC timestamp.
      status = "created,modified"
    }
  }

  depends_on = [
    null_resource.localAciEvenSpineNodeStageFirmware
  ]
}

resource "aci_maintenance_policy" "localACIEvenSpinesmaintMaintP" {
  name                   = "EVEN_SPINES_MNTPOL"
  admin_st               = "triggered"
  description            = "This Maintenance Policy Defines the Firmware/Software Version for Even Numbered Spines"
  annotation             = "orchestrator:terraform"
  graceful               = "yes"
  ignore_compat          = "yes"
  notif_cond             = "notifyNever"
  run_mode               = "pauseNever"
  version                = var.EVEN_SPINE_VERSION
  version_check_override = "untriggered"

  relation_maint_rs_pol_scheduler = aci_rest_managed.localACIEvenSpinestrigSchedP.dn
}

resource "aci_pod_maintenance_group" "localACIEvenSpinesmaintMaintGrp" {
  name                       = "EVEN_SPINES_MNTGRP"
  description                = "Associated with Maintenance Policy ${aci_maintenance_policy.localACIEvenSpinesmaintMaintP.name}."
  annotation                 = "orchestrator:terraform"
  fwtype                     = "switch"
  pod_maintenance_group_type = "range"

  relation_maint_rs_mgrpp = aci_maintenance_policy.localACIEvenSpinesmaintMaintP.id
}

resource "aci_maintenance_group_node" "localACIEvenSpinesmaintMaintGrpNodeBlkIteration" {
  for_each = local.FilteredEvenSpines

  name        = join("_", ["MaintGrpNodeBlk", each.value.SWITCH_NODE_ID])
  description = "Associated with Maintenance Group ${aci_pod_maintenance_group.localACIEvenSpinesmaintMaintGrp.name}."
  annotation  = "orchestrator:terraform"
  from_       = each.value.SWITCH_NODE_ID
  to_         = each.value.SWITCH_NODE_ID

  pod_maintenance_group_dn = aci_pod_maintenance_group.localACIEvenSpinesmaintMaintGrp.id
}


resource "aci_rest_managed" "localACIOddLeaftrigSchedP" {
  dn         = "uni/fabric/schedp-ODD_LF_SCHD"
  class_name = "trigSchedP"
  content = {
    name   = "ODD_LF_SCHD"
    status = "created,modified"
  }

  child {
    rn         = "abswinp-ODD_LF_TRIG"
    class_name = "trigAbsWindowP"
    content = {
      name   = "ODD_LF_TRIG"
      date   = timestamp() # UTC timestamp.
      status = "created,modified"
    }
  }

  depends_on = [
    null_resource.localAciOddLeafNodeStageFirmware
  ]
}

resource "aci_maintenance_policy" "localACIOddLeafmaintMaintP" {
  name                   = "ODD_Leaf_MNTPOL"
  admin_st               = "triggered"
  description            = "This Maintenance Policy Defines the Firmware/Software Version for Odd Numbered Leaf"
  annotation             = "orchestrator:terraform"
  graceful               = "yes"
  ignore_compat          = "yes"
  notif_cond             = "notifyNever"
  run_mode               = "pauseNever"
  version                = var.ODD_LEAF_VERSION
  version_check_override = "untriggered"

  relation_maint_rs_pol_scheduler = aci_rest_managed.localACIOddLeaftrigSchedP.dn
}

resource "aci_pod_maintenance_group" "localACIOddLeafmaintMaintGrp" {
  name                       = "ODD_Leaf_MNTGRP"
  description                = "Associated with Maintenance Policy ${aci_maintenance_policy.localACIOddLeafmaintMaintP.name}."
  annotation                 = "orchestrator:terraform"
  fwtype                     = "switch"
  pod_maintenance_group_type = "range"

  relation_maint_rs_mgrpp = aci_maintenance_policy.localACIOddLeafmaintMaintP.id
}

resource "aci_maintenance_group_node" "localACIOddLeafmaintMaintGrpNodeBlkIteration" {
  for_each = local.FilteredOddLeafs

  name        = join("_", ["MaintGrpNodeBlk", each.value.SWITCH_NODE_ID])
  description = "Associated with Maintenance Group ${aci_pod_maintenance_group.localACIOddLeafmaintMaintGrp.name}."
  annotation  = "orchestrator:terraform"
  from_       = each.value.SWITCH_NODE_ID
  to_         = each.value.SWITCH_NODE_ID

  pod_maintenance_group_dn = aci_pod_maintenance_group.localACIOddLeafmaintMaintGrp.id
}

resource "aci_rest_managed" "localACIEvenLeaftrigSchedP" {
  dn         = "uni/fabric/schedp-EVEN_LF_SCHD"
  class_name = "trigSchedP"
  content = {
    name   = "EVEN_LF_SCHD"
    status = "created,modified"
  }

  child {
    rn         = "abswinp-EVEN_LF_TRIG"
    class_name = "trigAbsWindowP"
    content = {
      name   = "EVEN_LF_TRIG"
      date   = timestamp() # UTC timestamp.
      status = "created,modified"
    }
  }

  depends_on = [
    null_resource.localAciEvenLeafNodeStageFirmware
  ]
}

resource "aci_maintenance_policy" "localACIEvenLeafmaintMaintP" {
  name                   = "EVEN_Leaf_MNTPOL"
  admin_st               = "triggered"
  description            = "This Maintenance Policy Defines the Firmware/Software Version for Even Numbered Leaf"
  annotation             = "orchestrator:terraform"
  graceful               = "yes"
  ignore_compat          = "yes"
  notif_cond             = "notifyNever"
  run_mode               = "pauseNever"
  version                = var.EVEN_LEAF_VERSION
  version_check_override = "untriggered"

  relation_maint_rs_pol_scheduler = aci_rest_managed.localACIEvenLeaftrigSchedP.dn
}

resource "aci_pod_maintenance_group" "localACIEvenLeafmaintMaintGrp" {
  name                       = "EVEN_Leaf_MNTGRP"
  description                = "Associated with Maintenance Policy ${aci_maintenance_policy.localACIEvenLeafmaintMaintP.name}."
  annotation                 = "orchestrator:terraform"
  fwtype                     = "switch"
  pod_maintenance_group_type = "range"

  relation_maint_rs_mgrpp = aci_maintenance_policy.localACIEvenLeafmaintMaintP.id
}

resource "aci_maintenance_group_node" "localACIEvenLeafmaintMaintGrpNodeBlkIteration" {
  for_each = local.FilteredEvenLeafs

  name        = join("_", ["MaintGrpNodeBlk", each.value.SWITCH_NODE_ID])
  description = "Associated with Maintenance Group ${aci_pod_maintenance_group.localACIEvenLeafmaintMaintGrp.name}."
  annotation  = "orchestrator:terraform"
  from_       = each.value.SWITCH_NODE_ID
  to_         = each.value.SWITCH_NODE_ID

  pod_maintenance_group_dn = aci_pod_maintenance_group.localACIEvenLeafmaintMaintGrp.id
}
*/

/*

# THESE ITEMS ARE COMMENTED OUT DUE TO THE PREFERENCE OF A DESIGN ENABLING
# VPCS TO ALLOCATE TWO DIFFERENT SWITCHPORTS/INTERFACE SELECTORS
# ON TWO DIFFERENT SWITCHES; WHICH IS CONSTRAINTED BY THE COMBINED
# METHODOLOGY THE CODE THAT FOLLOWS DEPLOYS AS BEST PRACTICE

resource "aci_leaf_interface_profile" "localAciFabricAccessLeafVPCInterfaceProfileIteration" {
  for_each   = local.UniqueVpcPeerGroupId

  name       = join("_", [each.key, "INTPROF"]) #INT
  annotation = "orchestrator:terraform"
}

resource "aci_leaf_profile" "localAciFabricAccessLeafVPCSwitchProfileIteration" {
  for_each                     = local.UniqueVpcPeerGroupId

  name                         = join("_", [each.key, "SWPROF"]) #INT
  annotation                   = "orchestrator:terraform"

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