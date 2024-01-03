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
        if vlan_id not in vlan_to_tenants:
            vlan_to_tenants[vlan_id] = [tenant_name]
        elif tenant_name not in vlan_to_tenants[vlan_id]:
            vlan_to_tenants[vlan_id].append(tenant_name)
            print(f"VLAN ID {vlan_id} is assigned to multiple tenants: {', '.join(vlan_to_tenants[vlan_id])}")
            return False
    return True

data = read_csv(filename)
if check_vlan_uniqueness(data):
    print("No duplicate VLAN IDs detected.")
else:
    sys.exit(1)  # Exit with an error code if VLAN IDs are not unique
