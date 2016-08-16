import email.utils
import SignedRequestAuth
import json

# pip requests
import requests


def main():
  with open('clusterParameters.json') as inputFile:
    clusterParameters = json.load(inputFile)

  availabilityDomains = clusterParameters['availabilityDomains']
  nodesPerAvailabilityDomain = clusterParameters['nodesPerAvailabilityDomain']
  shape = clusterParameters['shape']
  userOCID = clusterParameters['userOCID']
  tenancyOCID = clusterParameters['tenancyOCID']
  apiKeyFingerprint = clusterParameters['apiKeyFingerprint']
  privateKeyPath = clusterParameters['privateKeyPath']

  with open(privateKeyPath) as f:
    private_key = f.read().strip()

  # This is the keyId for a key uploaded through the console
  api_key = (tenancyOCID, userOCID, apiKeyFingerprint)

  auth = SignedRequestAuth(api_key, private_key)

  headers = {
    "content-type": "application/json",
    # Uncomment to use a fixed date
    # "date": "Thu, 05 Jan 2014 21:31:40 GMT"
    "date": email.utils.formatdate(usegmt=True)
  }

  # GET with query parameters
  uri = "https://core.us-az-phoenix-1.oracleiaas.com/v1/instances?availabilityDomain={availability_domain}&compartmentId={compartment_id}&displayName={display_name}&volumeId={volume_id}"
  uri = uri.format(
    availability_domain="Pjwf%3A%20PHX-AD-1",
    # Older ocid formats included ":" which must be escaped
    compartment_id="ocid1.compartment.oc1..aaaaaaaayzim47sto5wqh5d4vugrsx566gjqmflvhlifte3p5ez3miy6e4lq".replace(":", "%3A"),
    display_name="TeamXInstances",
    volume_id="ocid1.volume.oc1.phx.abyhqljrav2k323acohquoxszz2zyh5vj5v2gbvntg7ifd4ndusyvr332whq".replace(":", "%3A")
  )
  response = requests.get(uri, auth=auth, headers=headers)
  print(uri)
  print(response.request.headers["Authorization"])

  # POST with body
  uri = "https://core.us-az-phoenix-1.oracleiaas.com/v1/volumeAttachments"
  body = """{
    "compartmentId": "ocid1.compartment.oc1..aaaaaaaayzim47sto5wqh5d4vugrsx566gjqmflvhlifte3p5ez3miy6e4lq",
    "instanceId": "ocid1.instance.oc1.phx.abuw4ljrlsfiqw6vzzxb43vyypt4pkodawglp3wqxjqofakrwvou52gb6s5a",
    "volumeId": "ocid1.volume.oc1.phx.abyhqljrav2k323acohquoxszz2zyh5vj5v2gbvntg7ifd4ndusyvr332whq"
  }"""
  response = requests.post(uri, auth=auth, headers=headers, data=body)
  print("\n" + uri)
  print(response.request.headers["Authorization"])
