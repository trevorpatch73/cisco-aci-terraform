# This is the Terraform import file

resource "aci_leaf_interface_profile" "tf_1105_INTPROF" {
    name = "1105_INTPROF"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "tf_1106_INTPROF" {
    name = "1106_INTPROF"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "tf_1105-1106_INTPROF" {
    name = "1105-1106_INTPROF"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "tf_1107-1108_INTPROF" {
    name = "1107-1108_INTPROF"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "tf_1108_INTPROF" {
    name = "1108_INTPROF"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "tf_1107_INTPROF" {
    name = "1107_INTPROF"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "tf_ZF-6R-LEAF-2107" {
    name = "ZF-6R-LEAF-2107"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_interface_profile" "tf_ZF-6R-LEAF-2108" {
    name = "ZF-6R-LEAF-2108"
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_profile" "tf_1105_1106_SWPROF" {
    name = "1105_1106_SWPROF"
    leaf_selector {
        name = "1105-1106_LFSEL"
        switch_association_type = "range"
        node_block {
            name = "blk1"
            from_ = "1105"
            to_ = "1106"
        }
    }
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.tf_1106_INTPROF.id]
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_profile" "tf_1107_1108_SWPROF" {
    name = "1107_1108_SWPROF"
    leaf_selector {
        name = "1107-1108_LFSEL"
        switch_association_type = "range"
        node_block {
            name = "blk1"
            from_ = "1107"
            to_ = "1108"
        }
    }
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.tf_1108_INTPROF.id]
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_profile" "tf_1106_SWPROF" {
    name = "1106_SWPROF"
    leaf_selector {
        name = "1106_LFSEL"
        switch_association_type = "range"
        node_block {
            name = "blk1"
            from_ = "1106"
            to_ = "1106"
        }
    }
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.tf_1106_INTPROF.id]
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_profile" "tf_1105_SWPROF" {
    name = "1105_SWPROF"
    leaf_selector {
        name = "1105_LFSEL"
        switch_association_type = "range"
        node_block {
            name = "blk1"
            from_ = "1105"
            to_ = "1105"
        }
    }
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.tf_1105_INTPROF.id]
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_profile" "tf_1108_SWPROF" {
    name = "1108_SWPROF"
    leaf_selector {
        name = "1108_LFSEL"
        switch_association_type = "range"
        node_block {
            name = "blk1"
            from_ = "1108"
            to_ = "1108"
        }
    }
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.tf_1108_INTPROF.id]
    lifecycle {
        ignore_changes = all
    }
}
resource "aci_leaf_profile" "tf_1107_SWPROF" {
    name = "1107_SWPROF"
    leaf_selector {
        name = "1107_LFSEL"
        switch_association_type = "range"
        node_block {
            name = "blk1"
            from_ = "1107"
            to_ = "1107"
        }
    }
    relation_infra_rs_acc_port_p = [aci_leaf_interface_profile.tf_1107_INTPROF.id]
    lifecycle {
        ignore_changes = all
    }
}