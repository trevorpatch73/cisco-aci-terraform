# endpoint-switchport-configuration.csv

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
| [aci_access_port_block.localAciPhysInterfaceSelectorPortBlockIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/access_port_block) | resource |
| [aci_access_port_selector.localAciPhysInterfaceSelectorIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/access_port_selector) | resource |
| [aci_lacp_policy.localAciLacpActivePolicy](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/lacp_policy) | resource |
| [aci_leaf_access_bundle_policy_group.localAciGlobalPhysPortChannelPolicyGroup](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_access_bundle_policy_group) | resource |
| [aci_leaf_access_bundle_policy_group.localAciGlobalPhysVirtualPortChannelPolicyGroup](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_access_bundle_policy_group) | resource |
| [aci_leaf_access_bundle_policy_group.localAciTenantPhysPortChannelPolicyGroup](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_access_bundle_policy_group) | resource |
| [aci_leaf_access_bundle_policy_group.localAciTenantPhysVirtualPortChannelPolicyGroup](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_access_bundle_policy_group) | resource |
| [aci_leaf_access_port_policy_group.localAciGlobalPhysAccessPortPolicyGroupIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_access_port_policy_group) | resource |
| [aci_leaf_access_port_policy_group.localAciTenantPhysAccessPortPolicyGroupIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/leaf_access_port_policy_group) | resource |
| [aci_rest.localAciRestGlobalNonBondIntSelectIntPolAssocIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_rest.localAciRestGlobalPCIntSelectIntPolAssocIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_rest.localAciRestGlobalVPCIntSelectIntPolAssocIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_rest.localAciRestTenantNonBondIntSelectIntPolAssocIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_rest.localAciRestTenantPCIntSelectIntPolAssocIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_rest.localAciRestTenantVPCIntSelectIntPolAssocIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/resources/rest) | resource |
| [aci_attachable_access_entity_profile.dataLocalAciAttachableEntityProfileIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/data-sources/attachable_access_entity_profile) | data source |
| [aci_attachable_access_entity_profile.dataLocalAciGobalAAEP](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/data-sources/attachable_access_entity_profile) | data source |
| [aci_leaf_interface_profile.dataLocalAciFabricAccessLeafInterfaceProfileIteration](https://registry.terraform.io/providers/ciscodevnet/aci/latest/docs/data-sources/leaf_interface_profile) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
