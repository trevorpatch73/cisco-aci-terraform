# This is the Terraform import file

resource "aci_fabric_node_member" "Node102_TEP-1-102" {
    name        = "leaf-2"
    serial      = "TEP-1-102"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_fabric_node_member" "Node101_TEP-1-101" {
    name        = "leaf-1"
    serial      = "TEP-1-101"
    
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
resource "aci_attachable_access_entity_profile" "SnV_corporate_external" {
    name        = "SnV_corporate_external"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "Heroes_corporate_external" {
    name        = "Heroes_corporate_external"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "Heroes_phys" {
    name        = "Heroes_phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "SnV_phys" {
    name        = "SnV_phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "mytest-prod-aaep" {
    name        = "mytest-prod-aaep"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "AEP_Phys" {
    name        = "AEP_Phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_attachable_access_entity_profile" "em-AEP" {
    name        = "em-AEP"
    
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
resource "aci_physical_domain" "SnV_phys" {
    name        = "SnV_phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "Heroes_phys" {
    name        = "Heroes_phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "mytest-phys" {
    name        = "mytest-phys"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "MATLAB_PHY_DOM" {
    name        = "MATLAB_PHY_DOM"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "TestPhysDomain" {
    name        = "TestPhysDomain"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "em-phy-BD" {
    name        = "em-phy-BD"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_physical_domain" "AI_ACI_TF_DEMO_SRV" {
    name        = "AI_ACI_TF_DEMO_SRV"
    
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_aaep_to_domain" "default-phys-em-phy-BD-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.default.id
    domain_dn                           = aci_physical_domain.phys-em-phy-BD.id
}
resource "aci_aaep_to_domain" "SnV_phys-phys-SnV_phys-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.SnV_phys.id
    domain_dn                           = aci_physical_domain.phys-SnV_phys.id
}
resource "aci_aaep_to_domain" "Heroes_phys-phys-Heroes_phys-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.Heroes_phys.id
    domain_dn                           = aci_physical_domain.phys-Heroes_phys.id
}
resource "aci_aaep_to_domain" "mytest-prod-aaep-phys-mytest-phys-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.mytest-prod-aaep.id
    domain_dn                           = aci_physical_domain.phys-mytest-phys.id
}
resource "aci_aaep_to_domain" "AEP_Phys-phys-TestPhysDomain-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.AEP_Phys.id
    domain_dn                           = aci_physical_domain.phys-TestPhysDomain.id
}
resource "aci_aaep_to_domain" "em-AEP-phys-em-phy-BD-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.em-AEP.id
    domain_dn                           = aci_physical_domain.phys-em-phy-BD.id
}