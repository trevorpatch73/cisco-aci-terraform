# fabric-node-workflow

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

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
| [aci_maintenance_group_node.localACIEvenLeafmaintMaintGrpNodeBlkIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_group_node) | resource |
| [aci_maintenance_group_node.localACIEvenSpinesmaintMaintGrpNodeBlkIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_group_node) | resource |
| [aci_maintenance_group_node.localACIOddLeafmaintMaintGrpNodeBlkIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_group_node) | resource |
| [aci_maintenance_group_node.localACIOddSpinesmaintMaintGrpNodeBlkIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_group_node) | resource |
| [aci_maintenance_policy.localACIEvenLeafmaintMaintP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_policy) | resource |
| [aci_maintenance_policy.localACIEvenSpinesmaintMaintP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_policy) | resource |
| [aci_maintenance_policy.localACIOddLeafmaintMaintP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_policy) | resource |
| [aci_maintenance_policy.localACIOddSpinesmaintMaintP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/maintenance_policy) | resource |
| [aci_node_mgmt_epg.localAciNodeMgmtOobEPG](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/node_mgmt_epg) | resource |
| [aci_pod_maintenance_group.localACIEvenLeafmaintMaintGrp](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/pod_maintenance_group) | resource |
| [aci_pod_maintenance_group.localACIEvenSpinesmaintMaintGrp](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/pod_maintenance_group) | resource |
| [aci_pod_maintenance_group.localACIOddLeafmaintMaintGrp](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/pod_maintenance_group) | resource |
| [aci_pod_maintenance_group.localACIOddSpinesmaintMaintGrp](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/pod_maintenance_group) | resource |
| [aci_rest.localAciRestLeafSWPROFAssocSWPOLGRP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_rest_managed.localACIEvenLeaftrigSchedP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.localACIEvenSpinestrigSchedP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.localACIOddLeaftrigSchedP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.localACIOddSpinestrigSchedP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.localAciNodeMgmtOobCtr](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_static_node_mgmt_address.localAciStaticNodeMgmtAddrIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/static_node_mgmt_address) | resource |
| [aci_vpc_domain_policy.localAciVpcDomainPolicyIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/vpc_domain_policy) | resource |
| [aci_vpc_explicit_protection_group.localAciVpcExplictProtectionGroupIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/vpc_explicit_protection_group) | resource |
| [null_resource.localAciEvenLeafNodeStageFirmware](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.localAciEvenSpineNodeStageFirmware](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.localAciOddLeafNodeStageFirmware](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.localAciOddSpineNodeStageFirmware](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
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
