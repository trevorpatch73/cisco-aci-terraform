

module "app-mgmt-tenant-config-workflow"{
  source = "./modules/app-mgmt-tenant-config-workflow"
}


/*
module "fabric-node-workflow" {
  source = "./modules/fabric-node-workflow"

  ODD_SPINE_VERSION  = var.ODD_SPINE_VERSION
  EVEN_SPINE_VERSION = var.EVEN_SPINE_VERSION
  ODD_LEAF_VERSION   = var.ODD_LEAF_VERSION
  EVEN_LEAF_VERSION  = var.EVEN_LEAF_VERSION
}


module "fabric-interface-blacklist-workflow" {
  source = "./modules/fabric-interface-blacklist-workflow"
}
*/