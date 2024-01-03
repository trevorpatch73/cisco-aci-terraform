import csv
import sys

filename = '../data/app-mgmt-tenant-configuration.csv'

def read_csv(file_path):
    with open(file_path, mode='r') as infile:
        reader = csv.DictReader(infile)
        return [row for row in reader]

def check_vlan_uniqueness(data):
    vlan_to_tenants = {}
    for row in data:
        vlan_id = row['VLAN_ID']
        tenant_name = row['TENANT_NAME']
        application_name = row['APPLICATION_NAME']

        if vlan_id in vlan_to_tenants:
            if tenant_name != vlan_to_tenants[vlan_id]['tenant_name']:
                print(f"VLAN ID {vlan_id} is assigned to multiple tenants: {vlan_to_tenants[vlan_id]['tenant_name']} and {tenant_name}")
                return False
            if application_name != vlan_to_tenants[vlan_id]['application_name']:
                print(f"VLAN ID {vlan_id} is assigned to multiple applications within tenant {tenant_name}: {vlan_to_tenants[vlan_id]['application_name']} and {application_name}")
                return False
        else:
            vlan_to_tenants[vlan_id] = {'tenant_name': tenant_name, 'application_name': application_name}

    return True

data = read_csv(filename)
if check_vlan_uniqueness(data):
    print("No duplicate VLAN IDs detected.")
else:
    sys.exit(1)  # Exit with an error code if VLAN IDs are not
