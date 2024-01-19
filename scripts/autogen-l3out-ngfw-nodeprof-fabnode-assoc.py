import csv
import os

def process_csv(input_file, output_file):
    data = {}
    
    # Read and process the input file
    with open(input_file, mode='r', newline='', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
        for row in reader:
            if row['APPLICATION_NAME'].lower() == 'ngfw':
                key = (row['ACI_POD_ID'], row['TENANT_NAME'], row['MACRO_SEGMENTATION_ZONE'], row['APPLICATION_NAME'])
                node_id = int(row['ACI_NODE_ID'])

                if key not in data:
                    data[key] = {'ODD_NODE_ID': '', 'EVEN_NODE_ID': '', 'ODD_NODE_IP': '', 'EVEN_NODE_IP': ''}

                if node_id % 2 == 0:
                    data[key]['EVEN_NODE_ID'] = row['ACI_NODE_ID']
                    data[key]['EVEN_NODE_IP'] = row['IP_ADDRESS']
                else:
                    data[key]['ODD_NODE_ID'] = row['ACI_NODE_ID']
                    data[key]['ODD_NODE_IP'] = row['IP_ADDRESS']
    
    # Check if output file exists
    file_exists = os.path.exists(output_file)

    # Write to the output file
    with open(output_file, mode='w', newline='', encoding='utf-8') as outfile:
        fieldnames = ['ACI_POD_ID', 'ODD_NODE_ID', 'ODD_NODE_IP', 'EVEN_NODE_ID', 'EVEN_NODE_IP', 'TENANT_NAME', 'MACRO_SEGMENTATION_ZONE', 'APPLICATION_NAME']
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()

        for key, value in data.items():
            writer.writerow({
                'ACI_POD_ID': key[0],
                'TENANT_NAME': key[1],
                'MACRO_SEGMENTATION_ZONE': key[2],
                'APPLICATION_NAME': key[3],
                'ODD_NODE_ID': value['ODD_NODE_ID'],
                'ODD_NODE_IP': value['ODD_NODE_IP'],
                'EVEN_NODE_ID': value['EVEN_NODE_ID'],
                'EVEN_NODE_IP': value['EVEN_NODE_IP']
            })
    
    # Print message based on file existence
    if file_exists:
        print("File autogen-l3out-ngfw-nodeprof-fabnode-assoc.csv overwritten successfully.")
    else:
        print("New file autogen-l3out-ngfw-nodeprof-fabnode-assoc.csv created successfully.")

# Paths to the input and output files
input_file_path = './data/py-ipam-tenant-fabric-router-ids.csv'
output_file_path = './data/autogen-l3out-ngfw-nodeprof-fabnode-assoc.csv'

process_csv(input_file_path, output_file_path)
