"""Each endpoint exercises a different layer so failures are easy to localise.

/         app only
/healthz  probes
/k8s      Kubernetes API with the pod's ServiceAccount (RBAC)
/egress   DNS + outbound network
/s3       AWS IAM (IRSA) + S3        (EKS only)
/burn     CPU load
/leak     memory growth
"""
import json
import logging
import os
import ssl
import time
import urllib.error
import urllib.request

import boto3
from botocore.config import Config
from fastapi import FastAPI, HTTPException

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("app")

# Required on purpose: missing config should fail loudly at startup.
MESSAGE = os.environ["APP_MESSAGE"]
BUCKET = os.environ.get("BUCKET_NAME", "")
EGRESS_URL = os.environ.get("EGRESS_URL", "https://example.com")
POD = os.environ.get("HOSTNAME", "unknown")
SA_DIR = "/var/run/secrets/kubernetes.io/serviceaccount"
AWS_CFG = Config(connect_timeout=3, read_timeout=3, retries={"max_attempts": 1})

app = FastAPI()
_hog = []


def fail(layer: str, err: Exception):
    msg = f"[{layer}] {type(err).__name__}: {err}"
    log.error(msg)
    raise HTTPException(status_code=500, detail=msg)


@app.get("/")
def root():
    return {"message": MESSAGE, "pod": POD}


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/k8s")
def k8s_check():
    """Lists ConfigMaps in our namespace using the pod's own ServiceAccount token."""
    try:
        with open(f"{SA_DIR}/token") as f:
            token = f.read()
        with open(f"{SA_DIR}/namespace") as f:
            ns = f.read()
        host = os.environ["KUBERNETES_SERVICE_HOST"]
        port = os.environ.get("KUBERNETES_SERVICE_PORT", "443")
        req = urllib.request.Request(
            f"https://{host}:{port}/api/v1/namespaces/{ns}/configmaps",
            headers={"Authorization": f"Bearer {token}"},
        )
        ctx = ssl.create_default_context(cafile=f"{SA_DIR}/ca.crt")
        with urllib.request.urlopen(req, context=ctx, timeout=3) as r:
            items = json.load(r)["items"]
        return {"serviceaccount": f"system:serviceaccount:{ns}:app",
                "configmaps": [i["metadata"]["name"] for i in items]}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")[:300]
        log.error("k8s api %s: %s", e.code, detail)
        raise HTTPException(status_code=500, detail=f"[k8s-api] HTTP {e.code}: {detail}")
    except Exception as e:
        fail("k8s-api", e)


@app.get("/egress")
def egress_check():
    """Outbound HTTPS call: needs DNS and egress to work."""
    start = time.time()
    try:
        with urllib.request.urlopen(EGRESS_URL, timeout=5) as r:
            return {"url": EGRESS_URL, "status": r.status, "ms": int((time.time() - start) * 1000)}
    except Exception as e:
        fail(f"egress {int((time.time() - start) * 1000)}ms", e)


@app.get("/s3")
def s3_check():
    """Writes/lists S3 and reports WHICH AWS identity was used."""
    try:
        identity = boto3.client("sts", config=AWS_CFG).get_caller_identity()["Arn"]
        s3 = boto3.client("s3", config=AWS_CFG)
        s3.put_object(Bucket=BUCKET, Key=f"heartbeat/{POD}", Body=str(time.time()).encode())
        count = s3.list_objects_v2(Bucket=BUCKET, MaxKeys=50).get("KeyCount", 0)
        return {"identity": identity, "bucket": BUCKET, "objects": count}
    except Exception as e:
        fail("aws", e)


@app.get("/burn")
def burn(seconds: int = 5):
    end = time.time() + min(seconds, 60)
    while time.time() < end:
        pass
    return {"burned_seconds": seconds, "pod": POD}


@app.get("/leak")
def leak(mb: int = 50):
    _hog.append(bytearray(mb * 1024 * 1024))
    return {"held_mb": sum(len(b) for b in _hog) // (1024 * 1024), "pod": POD}