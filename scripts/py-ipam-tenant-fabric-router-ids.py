import csv
import os
import sys

def read_endpoint_data(file_path):
    filtered_data = []
    
    with open(file_path, mode='r', newline='', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if all(key in row for key in ['BOND', 'DUAL_HOME', 'ACI_DOMAIN']):
                bond_check = row['BOND'].lower() == "true"
                dual_home_check = row['DUAL_HOME'].lower() == "true"
                aci_domain_check = row['ACI_DOMAIN'].lower() == "l3"

                filtered_data.append(row)
                
    return filtered_data
    
def read_ipam_data(file_path):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return []
    
    if os.stat(file_path).st_size == 0:
        print(f"File is empty: {file_path}")
        return []

    ipam_data = []
    try:
        with open(file_path, mode='r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                ipam_data.append(row)
    except Exception as e:
        print(f"Error reading file: {e}")
    return ipam_data  

def write_csv_file(file_path, data):
    if not data:
        print("No data to write to CSV.")
        exit(1)

    with open(file_path, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)

def is_key_already_assigned(ipam_data, key):
    for ipam_entry in ipam_data:
        if (ipam_entry['ACI_POD_ID'] == key['ACI_POD_ID'] and
            ipam_entry['ACI_NODE_ID'] == key['ACI_NODE_ID'] and
            ipam_entry['TENANT_NAME'] == key['TENANT_NAME'] and
            ipam_entry['MACRO_SEGMENTATION_ZONE'] == key['MACRO_SEGMENTATION_ZONE'] and
            ipam_entry['IP_ADDRESS']):  # Check if IP_ADDRESS is not empty
            return True
    return False

def find_and_update_ipam(data, ipam_data):
    for entry in data:
        if is_key_already_assigned(ipam_data, entry):
            print(f"Entry for {entry} is already assigned an IP address. Skipping.")
            continue
        
        ip_address_assigned = False
        for ipam_entry in ipam_data:
            current_ip = ipam_entry['IP_ADDRESS']
            print(f"Evaluating IP_ADDRESS: {current_ip}")

            if ipam_entry['ACI_NODE_ID'].lower() in ['open', 'free', 'unused', 'available', '']:
                print(f"Updating IP_ADDRESS: {current_ip} with the following data:")
                print(f"ACI_POD_ID: {entry['ACI_POD_ID']}")
                print(f"ACI_NODE_ID: {entry['ACI_NODE_ID']}")
                print(f"TENANT_NAME: {entry['TENANT_NAME']}")
                print(f"MACRO_SEGMENTATION_ZONE: {entry['MACRO_SEGMENTATION_ZONE']}")

                ipam_entry.update({
                    'ACI_POD_ID': entry['ACI_POD_ID'],
                    'ACI_NODE_ID': entry['ACI_NODE_ID'],
                    'TENANT_NAME': entry['TENANT_NAME'],
                    'MACRO_SEGMENTATION_ZONE': entry['MACRO_SEGMENTATION_ZONE']
                })
                ip_address_assigned = True
                break

        if not ip_address_assigned:
            print("No available IP addresses left in the CSV. Please allocate more IP addresses.")
            sys.exit("Exiting: No more IP addresses available.")

def main():
    endpoint_data = read_endpoint_data('./data/endpoint-switchport-configuration.csv')
    print(f"Endpoint Data:")
    print(endpoint_data)
    ipam_data = read_ipam_data('./data/py-ipam-tenant-fabric-router-ids.csv')
    print(f"IPAM Data:")
    print(ipam_data)
    find_and_update_ipam(endpoint_data, ipam_data)
    write_csv_file('./data/py-ipam-tenant-fabric-router-ids.csv', ipam_data)
    
if __name__ == "__main__":
    main()