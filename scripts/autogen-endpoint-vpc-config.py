import csv
import os
from collections import defaultdict

input_file_path = './data/endpoint-switchport-configuration.csv'


def tenant_epg_converter():
    
    output_file_path = './data/autogen-tenant-endpoint-vpc-config.csv'    
    
    file_exists = os.path.exists(output_file_path)
    
    grouped_data = defaultdict(dict)
    
    with open(input_file_path, mode='r', newline='', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
    
        for row in reader:
            if (row['BOND'].lower() == 'true' and
                row['DUAL_HOME'].lower() == 'true' and
                row['MULTI_TENANT'].lower() == 'false' and
                row['ACI_DOMAIN'].lower() == 'phys'):
                
                key = (row['ENDPOINT_NAME'], row['BOND_GROUP'], row['DOT1Q_ENABLE'], 
                       row['TENANT_NAME'], row['APPLICATION_NAME'], row['MACRO_SEGMENTATION_ZONE'], 
                       row['VLAN_ID'], row['ACI_POD_ID'])
    
                aci_node_id = int(row["ACI_NODE_ID"])  # Convert to integer
                if aci_node_id % 2 == 0:  # Check if the node ID is even
                    grouped_data[key]["EVEN_NODE_ID"] = str(aci_node_id)  # Convert back to string
                else:  # Otherwise, it's odd
                    grouped_data[key]["ODD_NODE_ID"] = str(aci_node_id)  # Convert back to string
    
    # Write the new CSV file
    with open(output_file_path, mode='w', newline='', encoding='utf-8') as outfile:
        fieldnames = ['ENDPOINT_NAME', 'BOND_GROUP', 'ODD_NODE_ID', 'EVEN_NODE_ID', 'ACI_POD_ID', 
                      'DOT1Q_ENABLE', 'TENANT_NAME', 'APPLICATION_NAME', 'MACRO_SEGMENTATION_ZONE', 'VLAN_ID']
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
    
        for key, value in grouped_data.items():
            row = {
                'ENDPOINT_NAME': key[0],
                'BOND_GROUP': key[1],
                'DOT1Q_ENABLE': key[2],
                'TENANT_NAME': key[3],
                'APPLICATION_NAME': key[4],
                'MACRO_SEGMENTATION_ZONE': key[5],
                'VLAN_ID': key[6],
                'ACI_POD_ID': key[7],
                'ODD_NODE_ID': value.get("ODD_NODE_ID", ""),
                'EVEN_NODE_ID': value.get("EVEN_NODE_ID", "")
            }
            writer.writerow(row)
    
    if file_exists:
        print("Existing CSV file, autogen-tenant-endpoint-vpc-config.csv, overwritten successfully!")
    else:
        print("Newly formatted CSV file, autogen-tenant-endpoint-vpc-config.csv, created successfully!")


def global_epg_converter():
    
    output_file_path = './data/autogen-global-endpoint-vpc-config.csv'    
    
    file_exists = os.path.exists(output_file_path)
    
    grouped_data = defaultdict(dict)
    
    with open(input_file_path, mode='r', newline='', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
    
        for row in reader:
            if (row['BOND'].lower() == 'true' and
                row['DUAL_HOME'].lower() == 'true' and
                row['MULTI_TENANT'].lower() == 'true' and
                row['ACI_DOMAIN'].lower() == 'phys'):
                
                key = (row['ENDPOINT_NAME'], row['BOND_GROUP'], row['DOT1Q_ENABLE'], 
                       row['TENANT_NAME'], row['APPLICATION_NAME'], row['MACRO_SEGMENTATION_ZONE'], 
                       row['VLAN_ID'], row['ACI_POD_ID'])
    
                aci_node_id = int(row["ACI_NODE_ID"])  # Convert to integer
                if aci_node_id % 2 == 0:  # Check if the node ID is even
                    grouped_data[key]["EVEN_NODE_ID"] = str(aci_node_id)  # Convert back to string
                else:  # Otherwise, it's odd
                    grouped_data[key]["ODD_NODE_ID"] = str(aci_node_id)  # Convert back to string
    
    # Write the new CSV file
    with open(output_file_path, mode='w', newline='', encoding='utf-8') as outfile:
        fieldnames = ['ENDPOINT_NAME', 'BOND_GROUP', 'ODD_NODE_ID', 'EVEN_NODE_ID', 'ACI_POD_ID', 
                      'DOT1Q_ENABLE', 'TENANT_NAME', 'APPLICATION_NAME', 'MACRO_SEGMENTATION_ZONE', 'VLAN_ID']
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
    
        for key, value in grouped_data.items():
            row = {
                'ENDPOINT_NAME': key[0],
                'BOND_GROUP': key[1],
                'DOT1Q_ENABLE': key[2],
                'TENANT_NAME': key[3],
                'APPLICATION_NAME': key[4],
                'MACRO_SEGMENTATION_ZONE': key[5],
                'VLAN_ID': key[6],
                'ACI_POD_ID': key[7],
                'ODD_NODE_ID': value.get("ODD_NODE_ID", ""),
                'EVEN_NODE_ID': value.get("EVEN_NODE_ID", "")
            }
            writer.writerow(row)
        
    if file_exists:
        print("Existing CSV file, autogen-global-endpoint-vpc-config.csv, overwritten successfully!")
    else:
        print("Newly formatted CSV file, autogen-global-endpoint-vpc-config.csv, created successfully!")
        
tenant_epg_converter()
global_epg_converter()