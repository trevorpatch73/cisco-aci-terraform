# fabric-node-workflow

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aci_access_switch_policy_group.localAciFabricAccessLeafSwitchPolicyGroupIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/access_switch_policy_group) | resource |
| [aci_contract_subject.localAciNodeMgmtOobCtrSubj](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/contract_subject) | resource |
| [aci_contract_subject_filter.localAciNodeMgmtOobCtrSubjFiltAssoc](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/contract_subject_filter) | resource |
| [aci_fabric_node_member.localAciFabricNodeMemberIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/fabric_node_member) | resource |
| [aci_filter.localAciNodeMgmtOobCtrSubjFilt](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/filter) | resource |
| [aci_filter_entry.localAciNodeMgmtOobCtrSubjFiltAllowArpReply](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/filter_entry) | resource |
| [aci_filter_entry.localAciNodeMgmtOobCtrSubjFiltAllowArpReq](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/filter_entry) | resource |
| [aci_filter_entry.localAciNodeMgmtOobCtrSubjFiltProtocolIcmpIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/filter_entry) | resource |
| [aci_filter_entry.localAciNodeMgmtOobCtrSubjFiltProtocolTcpUdpIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/filter_entry) | resource |
| [aci_leaf_interface_profile.localAciFabricAccessLeafInterfaceProfileIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_interface_profile) | resource |
| [aci_leaf_profile.localAciFabricAccessLeafSwitchProfileIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_profile) | resource |
| [aci_node_mgmt_epg.localAciNodeMgmtOobEPG](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/node_mgmt_epg) | resource |
| [aci_rest.localAciRestLeafSWPROFAssocSWPOLGRP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_rest_managed.localAciNodeMgmtOobCtr](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_static_node_mgmt_address.localAciStaticNodeMgmtAddrIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/static_node_mgmt_address) | resource |
| [aci_vpc_domain_policy.localAciVpcDomainPolicyIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/vpc_domain_policy) | resource |
| [aci_vpc_explicit_protection_group.localAciVpcExplictProtectionGroupIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/vpc_explicit_protection_group) | resource |
| [aci_tenant.dataLocalAciTenantMgmt](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/data-sources/tenant) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_EVEN_LEAF_VERSION"></a> [EVEN\_LEAF\_VERSION](#input\_EVEN\_LEAF\_VERSION) | Inherits the software version to run on Cisco ACI Even Numbered Leaf Nodes | `string` | n/a | yes |
| <a name="input_EVEN_SPINE_VERSION"></a> [EVEN\_SPINE\_VERSION](#input\_EVEN\_SPINE\_VERSION) | Inherits the software version to run on Cisco ACI Even Numbered Spine Nodes | `string` | n/a | yes |
| <a name="input_ODD_LEAF_VERSION"></a> [ODD\_LEAF\_VERSION](#input\_ODD\_LEAF\_VERSION) | Inherits the software version to run on Cisco ACI Odd Numbered Leaf Nodes | `string` | n/a | yes |
| <a name="input_ODD_SPINE_VERSION"></a> [ODD\_SPINE\_VERSION](#input\_ODD\_SPINE\_VERSION) | Inherits the software version to run on Cisco ACI Odd Numbered Spine Nodes | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
