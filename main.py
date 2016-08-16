import base64
import email.utils
import hashlib

# pip install httpsig requests six
import httpsig.requests_auth
import requests
import six


class SignedRequestAuth(requests.auth.AuthBase):
    """A requests auth instance that can be reused across requests"""
    generic_headers = [
        "date",
        "(request-target)"
    ]
    body_headers = [
        "content-length",
        "content-type",
        "x-content-sha256",
    ]
    required_headers = {
        "options": [],
        "get": generic_headers,
        "head": generic_headers,
        "delete": generic_headers,
        "put": generic_headers + body_headers,
        "post": generic_headers + body_headers
    }

    def __init__(self, key_id, private_key):
        # Build a httpsig.requests_auth.HTTPSignatureAuth for each
        # HTTP method's required headers
        self.signers = {}
        for method, headers in six.iteritems(self.required_headers):
            signer = httpsig.sign.HeaderSigner(
                key_id=key_id, secret=private_key,
                algorithm="rsa-sha256", headers=headers[:])
            use_host = "host" in headers
            self.signers[method] = (signer, use_host)

    def inject_missing_headers(self, request, sign_body):
        # Inject date and content-type if missing
        request.headers.setdefault(
            "date", email.utils.formatdate(usegmt=True))
        request.headers.setdefault("content-type", "application/json")

        # Requests with a body need to send content-type,
        # content-length, and x-content-sha256
        if sign_body:
            body = request.body or ""
            if "x-content-sha256" not in request.headers:
                m = hashlib.sha256(body.encode("utf-8"))
                base64digest = base64.b64encode(m.digest())
                base64string = base64digest.decode("utf-8")
                request.headers["x-content-sha256"] = base64string
            request.headers.setdefault("content-length", len(body))

    def __call__(self, request):
        verb = request.method.lower()
        signer, use_host = self.signers.get(verb, (None, None))
        if signer is None:
            raise ValueError(
                "Don't know how to sign request verb {}".format(verb))

        # Inject body headers for put/post requests, date for all requests
        sign_body = verb in ["put", "post"]
        self.inject_missing_headers(request, sign_body=sign_body)

        if use_host:
            host = six.moves.urllib.parse.urlparse(request.url).netloc
        else:
            host = None

        signed_headers = signer.sign(
            request.headers, host=host,
            method=request.method, path=request.path_url)
        request.headers.update(signed_headers)
        return request


# -----BEGIN RSA PRIVATE KEY-----
# ...
# -----END RSA PRIVATE KEY-----
with open("../sample-private-key") as f:
    private_key = f.read().strip()

# This is the keyId for a key uploaded through the console
api_key = (
    "ocid1.tenancy.oc1..aaaaaaaaq3hulfjvrouw3e6qx2ncxtp256aq7etiabqqtzunnhxjslzkfyxq/"
    "ocid1.user.oc1..aaaaaaaaflxvsdpjs5ztahmsf7vjxy5kdqnuzyqpvwnncbkfhavexwd4w5ra/"
    "71:d9:eb:04:f6:e5:9b:49:10:b4:01:d7:f1:8e:9b:b4")

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