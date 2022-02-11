#!/usr/bin/env bash
# This script maintains and updates the DNS record on Google DNS for this workstation.
set -Eeuo pipefail

if [ ! -v ZONE_PROJECT ]; then
  printf "ZONE_PROJECT is not set\n"
  exit 1
fi

if [ ! -v ZONE_NAME ]; then
  printf "ZONE_NAME is not set\n"
  exit 1
fi

if [ ! -v DOMAIN ]; then
  printf "DOMAIN is not set\n"
  exit 1
fi

function get_external_ip() {
  curl -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip"
}

function update_record() {
  local zone_project zone domain ip
  zone_project="$1"
  zone="$2"
  domain="$3"
  ip="$4"

  gcloud --project "$zone_project" dns record-sets update "${domain}." \
    --rrdatas="$ip" \
    --type=A \
    --ttl=60 \
   --zone="$zone"
}

current_ip=""

while [ 1 ]; do
  public_ip="$(get_external_ip)"
  printf "resolved external IP as %s\n" "${public_ip}"

  if [ "${current_ip}" != "${public_ip}" ]; then
    update_record "${ZONE_PROJECT}" "${ZONE_NAME}" "${DOMAIN}" "${public_ip}"
    current_ip="${public_ip}"
    printf "updated %s to %s\n" "${DOMAIN}" "${current_ip}"
  fi

  echo "-> sleeping for 300s"
  sleep 300
done
