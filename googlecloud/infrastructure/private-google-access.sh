#!/bin/bash
# Copyright 2021 GoogleCloud.fr; All rights reserved!
#
# configure private Google access with most Google API domains
# verify no existing DNS zones of the domains exist to prevent conflicts

set -e # exit the script when execution hits any error
set -x # print the executing lines

declare -a domains=("googleadapis.com" "ltsapis.goog" "gcr.io" "pkg.dev" "gstatic.com" "appspot.com" "cloudfunctions.net" "pki.goog" "cloudproxy.app" "run.app" "datafusion.googleusercontent.com" "datafusion.cloud.google.com" "notebooks.cloud.google.com" "notebooks.googleusercontent.com" "appengine.google.com" "packages.cloud.google.com" "source.developers.google.com")

PROJECT_ID=agbg-blueprints-demo
NETWORK=hil-test

IPs="199.36.153.8 199.36.153.9 199.36.153.10 199.36.153.11"

gcloud beta dns --project=$PROJECT_ID managed-zones create googleapis --description="https://cloud.google.com/vpc/docs/configure-private-google-access#config" --dns-name="googleapis.com." --visibility="private" --networks=$NETWORK && \
gcloud beta dns --project=$PROJECT_ID record-sets transaction start --zone=googleapis
gcloud beta dns --project=$PROJECT_ID record-sets transaction add private.googleapis.com. --name=\*.googleapis.com. --ttl=300 --type=CNAME --zone=googleapis
gcloud beta dns --project=$PROJECT_ID record-sets transaction execute --zone=googleapis
gcloud beta dns --project=$PROJECT_ID record-sets transaction start --zone=googleapis
gcloud beta dns --project=$PROJECT_ID record-sets transaction add $IPs --name=private.googleapis.com. --ttl=300 --type=A --zone=googleapis
gcloud beta dns --project=$PROJECT_ID record-sets transaction execute --zone=googleapis

for domain in "${domains[@]}"
do
    # replace . with - for zone names
    NAME=$(echo $domain | tr . -)

    gcloud beta dns --project=$PROJECT_ID managed-zones create $NAME --description="https://cloud.google.com/vpc/docs/configure-private-google-access#config" --dns-name="$domain." --visibility="private" --networks=$NETWORK && \
    gcloud dns --project=$PROJECT_ID record-sets transaction start --zone=$NAME && \
    gcloud dns --project=$PROJECT_ID record-sets transaction add $IPs --name=$domain. --ttl=300 --type=A --zone=$NAME && \
    gcloud dns --project=$PROJECT_ID record-sets transaction execute --zone=$NAME && \
    gcloud dns --project=$PROJECT_ID record-sets transaction start --zone=$NAME && \
    gcloud dns --project=$PROJECT_ID record-sets transaction add $domain. --name=\*.$domain. --ttl=300 --type=CNAME --zone=$NAME && \
    gcloud dns --project=$PROJECT_ID record-sets transaction execute --zone=$NAME || exit $?
done