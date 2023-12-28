# environment

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_fabric-node-workflow"></a> [fabric-node-workflow](#module\_fabric-node-workflow) | ./modules/fabric-node-workflow | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_CISCO_ACI_APIC_IP_ADDRESS"></a> [CISCO\_ACI\_APIC\_IP\_ADDRESS](#input\_CISCO\_ACI\_APIC\_IP\_ADDRESS) | MAPS TO ENVIRONMENTAL VARIABLE TF\_VAR\_CISCO\_ACI\_APIC\_IP\_ADDRESS | `string` | n/a | yes |
| <a name="input_CISCO_ACI_TERRAFORM_PASSWORD"></a> [CISCO\_ACI\_TERRAFORM\_PASSWORD](#input\_CISCO\_ACI\_TERRAFORM\_PASSWORD) | MAPS TO ENVIRONMENTAL VARIABLE TF\_VAR\_CISCO\_ACI\_TERRAFORM\_PASSWORD | `string` | n/a | yes |
| <a name="input_CISCO_ACI_TERRAFORM_USERNAME"></a> [CISCO\_ACI\_TERRAFORM\_USERNAME](#input\_CISCO\_ACI\_TERRAFORM\_USERNAME) | MAPS TO ENVIRONMENTAL VARIABLE TF\_VAR\_CISCO\_ACI\_TERRAFORM\_USERNAME | `string` | n/a | yes |
| <a name="input_EVEN_LEAF_VERSION"></a> [EVEN\_LEAF\_VERSION](#input\_EVEN\_LEAF\_VERSION) | Inherits the software version to run on Cisco ACI Even Numbered Leaf Nodes | `string` | `"simsw-6.0(2h)"` | no |
| <a name="input_EVEN_SPINE_VERSION"></a> [EVEN\_SPINE\_VERSION](#input\_EVEN\_SPINE\_VERSION) | Inherits the software version to run on Cisco ACI Even Numbered Spine Nodes | `string` | `"simsw-6.0(2h)"` | no |
| <a name="input_ODD_LEAF_VERSION"></a> [ODD\_LEAF\_VERSION](#input\_ODD\_LEAF\_VERSION) | Inherits the software version to run on Cisco ACI Odd Numbered Leaf Nodes | `string` | `"simsw-6.0(2h)"` | no |
| <a name="input_ODD_SPINE_VERSION"></a> [ODD\_SPINE\_VERSION](#input\_ODD\_SPINE\_VERSION) | Inherits the software version to run on Cisco ACI Odd Numbered Spine Nodes | `string` | `"simsw-6.0(2h)"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
