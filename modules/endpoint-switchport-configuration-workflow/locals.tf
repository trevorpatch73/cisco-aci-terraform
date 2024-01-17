locals {
  iterations = csvdecode(file("./data/endpoint-switchport-configuration.csv"))
  
  distinct_tenants = toset(distinct([for tenant in local.iterations : tenant.TENANT_NAME]))
  
  distinct_switch_nodes = toset(distinct([for node in local.iterations : node.ACI_NODE_ID]))

  AppProf_GroupList = [
    for i in local.iterations : 
      "${i.TENANT_NAME}.${i.MACRO_SEGMENTATION_ZONE}"
    if lower(i.ACI_DOMAIN) == "phys"
  ]
  
  AppProf_UniqueList = distinct(local.AppProf_GroupList)
  
  AppProf_Map = { for item in local.AppProf_UniqueList : 
                  item => {
                    TENANT_NAME             = split(".", item)[0]
                    MACRO_SEGMENTATION_ZONE = split(".", item)[1]
                  }
                }

  AppEpg_GroupList = [
    for i in local.iterations : 
      "${i.TENANT_NAME}.${i.APPLICATION_NAME}.${i.MACRO_SEGMENTATION_ZONE}.${i.VLAN_ID}"
    if lower(i.ACI_DOMAIN) == "phys"
  ]
  
  AppEpg_UniqueList = distinct(local.AppEpg_GroupList)
  
  AppEpg_Map = { for item in local.AppEpg_UniqueList : 
                  item => {
                    TENANT_NAME             = split(".", item)[0]
                    APPLICATION_NAME        = split(".", item)[1]
                    MACRO_SEGMENTATION_ZONE = split(".", item)[2]
                    VLAN_ID                 = split(".", item)[3]
                  }
                }

  PhysInterfaceSelectors_GroupList = {
    for i in local.iterations : "${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}" => [i]...
    if lower(i.ACI_DOMAIN) == "phys"
  }
  
  PhysInterfaceSelectors_FlatList = flatten([
    for key, items in local.PhysInterfaceSelectors_GroupList : 
      [{ 
        ACI_NODE_ID       = items[0][0].ACI_NODE_ID,
        ACI_NODE_SLOT     = items[0][0].ACI_NODE_SLOT,
        ACI_NODE_PORT     = items[0][0].ACI_NODE_PORT
      }]
  ])
  
  PhysInterfaceSelectors_UniqueList = { for idx, i in local.PhysInterfaceSelectors_FlatList : 
    "${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}" => i 
  }  
  
  PhysIntSelectDesc_GroupList = [
    for i in local.iterations : 
      "${i.ENDPOINT_NAME}.${i.ENDPOINT_NIC}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}"
    if lower(i.ACI_DOMAIN) == "phys"
  ]
  
  PhysIntSelectDesc_UniqueList = distinct(local.PhysIntSelectDesc_GroupList)
 
  PhysIntSelectDesc_Map = { for item in local.PhysIntSelectDesc_UniqueList : 
                  item => {
                    ENDPOINT_NAME   = split(".", item)[0]
                    ENDPOINT_NIC    = split(".", item)[1]
                    ACI_NODE_ID     = split(".", item)[2]
                    ACI_NODE_SLOT   = split(".", item)[3]
                    ACI_NODE_PORT   = split(".", item)[4]
                  }
                }
                
  ExternalOutside_GroupList = [
    for i in local.iterations : 
      "${i.TENANT_NAME}.${i.MACRO_SEGMENTATION_ZONE}"
    if lower(i.ACI_DOMAIN) == "l3"
  ]
  
  ExternalOutside_UniqueList = distinct(local.ExternalOutside_GroupList)
  
  ExternalOutside_Map = { for item in local.ExternalOutside_UniqueList : 
                  item => {
                    TENANT_NAME             = split(".", item)[0]
                    MACRO_SEGMENTATION_ZONE = split(".", item)[1]
                  }
                }                
                
######### NONBOND L2 PORTS #########

  TenantAccessPortPolicyGroup_GroupList = {
    for i in local.iterations : "${i.TENANT_NAME}.${i.ENDPOINT_MAKE}.${i.ENDPOINT_MODEL}.${i.ENDPOINT_OS}" => [i]...
    if lower(i.BOND) == "false" && lower(i.MULTI_TENANT) == "false" && lower(i.ACI_DOMAIN) == "phys"
  }
  
  TenantAccessPortPolicyGroup_FlatList = flatten([
    for key, items in local.TenantAccessPortPolicyGroup_GroupList : 
      [{ 
        TENANT_NAME     = items[0][0].TENANT_NAME, 
        ENDPOINT_MAKE   = items[0][0].ENDPOINT_MAKE,
        ENDPOINT_MODEL  = items[0][0].ENDPOINT_MODEL,
        ENDPOINT_OS     = items[0][0].ENDPOINT_OS
      }]
  ])
  
  TenantAccessPortPolicyGroup_UniqueList = { for idx, i in local.TenantAccessPortPolicyGroup_FlatList : 
    "${i.TENANT_NAME}.${i.ENDPOINT_MAKE}.${i.ENDPOINT_MODEL}.${i.ENDPOINT_OS}" => i 
  }
  
  TenantNonBondIntSelectIntPolAssoc_FlatList = flatten([
    for _, groups in local.TenantAccessPortPolicyGroup_GroupList : [
      for group in groups : {
        TENANT_NAME     = group[0]["TENANT_NAME"],
        ENDPOINT_MAKE   = group[0]["ENDPOINT_MAKE"],
        ENDPOINT_MODEL  = group[0]["ENDPOINT_MODEL"],
        ENDPOINT_OS     = group[0]["ENDPOINT_OS"],
        ACI_NODE_ID     = group[0]["ACI_NODE_ID"],
        ACI_NODE_SLOT   = group[0]["ACI_NODE_SLOT"],
        ACI_NODE_PORT   = group[0]["ACI_NODE_PORT"]
      }
    ]
  ])

  TenantNonBondIntSelectIntPolAssoc_UniqueList = { 
    for i in local.TenantNonBondIntSelectIntPolAssoc_FlatList : 
      "${i.ENDPOINT_MAKE}.${i.ENDPOINT_MODEL}.${i.ENDPOINT_OS}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}" => i 
  }
  
  GlobalAccessPortPolicyGroup_GroupList = {
    for i in local.iterations : "GLOBAL.${i.ENDPOINT_MAKE}.${i.ENDPOINT_MODEL}.${i.ENDPOINT_OS}" => [i]...
    if lower(i.BOND) == "false" && lower(i.MULTI_TENANT) == "true" && lower(i.ACI_DOMAIN) == "phys"
  }
  
  GlobalAccessPortPolicyGroup_FlatList = flatten([
    for key, items in local.GlobalAccessPortPolicyGroup_GroupList : 
      [{ 
        TENANT_NAME     = items[0][0].TENANT_NAME, 
        ENDPOINT_MAKE   = items[0][0].ENDPOINT_MAKE,
        ENDPOINT_MODEL  = items[0][0].ENDPOINT_MODEL,
        ENDPOINT_OS     = items[0][0].ENDPOINT_OS
      }]
  ])
  
  GlobalAccessPortPolicyGroup_UniqueList = { for idx, i in local.GlobalAccessPortPolicyGroup_FlatList : 
    "GLOBAL.${i.ENDPOINT_MAKE}.${i.ENDPOINT_MODEL}.${i.ENDPOINT_OS}" => i 
  }
  
  GlobalNonBondIntSelectIntPolAssoc_FlatList = flatten([
    for _, groups in local.GlobalAccessPortPolicyGroup_GroupList : [
      for group in groups : {
        ENDPOINT_MAKE   = group[0]["ENDPOINT_MAKE"],
        ENDPOINT_MODEL  = group[0]["ENDPOINT_MODEL"],
        ENDPOINT_OS     = group[0]["ENDPOINT_OS"],
        ACI_NODE_ID     = group[0]["ACI_NODE_ID"],
        ACI_NODE_SLOT   = group[0]["ACI_NODE_SLOT"],
        ACI_NODE_PORT   = group[0]["ACI_NODE_PORT"]
      }
    ]
  ])

  GlobalNonBondIntSelectIntPolAssoc_UniqueList = { 
    for i in local.GlobalNonBondIntSelectIntPolAssoc_FlatList : 
      "${i.ENDPOINT_MAKE}.${i.ENDPOINT_MODEL}.${i.ENDPOINT_OS}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}" => i 
  } 
  
  PhysNonBondIntSelectAppEpgStaticBind_GroupList = [
    for i in local.iterations : 
      "${i.ACI_POD_ID}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}.${i.DOT1Q_ENABLE}.${i.TENANT_NAME}.${i.APPLICATION_NAME}.${i.MACRO_SEGMENTATION_ZONE}.${i.VLAN_ID}"
    if lower(i.BOND) == "false" && lower(i.ACI_DOMAIN) == "phys"
  ]
  
  PhysNonBondIntSelectAppEpgStaticBind_UniqueList = distinct(local.PhysNonBondIntSelectAppEpgStaticBind_GroupList)
 
  PhysNonBondIntSelectAppEpgStaticBind_Map = { for item in local.PhysNonBondIntSelectAppEpgStaticBind_UniqueList : 
                  item => {
                    ACI_POD_ID              = split(".", item)[0]
                    ACI_NODE_ID             = split(".", item)[1]
                    ACI_NODE_SLOT           = split(".", item)[2]
                    ACI_NODE_PORT           = split(".", item)[3]
                    DOT1Q_ENABLE            = split(".", item)[4]
                    TENANT_NAME             = split(".", item)[5]
                    APPLICATION_NAME        = split(".", item)[6]
                    MACRO_SEGMENTATION_ZONE = split(".", item)[7]
                    VLAN_ID                 = split(".", item)[8]
                  }
                }    
  
######### PORT-CHANNEL L2 PORTS #########

  TenantPortChannelPolicyGroup_GroupList = {
    for i in local.iterations : "${i.TENANT_NAME}.${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => [i]...
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "false" && lower(i.MULTI_TENANT) == "false" && lower(i.ACI_DOMAIN) == "phys"
  }
  
  TenantPortChannelPolicyGroup_FlatList = flatten([
    for key, items in local.TenantPortChannelPolicyGroup_GroupList : 
      [{ 
        TENANT_NAME           = items[0][0].TENANT_NAME, 
        ENDPOINT_NAME         = items[0][0].ENDPOINT_NAME,
        BOND_GROUP            = items[0][0].BOND_GROUP
      }]
  ])
  
  TenantPortChannelPolicyGroup_UniqueList = { for idx, i in local.TenantPortChannelPolicyGroup_FlatList : 
    "${i.TENANT_NAME}.${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => i 
  }
  
  TenantPCIntSelectIntPolAssoc_GroupList = [
    for i in local.iterations : 
      "${i.TENANT_NAME}.${i.ENDPOINT_NAME}.${i.BOND_GROUP}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}"
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "false" && lower(i.MULTI_TENANT) == "false" && lower(i.ACI_DOMAIN) == "phys"
  ]
  
  TenantPCIntSelectIntPolAssoc_UniqueList = distinct(local.TenantPCIntSelectIntPolAssoc_GroupList)
  
  TenantPCIntSelectIntPolAssoc_Map = { for item in local.TenantPCIntSelectIntPolAssoc_UniqueList : 
                  item => {
                    TENANT_NAME   = split(".", item)[0]
                    ENDPOINT_NAME = split(".", item)[1]
                    BOND_GROUP    = split(".", item)[2]
                    ACI_NODE_ID   = split(".", item)[3]
                    ACI_NODE_SLOT = split(".", item)[4]
                    ACI_NODE_PORT = split(".", item)[5]
                  }
                }  
  
  GlobalPortChannelPolicyGroup_GroupList = {
    for i in local.iterations : "Global.${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => [i]...
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "false" && lower(i.MULTI_TENANT) == "true" && lower(i.ACI_DOMAIN) == "phys"
  }
  
  GlobalPortChannelPolicyGroup_FlatList = flatten([
    for key, items in local.GlobalPortChannelPolicyGroup_GroupList : 
      [{ 
        ENDPOINT_NAME         = items[0][0].ENDPOINT_NAME,
        BOND_GROUP            = items[0][0].BOND_GROUP
      }]
  ])
  
  GlobalPortChannelPolicyGroup_UniqueList = { for idx, i in local.GlobalPortChannelPolicyGroup_FlatList : 
    "${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => i 
  }
  
  GlobalPCIntSelectIntPolAssoc_GroupList = [
    for i in local.iterations : 
      "GLOBAL.${i.ENDPOINT_NAME}.${i.BOND_GROUP}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}"
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "false" && lower(i.MULTI_TENANT) == "true" && lower(i.ACI_DOMAIN) == "phys"
  ]
  
  GlobalPCIntSelectIntPolAssoc_UniqueList = distinct(local.GlobalPCIntSelectIntPolAssoc_GroupList)
  
  GlobalPCIntSelectIntPolAssoc_Map = { for item in local.GlobalPCIntSelectIntPolAssoc_UniqueList : 
                  item => {
                    ENDPOINT_NAME = split(".", item)[1]
                    BOND_GROUP    = split(".", item)[2]
                    ACI_NODE_ID   = split(".", item)[3]
                    ACI_NODE_SLOT = split(".", item)[4]
                    ACI_NODE_PORT = split(".", item)[5]
                  }
                }     

######### VIRTUAL PORT-CHANNEL L2 PORTS #########

  TenantVirtualPortChannelPolicyGroup_GroupList = {
    for i in local.iterations : "${i.TENANT_NAME}.${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => [i]...
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "true" && lower(i.MULTI_TENANT) == "false" && lower(i.ACI_DOMAIN) == "phys"
  }
  
  TenantVirtualPortChannelPolicyGroup_FlatList = flatten([
    for key, items in local.TenantVirtualPortChannelPolicyGroup_GroupList : 
      [{ 
        TENANT_NAME           = items[0][0].TENANT_NAME, 
        ENDPOINT_NAME         = items[0][0].ENDPOINT_NAME,
        BOND_GROUP            = items[0][0].BOND_GROUP
      }]
  ])
  
  TenantVirtualPortChannelPolicyGroup_UniqueList = { for idx, i in local.TenantVirtualPortChannelPolicyGroup_FlatList : 
    "${i.TENANT_NAME}.${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => i 
  }
  
  TenantVPCIntSelectIntPolAssoc_GroupList = [
    for i in local.iterations : 
      "${i.TENANT_NAME}.${i.ENDPOINT_NAME}.${i.BOND_GROUP}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}"
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "true" && lower(i.MULTI_TENANT) == "false" && lower(i.ACI_DOMAIN) == "phys"
  ]
  
  TenantVPCIntSelectIntPolAssoc_UniqueList = distinct(local.TenantVPCIntSelectIntPolAssoc_GroupList)
  
  TenantVPCIntSelectIntPolAssoc_Map = { for item in local.TenantVPCIntSelectIntPolAssoc_UniqueList : 
                  item => {
                    TENANT_NAME   = split(".", item)[0]
                    ENDPOINT_NAME = split(".", item)[1]
                    BOND_GROUP    = split(".", item)[2]
                    ACI_NODE_ID   = split(".", item)[3]
                    ACI_NODE_SLOT = split(".", item)[4]
                    ACI_NODE_PORT = split(".", item)[5]
                  }
                }  
  
  GlobalVirtualPortChannelPolicyGroup_GroupList = {
    for i in local.iterations : "Global.${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => [i]...
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "true" && lower(i.MULTI_TENANT) == "true" && lower(i.ACI_DOMAIN) == "phys"
  }
  
  GlobalVirtualPortChannelPolicyGroup_FlatList = flatten([
    for key, items in local.GlobalVirtualPortChannelPolicyGroup_GroupList : 
      [{ 
        ENDPOINT_NAME         = items[0][0].ENDPOINT_NAME,
        BOND_GROUP   = items[0][0].BOND_GROUP
      }]
  ])
  
  GlobalVirtualPortChannelPolicyGroup_UniqueList = { for idx, i in local.GlobalVirtualPortChannelPolicyGroup_FlatList : 
    "${i.ENDPOINT_NAME}.${i.BOND_GROUP}" => i 
  }    
  
  GlobalVPCIntSelectIntPolAssoc_GroupList = [
    for i in local.iterations : 
      "GLOBAL.${i.ENDPOINT_NAME}.${i.BOND_GROUP}.${i.ACI_NODE_ID}.${i.ACI_NODE_SLOT}.${i.ACI_NODE_PORT}"
    if lower(i.BOND) == "true" && lower(i.DUAL_HOME) == "true" && lower(i.MULTI_TENANT) == "true" && lower(i.ACI_DOMAIN) == "phys"
  ]
  
  GlobalVPCIntSelectIntPolAssoc_UniqueList = distinct(local.GlobalVPCIntSelectIntPolAssoc_GroupList)
  
  GlobalVPCIntSelectIntPolAssoc_Map = { for item in local.GlobalVPCIntSelectIntPolAssoc_UniqueList : 
                  item => {
                    ENDPOINT_NAME = split(".", item)[1]
                    BOND_GROUP    = split(".", item)[2]
                    ACI_NODE_ID   = split(".", item)[3]
                    ACI_NODE_SLOT = split(".", item)[4]
                    ACI_NODE_PORT = split(".", item)[5]
                  }
                }
                
  TenantVpcIntSelectEpgAssoc_Iterations   =   csvdecode(file("./data/autogen-tenant-endpoint-vpc-config.csv"))
  
  TenantVpcIntSelectEpgAssoc_List = {
    for i in local.TenantVpcIntSelectEpgAssoc_Iterations :
    "${i.ENDPOINT_NAME}.${i.BOND_GROUP}.${i.ODD_NODE_ID}.${i.EVEN_NODE_ID}.${i.ACI_POD_ID}.${i.DOT1Q_ENABLE}.${i.TENANT_NAME}.${i.APPLICATION_NAME}.${i.MACRO_SEGMENTATION_ZONE}.${i.VLAN_ID}" => {
      ENDPOINT_NAME             = i.ENDPOINT_NAME
      BOND_GROUP                = i.BOND_GROUP
      ODD_NODE_ID               = i.ODD_NODE_ID
      EVEN_NODE_ID              = i.EVEN_NODE_ID
      ACI_POD_ID                = i.ACI_POD_ID
      DOT1Q_ENABLE              = i.DOT1Q_ENABLE
      TENANT_NAME               = i.TENANT_NAME 
      APPLICATION_NAME          = i.APPLICATION_NAME 
      MACRO_SEGMENTATION_ZONE   = i.MACRO_SEGMENTATION_ZONE
      VLAN_ID                   = i.VLAN_ID  
    }
  }  
  
  
  GlobalVpcIntSelectEpgAssoc_Iterations =   csvdecode(file("./data/autogen-global-endpoint-vpc-config.csv"))
  
  GlobalVpcIntSelectEpgAssoc_List = {
    for i in local.GlobalVpcIntSelectEpgAssoc_Iterations :
    "${i.ENDPOINT_NAME}.${i.BOND_GROUP}.${i.ODD_NODE_ID}.${i.EVEN_NODE_ID}.${i.ACI_POD_ID}.${i.DOT1Q_ENABLE}.${i.TENANT_NAME}.${i.APPLICATION_NAME}.${i.MACRO_SEGMENTATION_ZONE}.${i.VLAN_ID}" => {
      ENDPOINT_NAME             = i.ENDPOINT_NAME
      BOND_GROUP                = i.BOND_GROUP
      ODD_NODE_ID               = i.ODD_NODE_ID
      EVEN_NODE_ID              = i.EVEN_NODE_ID
      ACI_POD_ID                = i.ACI_POD_ID
      DOT1Q_ENABLE              = i.DOT1Q_ENABLE
      TENANT_NAME               = i.TENANT_NAME 
      APPLICATION_NAME          = i.APPLICATION_NAME 
      MACRO_SEGMENTATION_ZONE   = i.MACRO_SEGMENTATION_ZONE
      VLAN_ID                   = i.VLAN_ID  
    }
  }

######### VIRTUAL PORT-CHANNEL L3 Out #########

  ExtNodeProf_iterations = csvdecode(file("./data/py-ipam-tenant-fabric-router-ids.csv"))
  
  ExtNodeProf_GroupList = [
    for i in local.ExtNodeProf_iterations : 
      "${i.IP_ADDRESS}:${i.ACI_POD_ID}:${i.ACI_NODE_ID}:${i.TENANT_NAME}:${i.MACRO_SEGMENTATION_ZONE}"
    if (lower(i.ACI_NODE_ID) != "open" && lower(i.ACI_NODE_ID) != "available" && lower(i.ACI_NODE_ID) != "unused" && lower(i.ACI_NODE_ID) != "" && lower(i.ACI_NODE_ID) != null) &&
       (lower(i.ACI_POD_ID) != "open" && lower(i.ACI_POD_ID) != "available" && lower(i.ACI_POD_ID) != "unused" && lower(i.ACI_POD_ID) != "" && lower(i.ACI_POD_ID) != null) &&    
       (lower(i.TENANT_NAME) != "open" && lower(i.TENANT_NAME) != "available" && lower(i.TENANT_NAME) != "unused" && lower(i.TENANT_NAME) != "" && lower(i.TENANT_NAME) != null) &&
       (lower(i.MACRO_SEGMENTATION_ZONE) != "open" && lower(i.MACRO_SEGMENTATION_ZONE) != "available" && lower(i.MACRO_SEGMENTATION_ZONE) != "unused"  && lower(i.MACRO_SEGMENTATION_ZONE) != "" && lower(i.MACRO_SEGMENTATION_ZONE) != null)    
  ]
  
  ExtNodeProf_UniqueList = distinct(local.ExtNodeProf_GroupList)
  
  ExtNodeProf_Map = { for item in local.ExtNodeProf_UniqueList : 
                  item => {
                    IP_ADDRESS              = split(":", item)[0]
                    ACI_POD_ID              = split(":", item)[1]
                    ACI_NODE_ID             = split(":", item)[2]
                    TENANT_NAME             = split(":", item)[3]
                    MACRO_SEGMENTATION_ZONE = split(":", item)[4]
                  }
                }   
}