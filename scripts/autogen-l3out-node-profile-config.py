import csv
import os
from collections import defaultdict

input_file_path = './data/endpoint-switchport-configuration.csv'


def l3out_nfgw_node_prof_converter():
    
    output_file_path = './data/autogen-l3out-ngfw-node-profile-config.csv'    
    
    file_exists = os.path.exists(output_file_path)
    
    grouped_data = defaultdict(dict)
    
    with open(input_file_path, mode='r', newline='', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
    
        for row in reader:
            if (row['BOND'].lower() == 'true' and
                row['DUAL_HOME'].lower() == 'true' and
                row['ACI_DOMAIN'].lower() == 'l3' and
                row['APPLICATION_NAME'].lower() == 'ngfw'):
                
                key = ( 
                       row['TENANT_NAME'],
                       row['MACRO_SEGMENTATION_ZONE'], 
                       row['ACI_POD_ID']
                       )
    
                aci_node_id = int(row["ACI_NODE_ID"])
                if aci_node_id % 2 == 0:  
                    grouped_data[key]["EVEN_NODE_ID"] = str(aci_node_id) 
                else:  
                    grouped_data[key]["ODD_NODE_ID"] = str(aci_node_id) 
    
    with open(output_file_path, mode='w', newline='', encoding='utf-8') as outfile:
        fieldnames = [
            'ACI_POD_ID',
            'ODD_NODE_ID', 
            'EVEN_NODE_ID',  
            'TENANT_NAME',
            'MACRO_SEGMENTATION_ZONE'
        ]
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
    
        for key, value in grouped_data.items():
            row = {
                'TENANT_NAME': key[0],
                'MACRO_SEGMENTATION_ZONE': key[1],
                'ACI_POD_ID': key[2],
                'ODD_NODE_ID': value.get("ODD_NODE_ID", ""),
                'EVEN_NODE_ID': value.get("EVEN_NODE_ID", "")
            }
            writer.writerow(row)
    
    if file_exists:
        print("Existing CSV file, autogen-l3out-ngfw-node-profile-config.csv, overwritten successfully!")
    else:
        print("Newly formatted CSV file, autogen-l3out-ngfw-node-profile-config.csv, created successfully!")
        
l3out_nfgw_node_prof_converter()
