# This is the Terraform import file

resource "aci_fabric_node_member" "Node101_TEP-1-101" {
    name        = "leaf-1"
    serial      = "TEP-1-101"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_fabric_node_member" "Node102_TEP-1-102" {
    name        = "leaf-2"
    serial      = "TEP-1-102"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_fabric_node_member" "Node201_TEP-1-103" {
    name        = "spine-1"
    serial      = "TEP-1-103"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "default" {
    name        = "default"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "out3AAE" {
    name        = "out3AAE"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "Test" {
    name        = "Test"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "Test1" {
    name        = "Test1"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "sothy_aeep" {
    name        = "sothy_aeep"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "mud-aaep1" {
    name        = "mud-aaep1"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "GK" {
    name        = "GK"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "Pranav" {
    name        = "Pranav"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "RG-VCF-MGD-NSXEDGE-UPLINKS-AAEP" {
    name        = "RG-VCF-MGD-NSXEDGE-UPLINKS-AAEP"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "phys" {
    name        = "phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "sothy_phys" {
    name        = "sothy_phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "mud-physical-domain" {
    name        = "mud-physical-domain"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "RG-VCF-MGD-NSXEDGE-UPLINKS-PD" {
    name        = "RG-VCF-MGD-NSXEDGE-UPLINKS-PD"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "sdk_test_physdom_2" {
    name        = "sdk_test_physdom_2"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "sdk_test_physdom_1" {
    name        = "sdk_test_physdom_1"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_aaep_to_physdomain" "sothy_aeep-phys-sothy_phys-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.sothy_aeep.id
    domain_dn                           = aci_physical_domain.phys-sothy_phys.id
    
    lifecycle {
        ignore_changes = all
    }    
}
resource "aci_aaep_to_physdomain" "mud-aaep1-phys-mud-physical-domain-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.mud-aaep1.id
    domain_dn                           = aci_physical_domain.phys-mud-physical-domain.id
    
    lifecycle {
        ignore_changes = all
    }    
}
resource "aci_aaep_to_physdomain" "RG-VCF-MGD-NSXEDGE-UPLINKS-AAEP-phys-RG-VCF-MGD-NSXEDGE-UPLINKS-PD-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.RG-VCF-MGD-NSXEDGE-UPLINKS-AAEP.id
    domain_dn                           = aci_physical_domain.phys-RG-VCF-MGD-NSXEDGE-UPLINKS-PD.id
    
    lifecycle {
        ignore_changes = all
    }    
}
resource "aci_vlan_pool" "OUT3" {
    name       = "OUT3"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "OUT3-vlan-500-vlan-500" {
    vlan_pool_dn = aci_vlan_pool.OUT3.id
    from         = "vlan-500"
    to           = "vlan-500"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_vlan_pool" "KB_StaticVLPool" {
    name       = "KB_StaticVLPool"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "KB_StaticVLPool-vlan-270-vlan-300" {
    vlan_pool_dn = aci_vlan_pool.KB_StaticVLPool.id
    from         = "vlan-270"
    to           = "vlan-300"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "KB_StaticVLPool-vlan-230-vlan-256" {
    vlan_pool_dn = aci_vlan_pool.KB_StaticVLPool.id
    from         = "vlan-230"
    to           = "vlan-256"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "KB_StaticVLPool-vlan-224-vlan-229" {
    vlan_pool_dn = aci_vlan_pool.KB_StaticVLPool.id
    from         = "vlan-224"
    to           = "vlan-229"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_vlan_pool" "mud-phy-pool1" {
    name       = "mud-phy-pool1"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "mud-phy-pool1-vlan-20-vlan-25" {
    vlan_pool_dn = aci_vlan_pool.mud-phy-pool1.id
    from         = "vlan-20"
    to           = "vlan-25"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_vlan_pool" "GK" {
    name       = "GK"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "GK-vlan-2222-vlan-2222" {
    vlan_pool_dn = aci_vlan_pool.GK.id
    from         = "vlan-2222"
    to           = "vlan-2222"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_vlan_pool" "RG-VCF-MGD-NSXEDGE-UPLINKS-VLP" {
    name       = "RG-VCF-MGD-NSXEDGE-UPLINKS-VLP"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "RG-VCF-MGD-NSXEDGE-UPLINKS-VLP-vlan-150-vlan-151" {
    vlan_pool_dn = aci_vlan_pool.RG-VCF-MGD-NSXEDGE-UPLINKS-VLP.id
    from         = "vlan-150"
    to           = "vlan-151"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_vlan_pool" "test-vlan-4" {
    name       = "test-vlan-4"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "test-vlan-4-vlan-4-vlan-4" {
    vlan_pool_dn = aci_vlan_pool.test-vlan-4.id
    from         = "vlan-4"
    to           = "vlan-4"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_vlan_pool" "sdk_test_general_pool_1_pool" {
    name       = "sdk_test_general_pool_1_pool"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "sdk_test_general_pool_1_pool-vlan-300-vlan-399" {
    vlan_pool_dn = aci_vlan_pool.sdk_test_general_pool_1_pool.id
    from         = "vlan-300"
    to           = "vlan-399"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_vlan_pool" "sdk_test_general_pool_2_pool" {
    name       = "sdk_test_general_pool_2_pool"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_ranges" "sdk_test_general_pool_2_pool-vlan-400-vlan-499" {
    vlan_pool_dn = aci_vlan_pool.sdk_test_general_pool_2_pool.id
    from         = "vlan-400"
    to           = "vlan-499"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "system-port-profile-node-102" {
    name = "system-port-profile-node-102"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_selector" "system-port-profile-node-102-system-port-selector-accportgrp-mud-access-policy-1" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.system-port-profile-node-102.id
    name                      = "system-port-selector-accportgrp-mud-access-policy-1"
    access_port_selector_type = "range"

    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_block" "system-port-profile-node-102-system-port-selector-accportgrp-mud-access-policy-1-E1_35-E1_35" {
    access_port_selector_dn = aci_access_port_selector.system-port-profile-node-102-system-port-selector-accportgrp-mud-access-policy-1.id
    from_card               = "1"
    from_port               = "35"
    to_card                 = "1"
    to_port                 = "35"

    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_selector" "system-port-profile-node-102-system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.system-port-profile-node-102.id
    name                      = "system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01"
    access_port_selector_type = "range"

    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_block" "system-port-profile-node-102-system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01-E1_1-E1_1" {
    access_port_selector_dn = aci_access_port_selector.system-port-profile-node-102-system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01.id
    from_card               = "1"
    from_port               = "1"
    to_card                 = "1"
    to_port                 = "1"

    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "system-port-profile-node-101" {
    name = "system-port-profile-node-101"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_selector" "system-port-profile-node-101-system-port-selector-accportgrp-mud-access-policy-1" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.system-port-profile-node-101.id
    name                      = "system-port-selector-accportgrp-mud-access-policy-1"
    access_port_selector_type = "range"

    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_block" "system-port-profile-node-101-system-port-selector-accportgrp-mud-access-policy-1-E1_35-E1_35" {
    access_port_selector_dn = aci_access_port_selector.system-port-profile-node-101-system-port-selector-accportgrp-mud-access-policy-1.id
    from_card               = "1"
    from_port               = "35"
    to_card                 = "1"
    to_port                 = "35"

    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_selector" "system-port-profile-node-101-system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.system-port-profile-node-101.id
    name                      = "system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01"
    access_port_selector_type = "range"

    lifecycle {
        ignore_changes = all
    }
}
resource "aci_access_port_block" "system-port-profile-node-101-system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01-E1_1-E1_1" {
    access_port_selector_dn = aci_access_port_selector.system-port-profile-node-101-system-port-selector-accportgrp-Leaf-Access-Port-Policy-Group-01.id
    from_card               = "1"
    from_port               = "1"
    to_card                 = "1"
    to_port                 = "1"

    lifecycle {
        ignore_changes = all
    }
}