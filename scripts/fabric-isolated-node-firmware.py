import requests
import json
import os
import datetime
import time

requests.packages.urllib3.disable_warnings()
current_utc_datetime = datetime.datetime.utcnow()
formatted_date = current_utc_datetime.strftime("%Y-%m-%dT%H:%M:%S.000Z")

ACI_BASE_URL = os.environ.get('TF_VAR_CISCO_ACI_APIC_IP_ADDRESS')
USERNAME = os.environ.get('TF_VAR_CISCO_ACI_TERRAFORM_USERNAME')
PASSWORD = os.environ.get('TF_VAR_CISCO_ACI_TERRAFORM_PASSWORD')

SWITCH_POD_ID = os.environ.get('SWITCH_POD_ID')
SWITCH_NODE_ID = os.environ.get('SWITCH_NODE_ID')
TARGET_VERISON = os.environ.get('TARGET_VERISON')

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
        
def http_post(token):
    URL = f"{ACI_BASE_URL}/api/node/mo.json"
    
    headers = {
        "Cookie": f"APIC-Cookie={token}",
        "Content-Type": "application/json"
    }
    
    payload = json.dumps({
      "imdata": [
        {
          "maintMaintP": {
            "attributes": {
              "adminSt": "triggered",
              "annotation": "ORCHESTRATOR:TERRAFORM_PYTHON",
              "descr": "Creates a Temporary Maintenance Policy",
              "dn": f"uni/fabric/maintpol-{SWITCH_NODE_ID}_STAGE_MAINTPOL",
              "graceful": "yes",
              "ignoreCompat": "yes",
              "notifCond": "notifyNever",
              "rn": f"fabric/maintpol-{SWITCH_NODE_ID}_STAGE_MAINTPOL",
              "runMode": "pauseNever",
              "status": f"{STATUS}",
              "version": f"{TARGET_VERISON}",
              "versionCheckOverride": "untriggered"
            }
          }
        },
        {
          "maintMaintGrp": {
            "attributes": {
              "annotation": "ORCHESTRATOR:TERRAFORM_PYTHON",
              "descr": "Creates a Temporary Maintenance Group",
              "dn": f"uni/fabric/maintgrp-{SWITCH_NODE_ID}_STAGE_MAINTGRP",
              "fwtype": "switch",
              "rn": f"fabric/maintgrp-{SWITCH_NODE_ID}_STAGE_MAINTGRP",
              "status": f"{STATUS}",
              "type": "range"
            }
          }
        },
        {
          "fabricNodeBlk": {
            "attributes": {
              "annotation": "ORCHESTRATOR:TERRAFORM_PYTHON",
              "descr": "Creates a Temporary Maintenance Group Node Block",
              "dn": f"uni/fabric/maintgrp-{SWITCH_NODE_ID}_STAGE_MAINTGRP/nodeblk-{SWITCH_NODE_ID}_STAGE_MAINTGRP",
              "from_": f"{SWITCH_NODE_ID}",
              "rn": f"nodeblk-{SWITCH_NODE_ID}_STAGE_MAINTGRP",
              "status": f"{STATUS}",
              "to_": f"{SWITCH_NODE_ID}"
            }
          }
        },
        {
          "trigSchedP": {
            "attributes": {
              "dn": f"uni/fabric/schedp-{SWITCH_NODE_ID}_STAGE_MAINTPOL-SCHD",
              "name": f"{SWITCH_NODE_ID}_STAGE_MAINTPOL-SCHD",
              "rn": f"schedp-{SWITCH_NODE_ID}_STAGE_MAINTPOL-SCHD",
              "status": f"{STATUS}"
            },
            "children": [
              {
                "trigAbsWindowP": {
                  "attributes": {
                    "dn": f"uni/fabric/schedp-{SWITCH_NODE_ID}_STAGE_MAINTPOL-SCHD/abswinp-{SWITCH_NODE_ID}_OTT",
                    "name": f"{SWITCH_NODE_ID}_OTT",
                    "date": f"{formatted_date}",
                    "rn": f"abswinp-{SWITCH_NODE_ID}_OTT",
                    "status": f"{STATUS}"
                  }
                }
              }
            ]
          }
        },
        {
          "maintRsMgrpp": {
            "attributes": {
              "annotation": "ORCHESTRATOR:TERRAFORM_PYTHON",
              "dn": f"uni/fabric/maintgrp-{SWITCH_NODE_ID}_STAGE_MAINTGRP/rsmgrpp",
              "tnMaintMaintPName": f"{SWITCH_NODE_ID}_STAGE_MAINTPOL"
            }
          }
        },
        {
          "maintRsPolScheduler": {
            "attributes": {
              "annotation": "orchestrator:terraform",
              "dn": f"uni/fabric/{SWITCH_NODE_ID}_STAGE_MAINTPOL/rspolScheduler",
              "tnTrigSchedPName": f"{SWITCH_NODE_ID}_STAGE_MAINTPOL-SCHD"
            }
          }
        }
      ]
    })
    
    print(URL)
    print(payload)
    
    response = requests.post(URL, headers=headers, data=payload, verify=False)
    
    if response.status_code == 403:
        print("Received a HTTP_403 error. Refreshing token...")
        token = get_aci_token()
        headers["Cookie"] = f"APIC-Cookie={token}"
        response = requests.post(URL, headers=headers, data=payload, verify=False)
    else:
        print(f"Received a HTTP_200, Maintenance Upgrade Job for Node-{SWITCH_NODE_ID} triggered")
        print(response.content)
        print(f"TERRAFORM PROCEED ON NODE-{SWITCH_NODE_ID}")

def get_maintenance_upgrade_job(token):
    while True:
        
        URL = f'{ACI_BASE_URL}/api/node/class/maintUpgJob.json?=query-target-filter=eq(maintUpgJob.dn, \"topology/pod-{SWITCH_POD_ID}/node-{SWITCH_NODE_ID}/sys/fwstatuscont/upgjob\")'
        
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
        else:
            data = response.json()
            upgradeStatus = data["imdata"][0]["maintUpgJob"]["attributes"]["upgradeStatus"]
            print(f"{SWITCH_NODE_ID} upgrade status is: {upgradeStatus}")
            
            if upgradeStatus == "completeok":
                print(f"Starting process to remove staging maintenance group for Node-{SWITCH_NODE_ID}.")
                break
            else:
                print(f"Node-{SWITCH_NODE_ID} is not completeok, sleeping 10 seconds...")
                time.sleep(10)
                
# Get a token            
token = get_aci_token()

# Set Up Ad-Hoc Staging Group for Node
STATUS = "created, modified"
http_post(token)

# Wait for it to upgrade/downgrade to verison
get_maintenance_upgrade_job(token)

# Remove Ad-Hoc Staging Group for Node
STATUS = "deleted"
http_post(token)