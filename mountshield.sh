#!/bin/bash

# Define mount points and sources
MOUNTS=(
  "//192.168.68.56/reanim /media/shield/reanim"
  "//192.168.68.56/easystore2 /media/shield/easystore2"
)

CIFS_OPTIONS="rw,vers=3.0,credentials=/root/.shield-creds"

for MOUNT in "${MOUNTS[@]}"; do
  SRC=$(echo $MOUNT | awk '{print $1}')
  DST=$(echo $MOUNT | awk '{print $2}')
  
  # Create destination directory if it doesn't exist
  if [ ! -d "$DST" ]; then
    mkdir -p "$DST"
  fi

  # Mount the share
  mount -t cifs -o $CIFS_OPTIONS "$SRC" "$DST"
done