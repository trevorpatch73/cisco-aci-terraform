//  ------------- START SECTION: GUARDRAILS --------------- 
// ALL RESOURCES MUST BE DEPENDENT ON THESE FOR YOUR OWN HEALTH
resource "null_resource" "GlobalFabricVlanUniquenessCheckerPython" {
  provisioner "local-exec" {
    command     = "python3 global-fabric-vlan-uniqueness-checker.py"
    working_dir = "${path.root}/scripts"
  }

  triggers = {
    csv_hash = filemd5("${path.root}/data/app-mgmt-tenant-configuration.csv")
  }
}

resource "null_resource" "GlobalFabricSubnetUniquenessCheckerPython" {
  provisioner "local-exec" {
    command     = "python3 global-fabric-subnet-uniqueness-checker.py"
    working_dir = "${path.root}/scripts"
  }

  triggers = {
    csv_hash = filemd5("${path.root}/data/app-mgmt-tenant-configuration.csv")
  }
}

// ------------- END SECTION: GUARDRAILS ---------------

resource "aci_tenant" "localAciTenantIteration" {
  for_each = local.distinct_tenants

  name        = each.value
  description = join(" ", [each.value, "tenant was created via Terraform from a CI/CD Pipeline."])
  annotation  = "ORCHESTRATOR:TERRAFORM"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_application_profile" "localAciTenantApplicationProfileIteration" {
  for_each = {
    for i in flatten([
      for TENANT_NAME, MACRO_SEGMENTATION_ZONES in local.application_profile_list : [
        for MACRO_SEGMENTATION_ZONE in MACRO_SEGMENTATION_ZONES : {
          TENANT_NAME              = TENANT_NAME
          APPLICATION_PROFILE_NAME = MACRO_SEGMENTATION_ZONE
        }
      ]
    ]) :
    "${i.TENANT_NAME}.${i.APPLICATION_PROFILE_NAME}" => {
      TENANT_NAME              = i.TENANT_NAME
      APPLICATION_PROFILE_NAME = i.APPLICATION_PROFILE_NAME
    }
  }

  tenant_dn   = aci_tenant.localAciTenantIteration[each.value.TENANT_NAME].id
  name        = each.value.APPLICATION_PROFILE_NAME
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = join(" ", [each.value.APPLICATION_PROFILE_NAME, "application profile was created as a macro-segmentation zone via Terraform from a CI/CD Pipeline."])

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_bridge_domain" "localAciTenantBridgeDomainIteration" {
  for_each = local.network_centric_epgs_bds_list

  tenant_dn   = aci_tenant.localAciTenantIteration[each.value.TENANT_NAME].id
  name        = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "BD"])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  description = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "bridge domain was created as a NCI Mode VLAN for a segmentation zone via Terraform from a CI/CD Pipeline."])

  optimize_wan_bandwidth      = "no"
  arp_flood                   = each.value.BD_FLOOD == "true" ? "yes" : "no"
  ep_clear                    = "no"
  ep_move_detect_mode         = "garp"
  host_based_routing          = "no" # ISN via Nexus Dashboard MSO Not Used
  intersite_bum_traffic_allow = "no" # ISN via Nexus Dashboard MSO Not Used
  intersite_l2_stretch        = "no" # ISN via Nexus Dashboard MSO Not Used
  ip_learning                 = "yes"
  ipv6_mcast_allow            = each.value.BD_FLOOD == "true" ? "yes" : "no"
  limit_ip_learn_to_subnets   = "yes"
  ll_addr                     = "::"
  mac                         = "00:22:BD:F8:19:FF" # Cisco Default for all BDs
  mcast_allow                 = each.value.BD_FLOOD == "true" ? "yes" : "no"
  multi_dst_pkt_act           = each.value.BD_FLOOD == "true" ? "bd-flood" : "drop"
  bridge_domain_type          = "regular"
  unicast_route               = "yes"
  unk_mac_ucast_act           = each.value.BD_FLOOD == "true" ? "flood" : "proxy"
  unk_mcast_act               = each.value.BD_FLOOD == "true" ? "flood" : "opt-flood"
  v6unk_mcast_act             = each.value.BD_FLOOD == "true" ? "flood" : "opt-flood"
  vmac                        = "not-applicable" # ISN via Nexus Dashboard MSO Not Used

  relation_fv_rs_ctx = aci_vrf.localAciTenantApplicationProfileVrfIteration[each.key].id

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_subnet" "localAciTenantBridgeDomainSubnet" {
  for_each = { for subnet in local.bd_subnet_ips : "${subnet.TENANT_NAME}-${subnet.APPLICATION_NAME}-${subnet.MACRO_SEGMENTATION_ZONE}-${subnet.SUBNET}" => subnet }

  parent_dn   = aci_bridge_domain.localAciTenantBridgeDomainIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  description = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "subnet was created as a NCI Mode VLAN for a segmentation zone via Terraform from a CI/CD Pipeline."])
  ip          = "${each.value.GW_IP}/${each.value.MASK}"
  annotation  = "ORCHESTRATOR:TERRAFORM"
  ctrl        = each.value.BD_FLOOD == "true" ? ["querier", "nd"] : ["unspecified"]
  scope       = ["private"]
  virtual     = "no"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_vrf" "localAciTenantApplicationProfileVrfIteration" {
  for_each = local.network_centric_epgs_bds_list

  tenant_dn              = aci_tenant.localAciTenantIteration[each.value.TENANT_NAME].id
  name                   = join("_", [each.value.TENANT_NAME, each.value.MACRO_SEGMENTATION_ZONE, "VRF"])
  description            = join(" ", [each.value.MACRO_SEGMENTATION_ZONE, " VRF was created as a macro-segmentation zone via Terraform from a CI/CD Pipeline."])
  annotation             = "ORCHESTRATOR:TERRAFORM"
  bd_enforced_enable     = "yes"
  ip_data_plane_learning = "enabled"
  knw_mcast_act          = "permit"
  pc_enf_dir             = "ingress"
  pc_enf_pref            = "enforced"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_vrf_snmp_context" "localAciTenantApplicationProfileVrfSnmpIteration" {
  for_each = local.network_centric_epgs_bds_list

  vrf_dn     = aci_vrf.localAciTenantApplicationProfileVrfIteration[each.key].id
  name       = join("_", [each.value.TENANT_NAME, each.value.MACRO_SEGMENTATION_ZONE, "VRF", "SNMP"])
  annotation = "ORCHESTRATOR:TERRAFORM"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_vrf_snmp_context_community" "localAciTenantApplicationProfileVrfSnmpCommunityIteration" {
  for_each = local.network_centric_epgs_bds_list

  vrf_snmp_context_dn = aci_vrf_snmp_context.localAciTenantApplicationProfileVrfSnmpIteration[each.key].id
  name = join("-", [
    replace(each.value.TENANT_NAME, "_", "-"),
    replace(each.value.MACRO_SEGMENTATION_ZONE, "_", "-"),
    "VRF"
  ])
  description = join(" ", [
    replace(each.value.MACRO_SEGMENTATION_ZONE, "_", "-"),
    "VRF created via Terraform CI/CD"
  ])
  annotation = "ORCHESTRATOR:TERRAFORM"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}


resource "aci_application_epg" "localAciTenantApplicationEndpointGroupIteration" {
  for_each = local.network_centric_epgs_bds_list

  application_profile_dn = aci_application_profile.localAciTenantApplicationProfileIteration["${each.value.TENANT_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  name                   = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "aEPG"])
  description            = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "epg was created as a NCI Mode segmentation zone via Terraform from a CICD."])
  annotation             = "ORCHESTRATOR:TERRAFORM"
  flood_on_encap         = "disabled"
  fwd_ctrl               = "none"
  has_mcast_source       = "no"
  is_attr_based_epg      = "no"
  match_t                = "AtleastOne"
  pc_enf_pref            = "unenforced"
  pref_gr_memb           = "exclude"
  prio                   = "unspecified"
  shutdown               = "no"
  relation_fv_rs_bd      = aci_bridge_domain.localAciTenantBridgeDomainIteration[each.key].id

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}


resource "aci_contract" "localAciTenantAppEpgInboundContractIteration" {
  for_each = local.network_centric_epgs_bds_list

  tenant_dn   = aci_tenant.localAciTenantIteration[each.value.TENANT_NAME].id
  description = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "inbound contract epg was created as a NCI Mode segmentation zone via Terraform from a CICD."])
  name        = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "IN", "CTR"])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  prio        = "unspecified"
  scope       = "context"
  target_dscp = "unspecified"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_contract_subject" "localAciTenantAppEpgInboundContractSubjectIteration" {
  for_each = local.network_centric_epgs_bds_list

  contract_dn   = aci_contract.localAciTenantAppEpgInboundContractIteration[each.key].id
  description   = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "inbound contract epg was created as a NCI Mode segmentation zone via Terraform from a CICD."])
  name          = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "IN", "CTR", "SUBJ"])
  annotation    = "ORCHESTRATOR:TERRAFORM"
  cons_match_t  = "AtleastOne"
  prio          = "unspecified"
  prov_match_t  = "AtleastOne"
  rev_flt_ports = "yes"
  target_dscp   = "unspecified"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_contract_subject_filter" "localAciTenantAppEpgInboundCtrSubjFiltIteration" {
  for_each = local.inbound_port_map

  contract_subject_dn = aci_contract_subject.localAciTenantAppEpgInboundContractSubjectIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  filter_dn           = aci_filter.localAciTenantContractFiltersIteration["${each.value.TENANT_NAME}.${each.value.INBOUND_PORT}"].id
  action              = "permit"
  directives          = ["log"]
  priority_override   = "default"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_epg_to_contract" "localAciTenantAppEpgInboundCtrAssocIteration" {
  for_each = local.network_centric_epgs_bds_list

  application_epg_dn = aci_application_epg.localAciTenantApplicationEndpointGroupIteration[each.key].id
  contract_dn        = aci_contract.localAciTenantAppEpgInboundContractIteration[each.key].id
  contract_type      = "provider"
  annotation         = "ORCHESTRATOR:TERRAFORM"
  match_t            = "AtleastOne"
  prio               = "unspecified"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_contract" "localAciTenantAppEpgOutboundContractIteration" {
  for_each = local.network_centric_epgs_bds_list

  tenant_dn   = aci_tenant.localAciTenantIteration[each.value.TENANT_NAME].id
  description = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "outbound contract epg was created as a NCI Mode segmentation zone via Terraform from a CICD."])
  name        = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "OUT", "CTR"])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  prio        = "unspecified"
  scope       = "context"
  target_dscp = "unspecified"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_contract_subject" "localAciTenantAppEpgOutboundContractSubjectIteration" {
  for_each = local.network_centric_epgs_bds_list

  contract_dn   = aci_contract.localAciTenantAppEpgOutboundContractIteration[each.key].id
  description   = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "outbound contract epg was created as a NCI Mode segmentation zone via Terraform from a CICD."])
  name          = join("_", ["VLAN", each.value.VLAN_ID, each.value.TENANT_NAME, each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "OUT", "CTR", "SUBJ"])
  annotation    = "ORCHESTRATOR:TERRAFORM"
  cons_match_t  = "AtleastOne"
  prio          = "unspecified"
  prov_match_t  = "AtleastOne"
  rev_flt_ports = "yes"
  target_dscp   = "unspecified"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_contract_subject_filter" "localAciTenantAppEpgOutboundCtrSubjFiltIteration" {
  for_each = local.outbound_port_map

  contract_subject_dn = aci_contract_subject.localAciTenantAppEpgOutboundContractSubjectIteration["${each.value.TENANT_NAME}.${each.value.APPLICATION_NAME}.${each.value.MACRO_SEGMENTATION_ZONE}"].id
  filter_dn           = aci_filter.localAciTenantContractFiltersIteration["${each.value.TENANT_NAME}.${each.value.OUTBOUND_PORT}"].id
  action              = "permit"
  directives          = ["log"]
  priority_override   = "default"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_epg_to_contract" "localAciTenantAppEpgOutboundCtrAssocIteration" {
  for_each = local.network_centric_epgs_bds_list

  application_epg_dn = aci_application_epg.localAciTenantApplicationEndpointGroupIteration[each.key].id
  contract_dn        = aci_contract.localAciTenantAppEpgOutboundContractIteration[each.key].id
  contract_type      = "consumer"
  annotation         = "ORCHESTRATOR:TERRAFORM"
  prio               = "unspecified"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_filter" "localAciTenantContractFiltersIteration" {
  for_each = local.distinct_protocol_port_tenant_pairs

  tenant_dn   = aci_tenant.localAciTenantIteration[each.value.TENANT_NAME].id
  description = join(" ", ["Allows", each.value.PROTOCOL, each.value.PORT, "as specified by Terraform CI/CD Pipeline for EPGs"])
  name        = join("_", [each.value.TENANT_NAME, upper(each.value.PROTOCOL), each.value.PORT, "FILT"])
  annotation  = "ORCHESTRATOR:TERRAFORM"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_filter_entry" "localAciTenantContractFilterEntriesIteration" {
  for_each = local.distinct_protocol_port_tenant_pairs

  filter_dn   = aci_filter.localAciTenantContractFiltersIteration[each.key].id
  description = join(" ", ["Allows", each.value.PROTOCOL, each.value.PORT, "as specified by Terraform CI/CD Pipeline for EPGs"])
  name        = join("_", [each.value.TENANT_NAME, "ALLOW", upper(each.value.PROTOCOL), each.value.PORT])
  annotation  = "ORCHESTRATOR:TERRAFORM"

  ether_t     = "ipv4"
  prot        = each.value.PROTOCOL
  d_from_port = each.value.PORT
  d_to_port   = each.value.PORT
  stateful    = "yes"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_vlan_pool" "localAciTenantPhyDomVlanPoolIteration" {
  for_each = local.distinct_tenants

  name        = join("_", [each.value, "PHYS-DOM", "VLAN-POOL"])
  description = join(" ", [each.value, " tenant VLAN Pool was created in a NCI Mode via Terraform from a CI/CD Pipeline."])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  alloc_mode  = "static"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_ranges" "localAciTenantPhyDomVlanPoolRangesIteration" {
  for_each = local.network_centric_epgs_bds_list

  annotation   = "ORCHESTRATOR:TERRAFORM"
  description  = join(" ", [each.value.APPLICATION_NAME, each.value.MACRO_SEGMENTATION_ZONE, "bridge domain was created as a NCI Mode VLAN for a segmentation zone via Terraform from a CI/CD Pipeline."])
  vlan_pool_dn = aci_vlan_pool.localAciTenantPhyDomVlanPoolIteration[each.value.TENANT_NAME].id
  from         = "vlan-${each.value.VLAN_ID}"
  to           = "vlan-${each.value.VLAN_ID}"
  alloc_mode   = "inherit"
  role         = "external"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_physical_domain" "localAciTenantPhysicalDomainIteration" {
  for_each = local.distinct_tenants

  name                      = join("_", [each.value, "PHYS-DOM"])
  annotation                = "ORCHESTRATOR:TERRAFORM"
  relation_infra_rs_vlan_ns = aci_vlan_pool.localAciTenantPhyDomVlanPoolIteration[each.key].id


  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_epg_to_domain" "localAciTenantEpgPhysDomAssocIteration" {
  for_each = local.network_centric_epgs_bds_list

  application_epg_dn = aci_application_epg.localAciTenantApplicationEndpointGroupIteration[each.key].id
  tdn                = aci_physical_domain.localAciTenantPhysicalDomainIteration[each.value.TENANT_NAME].id

  annotation            = "ORCHESTRATOR:TERRAFORM"
  binding_type          = "none"
  allow_micro_seg       = "false"
  encap                 = "vlan-${each.value.VLAN_ID}"
  encap_mode            = "auto"
  epg_cos               = "Cos0"
  epg_cos_pref          = "disabled"
  instr_imedcy          = "lazy"
  netflow_dir           = "both"
  netflow_pref          = "disabled"
  num_ports             = "0"
  port_allocation       = "none"
  primary_encap         = "unknown"
  primary_encap_inner   = "unknown"
  res_imedcy            = "lazy"
  secondary_encap_inner = "unknown"
  switching_mode        = "native"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_attachable_access_entity_profile" "localAciTenantAttachableEntityAccessProfileIteration" {
  for_each = local.distinct_tenants

  name                    = join("_", [each.value, "AAEP"])
  description             = join(" ", [each.value, " AAEP allows access to the associated tenant Physical Domain in a NCI Mode via Terraform from a CI/CD Pipeline."])
  annotation              = "ORCHESTRATOR:TERRAFORM"
  relation_infra_rs_dom_p = [aci_physical_domain.localAciTenantPhysicalDomainIteration[each.key].id]

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_attachable_access_entity_profile" "localAciGlobalAttachableEntityAccessProfileIteration" {
  name        = "GLOBAL_AAEP"
  description = "Global AAEP for all tenants"
  annotation  = "ORCHESTRATOR:TERRAFORM"

  relation_infra_rs_dom_p = values(aci_physical_domain.localAciTenantPhysicalDomainIteration)[*].id

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_vlan_pool" "localAciTenantL3ExtVlanPoolIteration" {
  for_each = local.distinct_tenants

  name        = join("_", [each.value, "L3-EXT", "VLAN-POOL"])
  description = join(" ", [each.value, " tenant L3Out VLAN Pool was created in a NCI Mode via Terraform from a CI/CD Pipeline."])
  annotation  = "ORCHESTRATOR:TERRAFORM"
  alloc_mode  = "static"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_ranges" "localAciTenantL3ExtVlanPoolRangesIteration" {
  for_each = local.network_centric_epgs_bds_list

  annotation   = "ORCHESTRATOR:TERRAFORM"
  description  = join(" ", [each.value.TENANT_NAME, each.value.MACRO_SEGMENTATION_ZONE, "L3Out Transit VLAN was created segmentation zone via Terraform"])
  vlan_pool_dn = aci_vlan_pool.localAciTenantL3ExtVlanPoolIteration[each.value.TENANT_NAME].id
  from         = "vlan-${each.value.TRANSIT_VLAN_ID}"
  to           = "vlan-${each.value.TRANSIT_VLAN_ID}"
  alloc_mode   = "inherit"
  role         = "external"

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_l3_domain_profile" "localAciTenantL3ExternalDomainIteration" {
  for_each = local.distinct_tenants

  name                      = join("_", [each.value, "L3OUT-DOM"])
  annotation                = "ORCHESTRATOR:TERRAFORM"
  relation_infra_rs_vlan_ns = aci_vlan_pool.localAciTenantL3ExtVlanPoolIteration[each.key].id


  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_l3_outside" "localAciTenantAppProfVrfL3OutProfNgfwIteration" {
  for_each = local.network_centric_epgs_bds_list
  
  tenant_dn                     = aci_tenant.localAciTenantIteration[each.value.TENANT_NAME].id
  name                          = join("_", [each.value.TENANT_NAME, each.value.MACRO_SEGMENTATION_ZONE, "VRF", "NGFW", "L3OUT"])
  description                   = join(" ", [each.value.MACRO_SEGMENTATION_ZONE, "L3Out routes to the Tenant NGFW as part of a macro-segmentation zone via Terraform."])
  annotation                    = "ORCHESTRATOR:TERRAFORM"
  enforce_rtctrl                = ["export"]
  target_dscp                   = "unspecified"
  mpls_enabled                  = "no"
  pim                           = ["ipv4", "ipv6"]
  
  relation_l3ext_rs_ectx        = aci_vrf.localAciTenantApplicationProfileVrfIteration[each.key].id
  relation_l3ext_rs_l3_dom_att  = aci_l3_domain_profile.localAciTenantL3ExternalDomainIteration["${each.value.TENANT_NAME}"].id

  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}

resource "aci_external_network_instance_profile" "localAciTenantAppProfVrfL3OutEpgNgfwIteration" {
  for_each = local.network_centric_epgs_bds_list
  
  l3_outside_dn   = aci_l3_outside.localAciTenantAppProfVrfL3OutProfNgfwIteration[each.key].id
  name            = join("_", [each.value.TENANT_NAME, each.value.MACRO_SEGMENTATION_ZONE, "VRF", "NGFW", "L3OUT-EPG"])
  annotation      = "ORCHESTRATOR:TERRAFORM"  
  flood_on_encap  = "disabled"
  match_t         = "AtleastOne"
  pref_gr_memb    = "exclude"
  prio            = "unspecified"
  target_dscp     = "unspecified"
  
  depends_on = [
    null_resource.GlobalFabricVlanUniquenessCheckerPython,
    null_resource.GlobalFabricSubnetUniquenessCheckerPython
  ]
}  

resource "aci_l3_ext_subnet" "localAciTenantAppProfVrfL3OutEpgSnetNgfwIteration" {
  for_each = local.network_centric_epgs_bds_list
  
  external_network_instance_profile_dn  = aci_external_network_instance_profile.localAciTenantAppProfVrfL3OutEpgNgfwIteration[each.key].id
  description                           = "Deafult Route Out of Macro-Segmentation Zone"
  ip                                    = "0.0.0.0/0"
  annotation                            = "ORCHESTRATOR:TERRAFORM" 
}  