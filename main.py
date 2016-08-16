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
  compartmentId = clusterParameters['compartmentId']
  apiKeyFingerprint = clusterParameters['apiKeyFingerprint']
  privateKeyPath = clusterParameters['privateKeyPath']

  with open(privateKeyPath) as f:
    private_key = f.read().strip()

  # This is the keyId for a key uploaded through the console
  api_key = (compartmentId, userOCID, apiKeyFingerprint)
  auth = SignedRequestAuth.SignedRequestAuth(api_key, private_key)

  headers = {
    "content-type": "application/json",
    "date": email.utils.formatdate(usegmt=True)
  }

  uri = ("https://core.us-az-phoenix-1.oracleiaas.com/v1/shapes/?" +
         "availabilityDomain=" + availabilityDomains[0][0] +
         "&compartmentId=" + compartmentId)
  print("uri: " + uri)

  response = requests.get(uri, auth=auth, headers=headers)
  print("response: " + response.text)

main()