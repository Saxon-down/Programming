#!/usr/local/bin/python3
# New pre-receive hook for GitHub Enterprise to send COMMIT data to our
# Elastic Stack.

from datetime import datetime
import json
import os
import requests
import ssl
import sys
import socket


GKE_LOGSTASH_SERVER = "https://logstash-prod:8080"
GKE_LOGSTASH_CA_CERT = "/usr/src/app/ca.cert"
GKE_LOGSTASH_SSL_CERT = "/usr/src/app/elk-gke.pem"  # path on GHE_PROD server

POC_LOGSTASH_SERVER = "https://logstash-poc:5011"
POC_LOGSTASH_SSL_CERT = "/usr/src/app/ca-poc.cert"
POC_LOGSTASH_CA_CERT = "/usr/src/app/elk-gke-poc.pem"


USE_TEST_ENVIRONMENT = False
DEBUGGING = True


def debug(*args):
    # Takes a string and prints it if DEBUGGING is on
    if DEBUGGING:
        print("DEBUG:", *args, "\n")

def get_ip() :
    # Returns the user's workstation IP address
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()
    debug("get_ip:", IP)
    return IP

def organise_data() :
    # No idea what kind of data we'll get, so stage 1 is to just record everything we get
    data_out = {}
    for entry in os.environ :
        if entry == "GITHUB_REPO_NAME":
            # Splitting this should make it easier to query against
            # both repo name AND org name
            data_out["GITHUB_ORG_NAME_ONLY"], data_out["GITHUB_REPO_NAME_ONLY"] = os.getenv(entry).split("/")
        data_out[entry] = os.getenv(entry)
    # Additional info that github doesn't provide as an 
    # environment variable
    now = datetime.now()
    data_out["date"], data_out["time"] = str(now).split()
    data_out["timestamp-year"] = now.year
    data_out["timestamp-month"] = now.month
    data_out["timestamp-day"] = now.day
    data_out["ip_address"] = get_ip()
    debug("organise_data:\n", json.dumps(data_out, indent = 8))
    # return json.dumps(data_out, indent = 2)
    # While elasticsearch wanted the data in JSON format, logstash wants it as 
    # a string, which it then converts itself.
    return data_out


def post_to_logstash(json_block):
    logstash_server = GKE_LOGSTASH_SERVER
    logstash_ssl_cert = GKE_LOGSTASH_SSL_CERT
    logstash_ca_cert = GKE_LOGSTASH_CA_CERT
    if USE_TEST_ENVIRONMENT:
        logstash_server = POC_LOGSTASH_SERVER
        logstash_ssl_cert = POC_LOGSTASH_SSL_CERT
        logstash_ca_cert = POC_LOGSTASH_CA_CERT
        debug("post_to_logstash:", "USING TEST ENV")
    else:
        debug("post_to_logstash:", "*** POSTING TO PRODUCTION ***")
    debug("post_to_logstash:", "checking GHE server:", os.uname()[1])
    debug("post_to_logstash:", "server =", logstash_server)
    debug("post_to_logstash:", "certificate path =", logstash_ssl_cert)
    debug("post_to_logstash:", "checking certificate exists ..", os.path.isfile(logstash_ssl_cert))
    with requests.session() as elk_session:
        debug("post_to_logstash:", "getting session:",
                "ssl_cert =", logstash_ssl_cert, "ca_cert =", logstash_ca_cert)
        debug("\t-->", elk_session.get(logstash_server, cert=logstash_ssl_cert, verify=logstash_ca_cert))
        debug("post_to_logstash:", "verifying session:")
        elk_session.verify = logstash_ssl_cert
        debug("post_to_logstash:", "posting data:", logstash_server, json_block)
        elk_session = requests.post(logstash_server, json=json_block, cert=logstash_ssl_cert, verify=logstash_ca_cert)
        debug("post_to_logstash:", "complete")

debug("logstash_send.py PRE-RECEIVE-HOOK")
post_to_logstash(organise_data())
sys.exit(0)

