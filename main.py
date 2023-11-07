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

        interface_name = interface.replace("/", "_")

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

    terraform_template = Template("""
resource "aci_attachable_access_entity_profile" "{{name}}" {
    name        = "{{name}}"
    
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
        terraform_block = terraform_template.render(name=entry['name'])
        if terraform_block not in existing_content:
            new_terraform_content += terraform_block

    if new_terraform_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_terraform_content)

    print("Terraform resources, aci_attachable_access_entity_profile, appended to import.tf successfully!")

def tf_ciscodevnet_aci_access_policy_aaep_commands():
    csv_filepath = os.path.join('data', 'py_access_policy_aaep.csv')
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_attachable_access_entity_profile.{{name}} uni/infra/attentp-{{name}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands = ""

    for entry in entries:
        terraform_command = command_template.render(name=entry['name'])
        if terraform_command not in existing_content:
            new_commands += terraform_command

    if new_commands:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands)

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

    terraform_template = Template("""
resource "aci_physical_domain" "{{name}}" {
    name        = "{{name}}"
    
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
        terraform_block = terraform_template.render(name=entry['name'])
        if terraform_block not in existing_content:
            new_terraform_content += terraform_block

    if new_terraform_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_terraform_content)

    print("Terraform resources, aci_physical_domain, appended to import.tf successfully!")

def tf_ciscodevnet_aci_physical_domain_commands():
    csv_filepath = os.path.join('data', 'py_physical_domain.csv')
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_physical_domain.{{name}} {{dn}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands = ""

    for entry in entries:
        terraform_command = command_template.render(
            name=entry['name'],
            dn=entry['dn']
        )
        if terraform_command not in existing_content:
            new_commands += terraform_command

    if new_commands:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands)

    print("Import commands for aci_physical_domain appended to import_commands.txt successfully!")
    
########################################################
### ACI ACCESS POLICIES AAEP to PHYSICAL DOMAIN      ###
########################################################

def aaep_to_physdomain_file():
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

def get_aaep_to_physdomain(token):
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
            
            if not any("infraRsDomP" in child for child in children):
                continue
            
            for child in children:
                if "infraRsDomP" in child:
                    infraRsDomP_name = child["infraRsDomP"]["attributes"]["tDn"].split("-")[-1]
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


def tf_ciscodevnet_aci_aaep_to_physdomain():
    csv_filepath = os.path.join("data", "py_aaep_to_physdomain.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    terraform_template = Template("""
resource "aci_aaep_to_physdomain" "{{ infraAttEntityP_name }}-{{ infraRsDomP_name }}-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.{{ infraAttEntityP_name }}.id
    domain_dn                           = aci_physical_domain.{{ infraRsDomP_name }}.id
    
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
        specific_resource = f'aci_aaep_to_physdomain."{entry["infraAttEntityP_name"]}-{entry["infraRsDomP_name"]}-ASSOC"'
        if specific_resource not in existing_content:
            terraform_block = terraform_template.render(
                infraAttEntityP_name=entry['infraAttEntityP_name'],
                infraRsDomP_name=entry['infraRsDomP_name']
            )
            new_terraform_content += terraform_block
        else:
            print(f"Resource {specific_resource} already exists in import.tf")

    if new_terraform_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_terraform_content)

    print("Terraform resources for aci_aaep_to_physdomain appended to import.tf successfully!")

def tf_ciscodevnet_aci_aaep_to_physdomain_commands():
    csv_filepath = os.path.join('data', 'py_aaep_to_physdomain.csv')
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_aaep_to_physdomain.{{ infraAttEntityP_name }}-{{ infraRsDomP_name }}-ASSOC {{ infraAttEntityP_dn }}/{{ infraRsDomP_rn }}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands = ""

    for entry in entries:
        specific_command = f'aci_aaep_to_physdomain."{entry["infraAttEntityP_name"]}-{entry["infraRsDomP_name"]}-ASSOC"'
        if specific_command not in existing_content:
            terraform_command = command_template.render(
                infraAttEntityP_name=entry['infraAttEntityP_name'],
                infraRsDomP_name=entry['infraRsDomP_name'],
                infraAttEntityP_dn=entry['infraAttEntityP_dn'],
                infraRsDomP_rn=entry['infraRsDomP_rn']
            )
            new_commands += terraform_command
        else:
            print(f"Command for {specific_command} already exists in import_commands.txt")

    if new_commands:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands)

    print("Import commands for aci_aaep_to_physdomain appended to import_commands.txt successfully!")

########################################################
### ACI ACCESS POLICIES VLAN ROOL & RANGES           ###
########################################################

def vlan_pool_file():
    directory = "data"
    filename = os.path.join(directory, "py_vlan_pool.csv")
    headers = [
        "APIC", "fvnsVlanInstP_name", "fvnsVlanInstP_dn", 
        "fvnsEncapBlk_from", "fvnsEncapBlk_to", "fvnsEncapBlk_rn"
    ]
    
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")

def get_vlan_pools(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni/infra.json?query-target=children&target-subtree-class=fvnsVlanInstP&rsp-subtree-class=fvnsEncapBlk&query-target=subtree&rsp-subtree=full"
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(URL, headers=headers, verify=False)
    filename = os.path.join("data", "py_vlan_pool.csv")

    if response.status_code == 200:
        data = response.json()
        existing_entries = []

        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            vlan_pool_name = entry["fvnsVlanInstP"]["attributes"]["name"]
            vlan_pool_dn = entry["fvnsVlanInstP"]["attributes"]["dn"]
            children = entry["fvnsVlanInstP"].get("children", [])
            
            for child in children:
                if "fvnsEncapBlk" in child:
                    encap_from = child["fvnsEncapBlk"]["attributes"]["from"]
                    encap_to = child["fvnsEncapBlk"]["attributes"]["to"]
                    encap_rn = child["fvnsEncapBlk"]["attributes"]["rn"]
                    row_as_list = [
                        os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                        vlan_pool_name,
                        vlan_pool_dn,
                        encap_from,
                        encap_to,
                        encap_rn
                    ]
                    if row_as_list not in existing_entries:
                        existing_entries.append(row_as_list)

        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve VLAN Pool mappings. Status code: {response.status_code}")

def tf_ciscodevnet_aci_vlan_pool():
    csv_filepath = os.path.join("data", "py_vlan_pool.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    vlan_pool_template = Template("""
resource "aci_vlan_pool" "{{fvnsVlanInstP_name}}" {
    name       = "{{fvnsVlanInstP_name}}"
    alloc_mode = "dynamic"
    
    lifecycle {
        ignore_changes = all
    }
}
""")

    range_template = Template("""
resource "aci_ranges" "{{fvnsVlanInstP_name}}-{{fvnsEncapBlk_from}}-{{fvnsEncapBlk_to}}" {
    vlan_pool_dn = aci_vlan_pool.{{fvnsVlanInstP_name}}.id
    from         = "{{fvnsEncapBlk_from}}"
    to           = "{{fvnsEncapBlk_to}}"
    
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
        vlan_pool_resource = vlan_pool_template.render(
            fvnsVlanInstP_name=entry['fvnsVlanInstP_name']
        )
        range_resource = range_template.render(
            fvnsVlanInstP_name=entry['fvnsVlanInstP_name'],
            fvnsEncapBlk_from=entry['fvnsEncapBlk_from'],
            fvnsEncapBlk_to=entry['fvnsEncapBlk_to']
        )
        
        if vlan_pool_resource not in existing_content:
            new_terraform_content += vlan_pool_resource
            existing_content += vlan_pool_resource 

        if range_resource not in existing_content:
            new_terraform_content += range_resource
            existing_content += range_resource  
    if new_terraform_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_terraform_content)

    print("Terraform resources for VLAN pools and ranges appended to import.tf successfully!")

def tf_ciscodevnet_aci_vlan_pool_commands():
    csv_filepath = os.path.join("data", "py_vlan_pool.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    vlan_pool_command_template = Template("""
terraform import aci_vlan_pool.{{fvnsVlanInstP_name}} {{fvnsVlanInstP_dn}}
""")

    range_command_template = Template("""
terraform import aci_ranges.{{fvnsVlanInstP_name}}-{{fvnsEncapBlk_from}}-{{fvnsEncapBlk_to}} {{fvnsVlanInstP_dn}}/{{fvnsEncapBlk_rn}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands = ""

    for entry in entries:
        vlan_pool_command = vlan_pool_command_template.render(
            fvnsVlanInstP_name=entry['fvnsVlanInstP_name'],
            fvnsVlanInstP_dn=entry['fvnsVlanInstP_dn']
        )
        range_command = range_command_template.render(
            fvnsVlanInstP_name=entry['fvnsVlanInstP_name'],
            fvnsEncapBlk_from=entry['fvnsEncapBlk_from'],
            fvnsEncapBlk_to=entry['fvnsEncapBlk_to'],
            fvnsVlanInstP_dn=entry['fvnsVlanInstP_dn'],
            fvnsEncapBlk_rn=entry['fvnsEncapBlk_rn']
        )
        
        if vlan_pool_command not in existing_content:
            new_commands += vlan_pool_command
            existing_content += vlan_pool_command  

        if range_command not in existing_content:
            new_commands += range_command
            existing_content += range_command  

    if new_commands:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands)

    print("Import commands for VLAN pools and ranges appended to import_commands.txt successfully!")

#################################################################################
### ACI ACCESS POLICIES LEAF INTERFACE PROFILES, SELECTORS & BLOCKS           ###
#################################################################################

def interface_profile_file():
    directory = "data"
    filename = os.path.join(directory, "py_interface_profile.csv")
    headers = [
        "APIC", "infraAccPortP_name", "infraAccPortP_dn",
        "infraHPortS_name", "infraHPortS_rn", "infraPortBlk_fromCard",
        "infraPortBlk_fromPort", "infraPortBlk_toCard", "infraPortBlk_toPort", "infraPortBlk_rn"
    ]

    if not os.path.exists(directory):
        os.makedirs(directory)

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")

def get_interface_profiles(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraAccPortP&query-target=children&target-subtree-class=infraAccPortP&rsp-subtree=full&rsp-subtree-class=infraHPortS,infraPortBlk,infraSubPortBlk"
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }

    response = requests.get(URL, headers=headers, verify=False)
    filename = os.path.join("data", "py_interface_profile.csv")

    if response.status_code == 200:
        data = response.json()
        existing_entries = []

        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            infraAccPortP_name = entry["infraAccPortP"]["attributes"]["name"]
            infraAccPortP_dn = entry["infraAccPortP"]["attributes"]["dn"]
            children = entry["infraAccPortP"].get("children", [])

            for child in children:
                if "infraHPortS" in child:
                    infraHPortS_name = child["infraHPortS"]["attributes"]["name"]
                    infraHPortS_rn = child["infraHPortS"]["attributes"]["rn"]
                    selector_children = child["infraHPortS"].get("children", [])

                    for selector_child in selector_children:
                        if "infraPortBlk" in selector_child:
                            infraPortBlk_fromCard = selector_child["infraPortBlk"]["attributes"]["fromCard"]
                            infraPortBlk_fromPort = selector_child["infraPortBlk"]["attributes"]["fromPort"]
                            infraPortBlk_toCard = selector_child["infraPortBlk"]["attributes"]["toCard"]
                            infraPortBlk_toPort = selector_child["infraPortBlk"]["attributes"]["toPort"]
                            infraPortBlk_rn = selector_child["infraPortBlk"]["attributes"]["rn"]

                            row_as_list = [
                                os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                                infraAccPortP_name,
                                infraAccPortP_dn,
                                infraHPortS_name,
                                infraHPortS_rn,
                                infraPortBlk_fromCard,
                                infraPortBlk_fromPort,
                                infraPortBlk_toCard,
                                infraPortBlk_toPort,
                                infraPortBlk_rn
                            ]

                            if row_as_list not in existing_entries:
                                existing_entries.append(row_as_list)

        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)

    else:
        print(f"Failed to retrieve Interface Profiles. Status code: {response.status_code}")

def tf_ciscodevnet_aci_interface_profile():
    csv_filepath = os.path.join("data", "py_interface_profile.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    interface_profile_template = Template("""
resource "aci_leaf_interface_profile" "{{infraAccPortP_name}}" {
    name = "{{infraAccPortP_name}}"
    
    lifecycle {
        ignore_changes = all
    }
}
""")

    access_port_selector_template = Template("""
resource "aci_access_port_selector" "{{infraAccPortP_name}}-{{infraHPortS_name}}" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.{{infraAccPortP_name}}.id
    name                      = "{{infraHPortS_name}}"
    access_port_selector_type = "range"

    lifecycle {
        ignore_changes = all
    }
}
""")

    access_port_block_template = Template("""
resource "aci_access_port_block" "{{infraAccPortP_name}}-{{infraHPortS_name}}-E{{infraPortBlk_fromCard}}_{{infraPortBlk_fromPort}}-E{{infraPortBlk_toCard}}_{{infraPortBlk_toPort}}" {
    access_port_selector_dn = aci_access_port_selector.{{infraAccPortP_name}}-{{infraHPortS_name}}.id
    from_card               = "{{infraPortBlk_fromCard}}"
    from_port               = "{{infraPortBlk_fromPort}}"
    to_card                 = "{{infraPortBlk_toCard}}"
    to_port                 = "{{infraPortBlk_toPort}}"

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
        interface_profile_resource = interface_profile_template.render(
            infraAccPortP_name=entry['infraAccPortP_name']
        )
        access_port_selector_resource = access_port_selector_template.render(
            infraAccPortP_name=entry['infraAccPortP_name'],
            infraHPortS_name=entry['infraHPortS_name']
        )
        access_port_block_resource = access_port_block_template.render(
            infraAccPortP_name=entry['infraAccPortP_name'],
            infraHPortS_name=entry['infraHPortS_name'],
            infraPortBlk_fromCard=entry['infraPortBlk_fromCard'],
            infraPortBlk_fromPort=entry['infraPortBlk_fromPort'],
            infraPortBlk_toCard=entry['infraPortBlk_toCard'],
            infraPortBlk_toPort=entry['infraPortBlk_toPort']
        )

        if entry['infraAccPortP_name'] not in existing_content:
            new_terraform_content += interface_profile_resource
            existing_content += interface_profile_resource

        if entry['infraHPortS_name'] not in existing_content:
            new_terraform_content += access_port_selector_resource
            existing_content += access_port_selector_resource

        access_port_block_id = f"{entry['infraAccPortP_name']}-{entry['infraHPortS_name']}-E{entry['infraPortBlk_fromCard']}_{entry['infraPortBlk_fromPort']}-E{entry['infraPortBlk_toCard']}_{entry['infraPortBlk_toPort']}"
        if access_port_block_id not in existing_content:
            new_terraform_content += access_port_block_resource
            existing_content += access_port_block_resource

    if new_terraform_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_terraform_content)
            
    print("Terraform resources for Interface Profiles, Selectors, and Blocks appended to import.tf successfully!")

def tf_ciscodevnet_aci_interface_profile_commands():
    csv_filepath = os.path.join("data", "py_interface_profile.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    # Command Template
    command_template = Template("""
terraform import aci_leaf_interface_profile.{{infraAccPortP_name}} {{infraAccPortP_dn}}
terraform import aci_access_port_selector.{{infraAccPortP_name}}-{{infraHPortS_name}} uni/infra/accportprof-{{infraAccPortP_name}}/{{infraHPortS_rn}}
terraform import aci_access_port_block.{{infraAccPortP_name}}-{{infraHPortS_name}}-E{{infraPortBlk_fromCard}}_{{infraPortBlk_fromPort}}-E{{infraPortBlk_toCard}}_{{infraPortBlk_toPort}} uni/infra/accportprof-{{infraAccPortP_name}}/{{infraHPortS_rn}}/{{infraPortBlk_rn}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands_content = ""

    for entry in entries:
        command = command_template.render(
            infraAccPortP_name=entry['infraAccPortP_name'],
            infraHPortS_name=entry['infraHPortS_name'],
            infraAccPortP_dn=entry['infraAccPortP_dn'],
            infraHPortS_rn=entry['infraHPortS_rn'],
            infraPortBlk_fromCard=entry['infraPortBlk_fromCard'],
            infraPortBlk_fromPort=entry['infraPortBlk_fromPort'],
            infraPortBlk_toCard=entry['infraPortBlk_toCard'],
            infraPortBlk_toPort=entry['infraPortBlk_toPort'],
            infraPortBlk_rn=entry['infraPortBlk_rn']
        )

        
        if command not in existing_content:
            new_commands_content += command
            existing_content += command

    if new_commands_content:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands_content)
            
    print("Import Commands for Interface Profiles, Selectors, and Blocks appended to import.tf successfully!")

####################################################################
### ACI ACCESS POLICIES LEAF ACCESS PORT POLICY GROUPS           ###
####################################################################

def leaf_access_port_policy_group_file():
    directory = "data"
    filename = os.path.join(directory, "py_leaf_access_port_policy_group.csv")
    headers = [
        "APIC", "infraAccPortGrp_name", "infraAccPortGrp_dn"
    ]

    if not os.path.exists(directory):
        os.makedirs(directory)

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")

def get_leaf_access_port_policy_groups(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraAccPortGrp"
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }

    response = requests.get(URL, headers=headers, verify=False)
    filename = os.path.join("data", "py_leaf_access_port_policy_group.csv")

    if response.status_code == 200:
        data = response.json()
        existing_entries = []

        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            infraAccPortGrp_name = entry["infraAccPortGrp"]["attributes"]["name"]
            infraAccPortGrp_dn = entry["infraAccPortGrp"]["attributes"]["dn"]

            row_as_list = [
                os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                infraAccPortGrp_name,
                infraAccPortGrp_dn
            ]

            if row_as_list not in existing_entries:
                existing_entries.append(row_as_list)

        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve Port Policy Groups. Status code: {response.status_code}")
        
def tf_ciscodevnet_aci_leaf_access_port_policy_group():
    csv_filepath = os.path.join("data", "py_leaf_access_port_policy_group.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    hcl_template = Template("""
resource "aci_leaf_access_port_policy_group" "{{infraAccPortGrp_name}}" {
    name        = "{{infraAccPortGrp_name}}"
    lifecycle {
        ignore_changes = all
    }
} 
""")

    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0)
        existing_content = tf_file.read()

    new_hcl_content = ""
    for entry in entries:
        specific_resource_line = f'resource "aci_leaf_access_port_policy_group" "{entry["infraAccPortGrp_name"]}"'
        
        if specific_resource_line not in existing_content:
            new_hcl_content += hcl_template.render(
                infraAccPortGrp_name=entry['infraAccPortGrp_name']
            )
        else:
            print(f"Entry {entry['infraAccPortGrp_name']} already exists in import.tf")

    if new_hcl_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_hcl_content)

    print("Terraform resources for Leaf Access Port Policy Groups appended to import.tf successfully!")

def tf_ciscodevnet_aci_leaf_access_port_policy_group_commands():
    csv_filepath = os.path.join("data", "py_leaf_access_port_policy_group.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_leaf_access_port_policy_group.{{infraAccPortGrp_name}} {{infraAccPortGrp_dn}}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands_content = ""
    for entry in entries:
        specific_command_line = f'terraform import aci_leaf_access_port_policy_group.{entry["infraAccPortGrp_name"]}'
        
        if specific_command_line not in existing_content:
            new_commands_content += command_template.render(
                infraAccPortGrp_name=entry['infraAccPortGrp_name'],
                infraAccPortGrp_dn=entry['infraAccPortGrp_dn']
            )
        else:
            print(f"Command for {entry['infraAccPortGrp_name']} already exists in import_commands.txt")

    if new_commands_content:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands_content)

    print("Import Commands for Leaf Access Port Policy Groups appended to import.tf successfully!")
    
####################################################################
### ACI ACCESS POLICIES LEAF ACCESS BUNDLE POLICY GROUPS         ###
####################################################################

def leaf_access_bundle_policy_group_file():
    directory = "data"
    filename = os.path.join(directory, "py_leaf_access_bundle_policy_group.csv")
    headers = [
        "APIC", "infraAccBndlGrp_name", "infraAccBndlGrp_dn"
    ]

    if not os.path.exists(directory):
        os.makedirs(directory)

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(headers)
            print(f"'{filename}' has been created with the required headers.")

def get_leaf_access_bundle_policy_groups(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni/infra/funcprof.json?query-target=subtree&target-subtree-class=infraAccBndlGrp"
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }

    response = requests.get(URL, headers=headers, verify=False)
    filename = os.path.join("data", "py_leaf_access_bundle_policy_group.csv")

    if response.status_code == 200:
        data = response.json()
        existing_entries = []

        with open(filename, mode='r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            infraAccBndlGrp_name = entry["infraAccBndlGrp"]["attributes"]["name"]
            infraAccBndlGrp_dn = entry["infraAccBndlGrp"]["attributes"]["dn"]

            row_as_list = [
                os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS'),
                infraAccBndlGrp_name,
                infraAccBndlGrp_dn
            ]

            if row_as_list not in existing_entries[1:]:
                existing_entries.append(row_as_list)

        with open(filename, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve Bundle Policy Groups. Status code: {response.status_code}")

def tf_ciscodevnet_aci_leaf_access_bundle_policy_group():
    csv_filepath = os.path.join("data", "py_leaf_access_bundle_policy_group.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    hcl_template = Template("""
resource "aci_leaf_access_bundle_policy_group" "{{ infraAccBndlGrp_name }}" {
  name        = "{{ infraAccBndlGrp_name }}"
  lifecycle {
    ignore_changes = all
  }
}
""")

    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0)
        existing_content = tf_file.read()

    new_hcl_content = ""
    for entry in entries:
        specific_resource_line = f'resource "aci_leaf_access_bundle_policy_group" "{entry["infraAccBndlGrp_name"]}"'

        if specific_resource_line not in existing_content:
            new_hcl_content += hcl_template.render(
                infraAccBndlGrp_name=entry['infraAccBndlGrp_name']
            )
        else:
            print(f"Entry {entry['infraAccBndlGrp_name']} already exists in import.tf")

    if new_hcl_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_hcl_content)

    print("Terraform resources for Leaf Access Bundle Policy Groups appended to import.tf successfully!")

def tf_ciscodevnet_aci_leaf_access_bundle_policy_group_commands():
    csv_filepath = os.path.join("data", "py_leaf_access_bundle_policy_group.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_leaf_access_bundle_policy_group.{{ infraAccBndlGrp_name }} {{ infraAccBndlGrp_dn }}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands_content = ""
    for entry in entries:
        specific_command_line = f"terraform import aci_leaf_access_bundle_policy_group.{entry['infraAccBndlGrp_name']}"

        if specific_command_line not in existing_content:
            new_commands_content += command_template.render(
                infraAccBndlGrp_name=entry['infraAccBndlGrp_name'],
                infraAccBndlGrp_dn=entry['infraAccBndlGrp_dn']
            )
        else:
            print(f"Command for {entry['infraAccBndlGrp_name']} already exists in import_commands.sh")

    if new_commands_content:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands_content)

    print("Import commands for Leaf Access Bundle Policy Groups appended to import_commands.sh successfully!")

########################################################
### ACI ACCESS POLICIES L3OUT DOMAIN                 ###
########################################################

def l3_domain_file():
    directory = "data"
    filename = os.path.join(directory, "py_l3_domain.csv")
    headers = [
        "APIC", "annotation", "childAction", "configIssues", "dn",
        "extMngdBy", "lcOwn", "modTs", "monPolDn", "name", "nameAlias",
        "ownerKey", "ownerTag", "status", "targetDscp", "uid", "userdom"
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

def get_l3_domain(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni.json?query-target=subtree&target-subtree-class=l3extDomP"
    
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

    filename = os.path.join("data", "py_l3_domain.csv")

    if response.status_code == 200:
        data = response.json()

        existing_entries = []
        with open(filename, 'r', newline='') as file:
            reader = csv.reader(file)
            existing_entries.extend(list(reader))

        for entry in data['imdata']:
            attributes = entry["l3extDomP"]["attributes"]
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
                attributes.get("targetDscp"),
                attributes.get("uid"),
                attributes.get("userdom"),
            ]
            if row_as_list not in existing_entries:
                existing_entries.append(row_as_list)

        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(existing_entries)
    else:
        print(f"Failed to retrieve L3 domains. Status code: {response.status_code}")
        
def tf_ciscodevnet_aci_l3_domain():
    csv_filepath = os.path.join("data", "py_l3_domain.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    hcl_template = Template("""
resource "aci_l3_domain_profile" "{{ name }}" {
    name  = "{{ name }}"
    
    lifecycle {
        ignore_changes = all
    }
}
""")

    with open('import.tf', 'a+') as tf_file:
        tf_file.seek(0)
        existing_content = tf_file.read()

    new_hcl_content = ""
    for entry in entries:
        specific_resource_line = f'resource "aci_l3_domain_profile" "{entry["name"]}"'

        if specific_resource_line not in existing_content:
            new_hcl_content += hcl_template.render(name=entry['name'])
        else:
            print(f"Entry {entry['name']} already exists in import.tf")

    if new_hcl_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_hcl_content)

    print("Terraform resources for ACI L3 Domain Profiles appended to import.tf successfully!")

def tf_ciscodevnet_aci_l3_domain_commands():
    csv_filepath = os.path.join('data', 'py_l3_domain.csv')
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_l3_domain_profile.{{ name }} {{ dn }}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands_content = ""
    for entry in entries:
        name_resource = entry['name'].replace(" ", "_")

        specific_command_line = f"terraform import aci_l3_domain_profile.{name_resource}"

        if specific_command_line not in existing_content:
            new_commands_content += command_template.render(
                name=name_resource,
                dn=entry['dn']
            )
        else:
            print(f"Command for {entry['name']} already exists in import_commands.txt")

    if new_commands_content:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands_content)

    print("Import commands for ACI L3 Domain Profiles appended to import_commands.txt successfully!")
    
########################################################
### ACI ACCESS POLICIES AAEP to L3OUT DOMAIN         ###
########################################################

def aaep_to_l3outdomain_file():
    directory = "data"
    filename = os.path.join(directory, "py_aaep_to_l3outdomain.csv")
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

def get_aaep_to_l3outdomain(token):
    URL = f"{ACI_BASE_URL}/api/node/mo/uni/infra.json?query-target=children&target-subtree-class=infraAttEntityP&rsp-subtree=children&rsp-subtree-class=infraRsDomP&rsp-subtree-filter=eq(infraRsDomP.tCl,\"l3extDomP\")"
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(URL, headers=headers, verify=False)
    filename = os.path.join("data", "py_aaep_to_l3outdomain.csv")

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
            
            if not any("infraRsDomP" in child for child in children):
                continue
            
            for child in children:
                if "infraRsDomP" in child:
                    infraRsDomP_name = child["infraRsDomP"]["attributes"]["tDn"].split("-")[-1]
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


def tf_ciscodevnet_aci_aaep_to_l3outdomain():
    csv_filepath = os.path.join("data", "py_aaep_to_l3outdomain.csv")
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    terraform_template = Template("""
resource "aci_aaep_to_l3outdomain" "{{ infraAttEntityP_name }}-{{ infraRsDomP_name }}-ASSOC" {
    attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.{{ infraAttEntityP_name }}.id
    domain_dn                           = aci_l3_domain_profile.{{ infraRsDomP_name }}.id
    
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
        specific_resource = f'aci_aaep_to_l3outdomain."{entry["infraAttEntityP_name"]}-{entry["infraRsDomP_name"]}-ASSOC"'
        if specific_resource not in existing_content:
            terraform_block = terraform_template.render(
                infraAttEntityP_name=entry['infraAttEntityP_name'],
                infraRsDomP_name=entry['infraRsDomP_name']
            )
            new_terraform_content += terraform_block
        else:
            print(f"Resource {specific_resource} already exists in import.tf")

    if new_terraform_content:
        with open('import.tf', 'a') as tf_file:
            tf_file.write(new_terraform_content)

    print("Terraform resources for aci_aaep_to_l3outdomain appended to import.tf successfully!")

def tf_ciscodevnet_aci_aaep_to_l3outdomain_commands():
    csv_filepath = os.path.join('data', 'py_aaep_to_l3outdomain.csv')
    with open(csv_filepath, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        entries = list(reader)

    command_template = Template("""
terraform import aci_aaep_to_l3outdomain.{{ infraAttEntityP_name }}-{{ infraRsDomP_name }}-ASSOC {{ infraAttEntityP_dn }}/{{ infraRsDomP_rn }}
""")

    with open('import_commands.txt', 'a+') as cmd_file:
        cmd_file.seek(0)
        existing_content = cmd_file.read()

    new_commands = ""

    for entry in entries:
        specific_command = f'aci_aaep_to_l3outdomain."{entry["infraAttEntityP_name"]}-{entry["infraRsDomP_name"]}-ASSOC"'
        if specific_command not in existing_content:
            terraform_command = command_template.render(
                infraAttEntityP_name=entry['infraAttEntityP_name'],
                infraRsDomP_name=entry['infraRsDomP_name'],
                infraAttEntityP_dn=entry['infraAttEntityP_dn'],
                infraRsDomP_rn=entry['infraRsDomP_rn']
            )
            new_commands += terraform_command
        else:
            print(f"Command for {specific_command} already exists in import_commands.txt")

    if new_commands:
        with open('import_commands.txt', 'a') as cmd_file:
            cmd_file.write(new_commands)

    print("Import commands for aci_aaep_to_l3outdomain appended to import_commands.txt successfully!")
   

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
aaep_to_physdomain_file()
aaep_to_l3outdomain_file()
vlan_pool_file()
interface_profile_file()
leaf_access_port_policy_group_file()
leaf_access_bundle_policy_group_file()
l3_domain_file()

#AUTHENTICATION TO FABRIC
token = get_aci_token()

#API CALLS TO CSV FILES
get_fabric_nodes(token)
get_fabric_blacklist_interfaces(token)
get_access_policy_aaep(token)
get_physical_domain(token)
get_vlan_pools(token)
get_interface_profiles(token)
get_leaf_access_port_policy_groups(token)
get_leaf_access_bundle_policy_groups(token)
get_l3_domain(token)
get_aaep_to_l3outdomain(token)


get_aaep_to_physdomain(token)

#TERRAFORM THINGS
tf_ciscodevnet_aci_fabric_node_member()
tf_ciscodevnet_aci_fabric_node_member_commands()
tf_ciscodevnet_aci_interface_blacklist()
tf_ciscodevnet_aci_interface_blacklist_commands()
tf_ciscodevnet_aci_access_policy_aaep()
tf_ciscodevnet_aci_access_policy_aaep_commands()
tf_ciscodevnet_aci_physical_domain()
tf_ciscodevnet_aci_physical_domain_commands()
tf_ciscodevnet_aci_vlan_pool()
tf_ciscodevnet_aci_vlan_pool_commands()
tf_ciscodevnet_aci_interface_profile()
tf_ciscodevnet_aci_interface_profile_commands()
tf_ciscodevnet_aci_leaf_access_port_policy_group()
tf_ciscodevnet_aci_leaf_access_port_policy_group_commands()
tf_ciscodevnet_aci_leaf_access_bundle_policy_group()
tf_ciscodevnet_aci_leaf_access_bundle_policy_group_commands()
tf_ciscodevnet_aci_l3_domain()
tf_ciscodevnet_aci_l3_domain_commands()


tf_ciscodevnet_aci_aaep_to_physdomain()
tf_ciscodevnet_aci_aaep_to_physdomain_commands()
tf_ciscodevnet_aci_aaep_to_l3outdomain()
tf_ciscodevnet_aci_aaep_to_l3outdomain_commands()