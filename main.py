import requests
import jinja2
import json
import os
import csv
import re

from jinja2 import Template

requests.packages.urllib3.disable_warnings()

ACI_BASE_URL = os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS')
USERNAME = os.environ.get('TF_VAR_CISCO_ACI_TERRAFORM_USERNAME')
PASSWORD = os.environ.get('TF_VAR_CISCO_ACI_TERRAFORM_PASSWORD')

#############################
### BASE FUNCTIONALITY    ###
#############################

def terraform_import_file():
    filename = "import.tf"
    
    if not os.path.exists(filename):
        with open(filename, 'w') as file:
            file.write("# This is the Terraform import file\n")
        print(f"'{filename}' created.")
    else:
        print(f"'{filename}' already exists.")
        
def terraform_command_file():
    filename = "import_commands.txt"
    
    if not os.path.exists(filename):
        with open(filename, 'w') as file:
            file.write("\n")
        print(f"'{filename}' created.")
    else:
        print(f"'{filename}' already exists.")
        
def get_aci_token():
    LOGIN_URL = f"{ACI_BASE_URL}/api/aaaLogin.json"
    
    headers = {
        "Content-Type": "application/json"
    }

    payload = {
        "aaaUser": {
            "attributes": {
                "name": USERNAME,
                "pwd": PASSWORD
            }
        }
    }
    
    response = requests.post(LOGIN_URL, json=payload, headers=headers, verify=False)
    
    if response.status_code == 200:
        token = response.json()['imdata'][0]['aaaLogin']['attributes']['token']
        print(f"Successfully Authenticated to APIC - {os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS')} with account - {USERNAME}")
        return token
    else:
        print(f"Error: {response.status_code}")
        return None
        
#################################
### ACI FABRIC NODE MEMBER    ###
#################################
        
def fabric_inventory_file():
    directory = "data"
    filename = os.path.join(directory, "py_fabric_inventory.csv")
    headers = [
        "APIC", "adSt", "address", "annotation", "apicType", "childAction", 
        "delayedHeartbeat", "dn", "extMngdBy", "fabricSt", "id", "lastStateModTs", 
        "lcOwn", "modTs", "model", "monPolDn", "name", "nameAlias", "nodeType", 
        "role", "serial", "status", "uid", "userdom", "vendor", "version"
    ]
    
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")
         
    else:
        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            current_headers = next(reader)

        if set(headers) != set(current_headers):
            print(f"'{filename}' does not have the correct headers. You may want to regenerate it.")

            with open(filename, 'w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(headers)
            print(f"'{filename}' has been recreated with the required headers.")

def get_fabric_nodes(token):
    URL = f"{ACI_BASE_URL}/api/node/class/fabricNode.json"
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(URL, headers=headers, verify=False)
    
    if response.status_code == 403:
        print("Received a 403 error. Refreshing token...")
        token = get_aci_token()
        headers["Cookie"] = f"APIC-Cookie={token}"
        response = requests.get(URL, headers=headers, verify=False)

    filename = os.path.join("data", "py_fabric_inventory.csv")

    if response.status_code == 200:
        data = response.json()

        existing_entries = []
        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            if entry["fabricNode"]["attributes"]["role"] == "controller":
                continue

            attributes = entry["fabricNode"]["attributes"]

            row_as_list = [
                os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                attributes.get("adSt"),
                attributes.get("address"),
                attributes.get("annotation"),
                attributes.get("apicType"),
                attributes.get("childAction"),
                attributes.get("delayedHeartbeat"),
                attributes.get("dn"),
                attributes.get("extMngdBy"),
                attributes.get("fabricSt"),
                attributes.get("id"),
                attributes.get("lastStateModTs"),
                attributes.get("lcOwn"),
                attributes.get("modTs"),
                attributes.get("model"),
                attributes.get("monPolDn"),
                attributes.get("name"),
                attributes.get("nameAlias"),
                attributes.get("nodeType"),
                attributes.get("role"),
                attributes.get("serial"),
                attributes.get("status"),
                attributes.get("uid"),
                attributes.get("userdom"),
                attributes.get("vendor"),
                attributes.get("version")
            ]

            if row_as_list not in existing_entries:
                existing_entries.append(row_as_list)

        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
            
    else:
        print(f"Failed to retrieve fabric nodes. Status code: {response.status_code}")
        
def tf_ciscodevnet_aci_fabric_node_member():
    csv_filepath = os.path.join("data", "py_fabric_inventory.csv")
    
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    terraform_template = """
resource "aci_fabric_node_member" "Node{{id}}_{{serial}}" {
    name        = "{{name}}"
    serial      = "{{serial}}"
    
    lifecycle {
        ignore_changes = all
    }
}
"""

    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0) 
        existing_content = tf_file.read()

    template = Template(terraform_template)
    new_terraform_content = ""

    for entry in entries:
        terraform_block = template.render(
            id=entry['id'],
            name=entry['name'],
            serial=entry['serial']
        )
        if terraform_block not in existing_content:
            new_terraform_content += terraform_block

    with open('import.tf', 'a') as tf_file:
        tf_file.write(new_terraform_content)

    print("Terraform resources, aci_fabric_node_member, appended to import.tf successfully!")
    
def tf_ciscodevnet_aci_fabric_node_member_commands():
    csv_filepath = os.path.join("data", "py_fabric_inventory.csv")
    
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    import_command_template = "terraform import aci_fabric_node_member.Node{}_{} uni/controller/nodeidentpol/nodep-{}\n"

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_commands = cmd_file.readlines()

    new_commands = ""
    for entry in entries:
        command = import_command_template.format(entry['id'], entry['serial'], entry['serial'])
        if command not in existing_commands:
            new_commands += command

    with open('import_commands.txt', 'a') as cmd_file:
        cmd_file.write(new_commands)
            
########################################
### ACI FABRIC INTERFACE BLACKLIST   ###
########################################
            
def fabric_blacklist_interfaces_file():
    directory = "data"
    filename = os.path.join(directory, "py_fabric_blacklist_interfaces.csv")
    headers = [
        "APIC", "annotation", "childaction", "dn", "extMngdBy", "forceResolve", 
        "lc", "lcOwn", "modTs", "monPolDn", "rType", "state", "stateQual", "status", 
        "tCl", "tDn", "tType", "uid", "userdom"
    ]
    
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")
         
    else:
        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            current_headers = next(reader)

        if set(headers) != set(current_headers):
            print(f"'{filename}' does not have the correct headers. You may want to regenerate it.")

            with open(filename, 'w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(headers)
            print(f"'{filename}' has been recreated with the required headers.")
        
def get_fabric_blacklist_interfaces(token):
    URL = f'{ACI_BASE_URL}/api/node/class/fabricRsOosPath.json?query-target-filter=and(not(wcard(fabricRsOosPath.dn,"__ui_")),ne(fabricRsOosPath.lc,"in-service"))'
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(URL, headers=headers, verify=False)
    
    if response.status_code == 403:
        print("Received a 403 error. Refreshing token...")
        token = get_aci_token()
        headers["Cookie"] = f"APIC-Cookie={token}"
        response = requests.get(URL, headers=headers, verify=False)

    if response.status_code == 200:
        data = response.json()

        existing_entries = []
        with open(os.path.join('data', 'py_fabric_blacklist_interfaces.csv'), 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            attributes = entry["fabricRsOosPath"]["attributes"]
            row_as_list = [
                os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                attributes.get("annotation"),
                attributes.get("childAction"),
                attributes.get("dn"),
                attributes.get("extMngdBy"),
                attributes.get("forceResolve"),
                attributes.get("lc"),
                attributes.get("lcOwn"),
                attributes.get("modTs"),
                attributes.get("monPolDn"),
                attributes.get("rType"),
                attributes.get("state"),
                attributes.get("stateQual"),
                attributes.get("status"),
                attributes.get("tCl"),
                attributes.get("tDn"),
                attributes.get("tType"),
                attributes.get("uid"),
                attributes.get("userdom"),
            ]
            if row_as_list not in existing_entries:
                existing_entries.append(row_as_list)

        with open(os.path.join('data', 'py_fabric_blacklist_interfaces.csv'), 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve fabric blacklist interfaces. Status code: {response.status_code}")

def parse_tdn(tdn):
    match = re.search(r"pod-(\d+)/paths-(\d+)(?:/extpaths-(\d+))?/pathep-\[(.+)\]", tdn)
    if match:
        return match.groups()
    return None, None, None, None

def tf_ciscodevnet_aci_interface_blacklist():
    with open(os.path.join('data', 'py_fabric_blacklist_interfaces.csv'), 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    template_fex = Template("""
resource "aci_interface_blacklist" "P{{pod_id}}_N{{node_id}}_F{{fex_id}}_{{interface_name}}" {
    pod_id    = "{{pod_id}}"
    node_id   = "{{node_id}}"
    fex_id    = "{{fex_id}}"
    interface = "{{interface}}"
  
    lifecycle {
        ignore_changes = all
    }
}
""")
    template_no_fex = Template("""
resource "aci_interface_blacklist" "P{{pod_id}}_N{{node_id}}_{{interface_name}}" {
    pod_id    = "{{pod_id}}"
    node_id   = "{{node_id}}"
    interface = "{{interface}}"
  
    lifecycle {
        ignore_changes = all
    }  
}
""")
    
    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0)
        existing_content = tf_file.read()

    new_terraform_content = ""

    for entry in entries:
        pod_id, node_id, fex_id, interface = parse_tdn(entry['tDn'])

        if not interface:
            print(f"Warning: Could not parse tDn for entry {entry['tDn']}")
            continue

        interface_name = interface.replace("/", "_")  # Change / to _ for the resource name
        if "extpaths" in entry['tDn']:
            terraform_block = template_fex.render(pod_id=pod_id, node_id=node_id, fex_id=fex_id, interface=interface, interface_name=interface_name)
        else:
            terraform_block = template_no_fex.render(pod_id=pod_id, node_id=node_id, interface=interface, interface_name=interface_name)

        if terraform_block not in existing_content:
            new_terraform_content += terraform_block

    with open('import.tf', 'a') as tf_file:
        tf_file.write(new_terraform_content)

    print("Terraform resources, aci_interface_blacklist, appended to import.tf successfully!")

def tf_ciscodevnet_aci_interface_blacklist_commands():
    with open(os.path.join('data', 'py_fabric_blacklist_interfaces.csv'), 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    template_fex = Template("""
terraform import aci_interface_blacklist.P{{pod_id}}_N{{node_id}}_F{{fex_id}}_{{interface_name}} uni/fabric/outofsvc/rsoosPath-[topology/pod-{{pod_id}}/extpaths-{{fex_id}}/paths-{{node_id}}/pathep-[{{interface}}]]
""")
    template_no_fex = Template("""
terraform import aci_interface_blacklist.P{{pod_id}}_N{{node_id}}_{{interface_name}} uni/fabric/outofsvc/rsoosPath-[topology/pod-{{pod_id}}/paths-{{node_id}}/pathep-[{{interface}}]]
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_commands = cmd_file.readlines()

    new_commands = ""

    for entry in entries:
        pod_id, node_id, fex_id, interface = parse_tdn(entry['tDn'])

        if not interface:
            print(f"Warning: Could not parse tDn for entry {entry['tDn']}")
            continue

        interface_name = interface.replace("/", "_")  # Change / to _ for the resource name

        if "extpaths" in entry['tDn']:
            command = template_fex.render(pod_id=pod_id, node_id=node_id, fex_id=fex_id, interface=interface, interface_name=interface_name)
        else:
            command = template_no_fex.render(pod_id=pod_id, node_id=node_id, interface=interface, interface_name=interface_name)

        if command not in existing_commands:
            new_commands += command

    with open('import_commands.txt', 'a') as cmd_file:
        cmd_file.write(new_commands)

    print("Import commands for aci_interface_blacklist appended to import_commands.txt successfully!")
    
########################################################
### ACI ACCESS POLICIES ATTACHABLE ENTITY PROFILE    ###
########################################################

def access_policy_aaep_file():
    directory = "data"
    filename = os.path.join(directory, "py_access_policy_aaep.csv")
    headers = [
        "APIC","annotation", "childAction", "configIssues", "creator", "descr", "dn", 
        "extMngdBy", "lcOwn", "modTs", "monPolDn", "name", "nameAlias", 
        "ownerKey", "ownerTag", "status", "uid", "userdom"
    ]
    
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")
         
    else:
        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            current_headers = next(reader)

        if set(headers) != set(current_headers):
            print(f"'{filename}' does not have the correct headers. You may want to regenerate it.")

            with open(filename, 'w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(headers)
            print(f"'{filename}' has been recreated with the required headers.")

def get_access_policy_aaep(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraAttEntityP"
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(URL, headers=headers, verify=False)
    
    if response.status_code == 403:
        print("Received a 403 error. Refreshing token...")
        token = get_aci_token()
        headers["Cookie"] = f"APIC-Cookie={token}"
        response = requests.get(URL, headers=headers, verify=False)

    filename = os.path.join("data", "py_fabric_inventory.csv")

    if response.status_code == 200:
        data = response.json()

        existing_entries = []
        with open(os.path.join('data', 'py_access_policy_aaep.csv'), 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            attributes = entry["infraAttEntityP"]["attributes"]
            row_as_list = [
                os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                attributes.get("annotation"),
                attributes.get("childAction"),
                attributes.get("configIssues"),
                attributes.get("creator"),
                attributes.get("descr"),
                attributes.get("dn"),
                attributes.get("extMngdBy"),
                attributes.get("lcOwn"),
                attributes.get("modTs"),
                attributes.get("monPolDn"),
                attributes.get("name"),
                attributes.get("nameAlias"),
                attributes.get("ownerKey"),
                attributes.get("ownerTag"),
                attributes.get("status"),
                attributes.get("uid"),
                attributes.get("userdom"),
            ]
            if row_as_list not in existing_entries:
                existing_entries.append(row_as_list)

        with open(os.path.join('data', 'py_access_policy_aaep.csv'), 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve access policies aaep. Status code: {response.status_code}")
        
def tf_ciscodevnet_aci_access_policy_aaep():
    csv_filepath = os.path.join("data", "py_access_policy_aaep.csv")
    
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    terraform_template = """
resource "aci_attachable_access_entity_profile" "{{name}}" {
    name        = "{{name}}"
    
    lifecycle {
        ignore_changes = all
    }
}
"""

    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0) 
        existing_content = tf_file.read()

    template = Template(terraform_template)
    new_terraform_content = ""

    for entry in entries:
        terraform_block = template.render(
            name=entry['name']
        )
        if terraform_block not in existing_content:
            new_terraform_content += terraform_block

    with open('import.tf', 'a') as tf_file:
        tf_file.write(new_terraform_content)

    print("Terraform resources, aci_attachable_access_entity_profile, appended to import.tf successfully!")
    
def tf_ciscodevnet_aci_access_policy_aaep_commands():
    with open(os.path.join('data', 'py_access_policy_aaep.csv'), 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_attachable_access_entity_profile.{{name}} uni/infra/attentp-{{name}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.readlines()

    new_commands = ""
    
    for entry in entries:
        terraform_block = command_template.render(
            name=entry['name']
        )
        if terraform_block not in existing_content:
            new_commands += terraform_block

    with open('import_commands.txt', 'a') as tf_file:
        tf_file.write(new_commands)

    print("Import commands for aci_attachable_access_entity_profile appended to import_commands.txt successfully!")

########################################################
### ACI ACCESS POLICIES PHYSICAL DOMAIN              ###
########################################################

def physical_domain_file():
    directory = "data"
    filename = os.path.join(directory, "py_physical_domain.csv")
    headers = [
        "APIC","annotation", "childAction", "configIssues", "dn", 
        "extMngdBy", "lcOwn", "modTs", "monPolDn", "name", "nameAlias", 
        "ownerKey", "ownerTag", "status", "uid", "userdom"
    ]
    
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")
         
    else:
        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            current_headers = next(reader)

        if set(headers) != set(current_headers):
            print(f"'{filename}' does not have the correct headers. You may want to regenerate it.")

            with open(filename, 'w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(headers)
            print(f"'{filename}' has been recreated with the required headers.")

def get_physical_domain(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni.json?query-target=subtree&target-subtree-class=physDomP"
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(URL, headers=headers, verify=False)
    
    if response.status_code == 403:
        print("Received a 403 error. Refreshing token...")
        token = get_aci_token()
        headers["Cookie"] = f"APIC-Cookie={token}"
        response = requests.get(URL, headers=headers, verify=False)

    filename = os.path.join("data", "py_physical_domain.csv")

    if response.status_code == 200:
        data = response.json()

        existing_entries = []
        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            attributes = entry["physDomP"]["attributes"]
            row_as_list = [
                os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                attributes.get("annotation"),
                attributes.get("childAction"),
                attributes.get("configIssues"),
                attributes.get("dn"),
                attributes.get("extMngdBy"),
                attributes.get("lcOwn"),
                attributes.get("modTs"),
                attributes.get("monPolDn"),
                attributes.get("name"),
                attributes.get("nameAlias"),
                attributes.get("ownerKey"),
                attributes.get("ownerTag"),
                attributes.get("status"),
                attributes.get("uid"),
                attributes.get("userdom"),
            ]
            if row_as_list not in existing_entries:
                existing_entries.append(row_as_list)

        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve physical domains. Status code: {response.status_code}")

def tf_ciscodevnet_aci_physical_domain():
    csv_filepath = os.path.join("data", "py_physical_domain.csv")
    
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    terraform_template = """
resource "aci_physical_domain" "{{name}}" {
    name        = "{{name}}"
    
    lifecycle {
        ignore_changes = all
    }
}
"""

    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0) 
        existing_content = tf_file.read()

    template = Template(terraform_template)
    new_terraform_content = ""

    for entry in entries:
        terraform_block = template.render(
            name=entry['name']
        )
        if terraform_block not in existing_content:
            new_terraform_content += terraform_block

    with open('import.tf', 'a') as tf_file:
        tf_file.write(new_terraform_content)

    print("Terraform resources, aci_physical_domain, appended to import.tf successfully!")

def tf_ciscodevnet_aci_physical_domain_commands():
    with open(os.path.join('data', 'py_physical_domain.csv'), 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_physical_domain.{{name}} {{dn}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.readlines()

    new_commands = ""
    
    for entry in entries:
        terraform_block = command_template.render(
            name=entry['name'],
            dn=entry['dn']
        )
        if terraform_block not in existing_content:
            new_commands += terraform_block

    with open('import_commands.txt', 'a') as tf_file:
        tf_file.write(new_commands)

    print("Import commands for aci_physical_domain appended to import_commands.txt successfully!")
    
########################################################
### ACI ACCESS POLICIES AAEP to PHYSICAL DOMAIN      ###
########################################################

def aaep_to_domain_file():
    directory = "data"
    filename = os.path.join(directory, "py_aaep_to_physdomain.csv")
    headers = [
        "APIC","infraAttEntityP_name", "infraAttEntityP_dn", 
        "infraRsDomP_name", "infraRsDomP_rn"
    ]
    
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")

def get_aaep_to_domain(token):
    # Updated URL
    URL = f"{ACI_BASE_URL}/api/node/mo/uni/infra.json?query-target=children&target-subtree-class=infraAttEntityP&rsp-subtree=children&rsp-subtree-class=infraRsDomP&rsp-subtree-filter=eq(infraRsDomP.tCl,\"physDomP\")"
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(URL, headers=headers, verify=False)
    filename = os.path.join("data", "py_aaep_to_physdomain.csv")

    if response.status_code == 200:
        data = response.json()
        existing_entries = []

        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            infraAttEntityP_name = entry["infraAttEntityP"]["attributes"]["name"]
            infraAttEntityP_dn = entry["infraAttEntityP"]["attributes"]["dn"]
            children = entry["infraAttEntityP"].get("children", [])
            
            # Check if there are any 'infraRsDomP' children, if not, skip this entry
            if not any("infraRsDomP" in child for child in children):
                continue
            
            for child in children:
                if "infraRsDomP" in child:
                    infraRsDomP_name = child["infraRsDomP"]["attributes"]["tDn"].split("/")[-1]
                    infraRsDomP_rn = child["infraRsDomP"]["attributes"]["rn"]
                    row_as_list = [
                        os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                        infraAttEntityP_name,
                        infraAttEntityP_dn,
                        infraRsDomP_name,
                        infraRsDomP_rn
                    ]
                    if row_as_list not in existing_entries:
                        existing_entries.append(row_as_list)

        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve AAEP to Domain mappings. Status code: {response.status_code}")


def tf_ciscodevnet_aci_aaep_to_domain():
    csv_filepath = os.path.join("data", "py_aaep_to_physdomain.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    terraform_template = """
resource "aci_aaep_to_domain" "{{infraAttEntityP_name}}-{{infraRsDomP_name}}-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.{{infraAttEntityP_name}}.id
    domain_dn                           = aci_physical_domain.{{infraRsDomP_name}}.id
}
"""

    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0) 
        existing_content = tf_file.read()

    template = Template(terraform_template)
    new_terraform_content = ""

    for entry in entries:
        terraform_block = template.render(
            infraAttEntityP_name=entry['infraAttEntityP_name'],
            infraRsDomP_name=entry['infraRsDomP_name']
        )
        if terraform_block not in existing_content:
            new_terraform_content += terraform_block

    with open('import.tf', 'a') as tf_file:
        tf_file.write(new_terraform_content)

    print("Terraform resources, aci_aaep_to_domain, appended to import.tf successfully!")

def tf_ciscodevnet_aci_aaep_to_domain_commands():
    with open(os.path.join('data', 'py_aaep_to_physdomain.csv'), 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_aaep_to_domain.{{infraAttEntityP_name}}-{{infraRsDomP_name}}-ASSOC {{infraAttEntityP_dn}}/{{infraRsDomP_rn}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.readlines()

    new_commands = ""
    
    for entry in entries:
        terraform_block = command_template.render(
            infraAttEntityP_name=entry['infraAttEntityP_name'],
            infraRsDomP_name=entry['infraRsDomP_name'],
            infraAttEntityP_dn=entry['infraAttEntityP_dn'],
            infraRsDomP_rn=entry['infraRsDomP_rn']
        )
        if terraform_block not in existing_content:
            new_commands += terraform_block

    with open('import_commands.txt', 'a') as tf_file:
        tf_file.write(new_commands)

    print("Import commands for aci_aaep_to_domain appended to import_commands.txt successfully!")
    
########################################
### INVOCATION OF SCRIPT FUNCTIONS   ###
########################################


# FILES THAT NEED BUILT        
terraform_import_file()
terraform_command_file()
fabric_inventory_file()
fabric_blacklist_interfaces_file()
access_policy_aaep_file()
physical_domain_file()
aaep_to_domain_file()

#AUTHENTICATION TO FABRIC
token = get_aci_token()

#API CALLS TO CSV FILES
get_fabric_nodes(token)
get_fabric_blacklist_interfaces(token)
get_access_policy_aaep(token)
get_physical_domain(token)
get_aaep_to_domain(token)

#TERRAFORM THINGS
tf_ciscodevnet_aci_fabric_node_member()
tf_ciscodevnet_aci_fabric_node_member_commands()
tf_ciscodevnet_aci_interface_blacklist()
tf_ciscodevnet_aci_interface_blacklist_commands()
tf_ciscodevnet_aci_access_policy_aaep()
tf_ciscodevnet_aci_access_policy_aaep_commands()
tf_ciscodevnet_aci_physical_domain()
tf_ciscodevnet_aci_physical_domain_commands()
tf_ciscodevnet_aci_aaep_to_domain()
tf_ciscodevnet_aci_aaep_to_domain_commands()