import csv
import ipaddress
import os
import sys
from collections import defaultdict

def read_ipam_csv(file_path):
    with open(file_path, mode='r', newline='', encoding='utf-8') as file:
        return list(csv.DictReader(file))

def write_ipam_csv(file_path, data, headers):
    file_exists = os.path.exists(file_path)
    mode = 'a' if file_exists else 'w'
    with open(file_path, mode=mode, newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=headers)
        if not file_exists:
            writer.writeheader()
        writer.writerows(data)
    return "appended to" if file_exists else "created"

def generate_ipam_data(source_data, existing_ipam):
    new_data = []
    existing_ips = {row['IP_ADDRESS'] for row in existing_ipam}
    processed_networks = set()

    for row in source_data:
        network_cidr = row['ZONE_TRANSIT_SUBNET']
        tenant_name = row['TENANT_NAME']
        macro_segmentation_zone = row['MACRO_SEGMENTATION_ZONE']
        subnet = ipaddress.ip_network(network_cidr, strict=False)

        network_key = (tenant_name, macro_segmentation_zone, network_cidr)

        if network_key not in processed_networks:
            for ip in subnet.hosts():
                if str(ip) not in existing_ips:
                    new_data.append({
                        "NETWORK_CIDR": network_cidr,
                        "IP_ADDRESS": str(ip),
                        "TENANT_NAME": tenant_name,
                        "MACRO_SEGMENTATION_ZONE": macro_segmentation_zone,
                        "ACI_POD_ID": "OPEN",
                        "ACI_NODE_ID": "OPEN"
                    })
            processed_networks.add(network_key)

    return new_data

def read_ipam_data(file_path):
    ipam_data = {}
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return ipam_data
    if os.stat(file_path).st_size == 0:
        print(f"File is empty: {file_path}")
        return ipam_data
    try:
        with open(file_path, mode='r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                ipam_data[row['IP_ADDRESS']] = row
    except Exception as e:
        print(f"Error reading file: {e}")
    return ipam_data
    
def read_endpoint_data(file_path):
    filtered_data = []
    with open(file_path, mode='r', newline='', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if (row['BOND'].lower() == 'true' and
                row['DUAL_HOME'].lower() == 'true' and
                row['ACI_DOMAIN'].lower() == 'l3' and
                row['APPLICATION_NAME'].lower() == 'ngfw'):
                filtered_data.append(row)
    return filtered_data    
    
def is_key_already_assigned(ipam_data, tenant_name, macro_segmentation_zone, aci_node_id):
    for ipam_entry in ipam_data.values():
        if (ipam_entry['TENANT_NAME'] == tenant_name and
            ipam_entry['MACRO_SEGMENTATION_ZONE'] == macro_segmentation_zone and
            ipam_entry['ACI_NODE_ID'] == aci_node_id):
            return True
    return False

def update_ipam(data, ipam_data):
    for entry in data:
        tenant_name = entry['TENANT_NAME']
        macro_segmentation_zone = entry['MACRO_SEGMENTATION_ZONE']
    
        for component in ['NGFW_A_IP', 'NGFW_B_IP', 'NGFW_FLOAT_IP']:
            component_key = f"{component}"
            if not is_key_already_assigned(ipam_data, tenant_name, macro_segmentation_zone, component_key):
                ip_assigned = False
                for ip, ipam_entry in ipam_data.items():
                    if (ipam_entry['ACI_NODE_ID'].lower() in ['open', 'free', 'unused', 'available', ''] and
                        ipam_entry['TENANT_NAME'] == tenant_name and
                        ipam_entry['MACRO_SEGMENTATION_ZONE'] == macro_segmentation_zone):
                        print(f"Assigning {component}: {ip} to {component_key}")
                        ipam_data[ip].update({
                            'ACI_NODE_ID': component,
                            'ACI_POD_ID': entry['ACI_POD_ID'],
                            'TENANT_NAME': tenant_name,
                            'MACRO_SEGMENTATION_ZONE': macro_segmentation_zone
                        })
                        ip_assigned = True
                        break
                if not ip_assigned:
                    print(f"No available IPs left in IPAM for {component_key}.")
        
        
        aci_node_id = int(entry["ACI_NODE_ID"])

        if aci_node_id % 2 == 0:
            even_node_id = aci_node_id
            odd_node_id = aci_node_id - 1
        else:
            odd_node_id = aci_node_id
            even_node_id = aci_node_id + 1

        entry['ODD_NODE_ID'] = str(odd_node_id)
        entry['EVEN_NODE_ID'] = str(even_node_id)

        print(f"Processing entry: ODD_NODE_ID: {odd_node_id}, EVEN_NODE_ID: {even_node_id}")

        for node_id in [str(odd_node_id), str(even_node_id)]:
            print(f"Processing NODE_ID: {node_id} for {entry['TENANT_NAME']} {entry['MACRO_SEGMENTATION_ZONE']}")
            if not is_key_already_assigned(ipam_data, entry['TENANT_NAME'], entry['MACRO_SEGMENTATION_ZONE'], node_id):
                ip_assigned = False
                for ip, ipam_entry in ipam_data.items():
                    if (ipam_entry['ACI_NODE_ID'].lower() in ['open', 'free', 'unused', 'available', ''] and
                        ipam_entry['TENANT_NAME'] == entry['TENANT_NAME'] and
                        ipam_entry['MACRO_SEGMENTATION_ZONE'] == entry['MACRO_SEGMENTATION_ZONE']):
                        print(f"Assigning IP_ADDRESS: {ip} to NODE_ID: {node_id}")
                        ipam_data[ip].update({
                            'ACI_NODE_ID': node_id,
                            'ACI_POD_ID': entry['ACI_POD_ID'],
                            'TENANT_NAME': entry['TENANT_NAME'],
                            'MACRO_SEGMENTATION_ZONE': entry['MACRO_SEGMENTATION_ZONE']
                        })
                        ip_assigned = True
                        break
                if not ip_assigned:
                    print(f"No available IPs left in IPAM for node {node_id}.")

        sec_ip_key = f"{odd_node_id}_{even_node_id}_SEC_IP"
        if not is_key_already_assigned(ipam_data, entry['TENANT_NAME'], entry['MACRO_SEGMENTATION_ZONE'], sec_ip_key):
            ip_assigned = False
            for ip, ipam_entry in ipam_data.items():
                if (ipam_entry['ACI_NODE_ID'].lower() in ['open', 'free', 'unused', 'available', ''] and
                    ipam_entry['TENANT_NAME'] == entry['TENANT_NAME'] and
                    ipam_entry['MACRO_SEGMENTATION_ZONE'] == entry['MACRO_SEGMENTATION_ZONE']):
                    print(f"Assigning Secondary IP_ADDRESS: {ip} to KEY: {sec_ip_key} for {entry['TENANT_NAME']} {entry['MACRO_SEGMENTATION_ZONE']}")
                    ipam_data[ip].update({
                        'ACI_NODE_ID': sec_ip_key,
                        'ACI_POD_ID': entry['ACI_POD_ID'],
                        'TENANT_NAME': entry['TENANT_NAME'],
                        'MACRO_SEGMENTATION_ZONE': entry['MACRO_SEGMENTATION_ZONE']
                    })
                    ip_assigned = True
                    break
            if not ip_assigned:
                print(f"No available secondary IPs left in IPAM for key {sec_ip_key}.")

def update_ipam_write_csv_file(file_path, data):
    if not data:
        print("No data to write to CSV.")
        return
    with open(file_path, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=data[0].keys())
        writer.writeheader()
        for entry in data:  # Directly iterate over data
            writer.writerow(entry)
            
def l3out_ngfw_converter(endpoint_data, output_file_path):
    grouped_data = defaultdict(dict)

    for row in endpoint_data:
        key = (row['ENDPOINT_NAME'], row['BOND_GROUP'], row['TENANT_NAME'], 
               row['MACRO_SEGMENTATION_ZONE'], row['ACI_POD_ID'], row['VLAN_ID'])
        aci_node_id = int(row["ACI_NODE_ID"])

        if aci_node_id % 2 == 0: 
            grouped_data[key]["EVEN_NODE_ID"] = str(aci_node_id)
        else:
            grouped_data[key]["ODD_NODE_ID"] = str(aci_node_id)

        grouped_data[key]['ODD_NODE_IP'] = ''
        grouped_data[key]['EVEN_NODE_IP'] = ''
        grouped_data[key]["SECONDARY_IP"] = ''
        grouped_data[key]["NGFW_A_IP"] = ''
        grouped_data[key]["NGFW_B_IP"] = ''
        grouped_data[key]["NGFW_FLOAT_IP"] = ''

        grouped_data[key]["MULTI_TENANT"] = row.get('MULTI_TENANT', '')

    with open(output_file_path, mode='w', newline='', encoding='utf-8') as outfile:
        fieldnames = ['ENDPOINT_NAME', 'BOND_GROUP', 'ODD_NODE_ID', 'ODD_NODE_IP', 
                      'EVEN_NODE_ID', 'EVEN_NODE_IP', 'SECONDARY_IP', 'MULTI_TENANT', 
                      'ACI_POD_ID', 'TENANT_NAME', 'MACRO_SEGMENTATION_ZONE', 'VLAN_ID',
                      'NGFW_A_IP', 'NGFW_B_IP', 'NGFW_FLOAT_IP']  # Updated fieldnames
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()

        for key, values in grouped_data.items():
            row = {
                'ENDPOINT_NAME': key[0],
                'BOND_GROUP': key[1],
                'ODD_NODE_ID': values.get('ODD_NODE_ID', ''),
                'ODD_NODE_IP': values.get('ODD_NODE_IP', ''),
                'EVEN_NODE_ID': values.get('EVEN_NODE_ID', ''),
                'EVEN_NODE_IP': values.get('EVEN_NODE_IP', ''),
                'SECONDARY_IP': values.get('SECONDARY_IP', ''),
                'MULTI_TENANT': values.get('MULTI_TENANT', ''),
                'ACI_POD_ID': key[4],
                'TENANT_NAME': key[2],
                'MACRO_SEGMENTATION_ZONE': key[3],
                'VLAN_ID': key[5],
                'NGFW_A_IP': '',
                'NGFW_B_IP': '',
                'NGFW_FLOAT_IP': ''
            }
            writer.writerow(row)

    print(f"CSV file {output_file_path} has been created successfully.")
            
def assign_ips(input_file, output_file):
    existing_data = []
    if os.path.exists(output_file):
        with open(output_file, mode='r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            for row in reader:
                existing_data.append(row)
        print("Existing data read from output file.")

    with open(input_file, mode='r', newline='', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
        for row in reader:
            cidr_suffix = row['NETWORK_CIDR'].split('/')[-1]
            updated_ip_address = f"{row['IP_ADDRESS']}/{cidr_suffix}"

            for existing_row in existing_data:
                if (existing_row['TENANT_NAME'] == row['TENANT_NAME'] and 
                    existing_row['MACRO_SEGMENTATION_ZONE'] == row['MACRO_SEGMENTATION_ZONE']):
                    print(f"Found matching row for TENANT_NAME: {row['TENANT_NAME']}, MACRO_SEGMENTATION_ZONE: {row['MACRO_SEGMENTATION_ZONE']}")

                    # Update Node IPs
                    if row['ACI_NODE_ID'] == existing_row['ODD_NODE_ID']:
                        print(f"Updating ODD_NODE_IP for NODE_ID: {row['ACI_NODE_ID']}")
                        existing_row['ODD_NODE_IP'] = updated_ip_address
                    elif row['ACI_NODE_ID'] == existing_row['EVEN_NODE_ID']:
                        print(f"Updating EVEN_NODE_IP for NODE_ID: {row['ACI_NODE_ID']}")
                        existing_row['EVEN_NODE_IP'] = updated_ip_address
                    elif row['ACI_NODE_ID'] == existing_row['ODD_NODE_ID'] + "_" + existing_row['EVEN_NODE_ID'] + "_SEC_IP":
                        print(f"Updating SECONDARY_IP for NODE_ID: {row['ACI_NODE_ID']}")
                        existing_row['SECONDARY_IP'] = updated_ip_address

                    # Update NGFW IPs
                    elif row['ACI_NODE_ID'] == 'NGFW_A_IP':
                        print(f"Updating NGFW_A_IP for TENANT_NAME: {row['TENANT_NAME']}, MACRO_SEGMENTATION_ZONE: {row['MACRO_SEGMENTATION_ZONE']}")
                        existing_row['NGFW_A_IP'] = updated_ip_address
                    elif row['ACI_NODE_ID'] == 'NGFW_B_IP':
                        print(f"Updating NGFW_B_IP for TENANT_NAME: {row['TENANT_NAME']}, MACRO_SEGMENTATION_ZONE: {row['MACRO_SEGMENTATION_ZONE']}")
                        existing_row['NGFW_B_IP'] = updated_ip_address
                    elif row['ACI_NODE_ID'] == 'NGFW_FLOAT_IP':
                        print(f"Updating NGFW_FLOAT_IP for TENANT_NAME: {row['TENANT_NAME']}, MACRO_SEGMENTATION_ZONE: {row['MACRO_SEGMENTATION_ZONE']}")
                        existing_row['NGFW_FLOAT_IP'] = updated_ip_address

    with open(output_file, mode='w', newline='', encoding='utf-8') as outfile:
        fieldnames = ['ENDPOINT_NAME','BOND_GROUP','ODD_NODE_ID','ODD_NODE_IP','EVEN_NODE_ID','EVEN_NODE_IP','SECONDARY_IP','MULTI_TENANT','ACI_POD_ID','TENANT_NAME','MACRO_SEGMENTATION_ZONE','VLAN_ID', 'NGFW_A_IP', 'NGFW_B_IP', 'NGFW_FLOAT_IP']
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(existing_data)
        print("Updated data written back to the output file.")

    print("assign_ips function completed.")

def main():
    source_ipam_file = './data/tenant-configuration.csv'
    destination_ipam_file = './data/autogen-l3out-ngfw-transit-ipam.csv'
    ipam_headers = ["NETWORK_CIDR", "IP_ADDRESS", "TENANT_NAME", "MACRO_SEGMENTATION_ZONE", "ACI_POD_ID", "ACI_NODE_ID"]

    source_data = read_ipam_csv(source_ipam_file)
    existing_ipam = read_ipam_csv(destination_ipam_file) if os.path.exists(destination_ipam_file) else []
    new_ipam_data = generate_ipam_data(source_data, existing_ipam)

    message = write_ipam_csv(destination_ipam_file, new_ipam_data, ipam_headers)
    print(f"The file {destination_ipam_file} was {message} successfully.")
    
    ipam_data = read_ipam_data('./data/autogen-l3out-ngfw-transit-ipam.csv')
    endpoint_data = read_endpoint_data('./data/endpoint-switchport-configuration.csv')
    update_ipam(endpoint_data, ipam_data)
    update_ipam_write_csv_file('./data/autogen-l3out-ngfw-transit-ipam.csv', list(ipam_data.values()))
    l3out_ngfw_converter(endpoint_data, './data/autogen-l3out-ngfw-vpc-config.csv')
    assign_ips('./data/autogen-l3out-ngfw-transit-ipam.csv','./data/autogen-l3out-ngfw-vpc-config.csv')


if __name__ == "__main__":
    main()
