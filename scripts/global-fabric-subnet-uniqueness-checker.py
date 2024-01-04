import csv
import sys

filename = '../data/app-mgmt-tenant-configuration.csv'

def read_csv(file_path):
    with open(file_path, mode='r') as infile:
        reader = csv.DictReader(infile)
        return [row for row in reader]

def check_subnet_uniqueness(data):
    subnet_to_entries = {}
    for row in data:
        subnets = row['SUBNET'].split(';')
        for subnet in subnets:
            key = f"{row['TENANT_NAME']}-{row['APPLICATION_NAME']}-{subnet}"
            if subnet in subnet_to_entries:
                existing_entry = subnet_to_entries[subnet]
                print(f"Subnet {subnet} is assigned to multiple entries: {existing_entry} and {key}")
                return False
            subnet_to_entries[subnet] = key

    return True

data = read_csv(filename)
if check_subnet_uniqueness(data):
    print("No duplicate subnets detected.")
else:
    sys.exit(1)  # Exit with an error code if duplicate subnets are detected

