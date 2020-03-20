#!/bin/bash

set -e

cd "$(dirname "$0")"
. .credentials

export AUTHOR=Shou
export EMAIL=shou@lain.li
export CALENDAR=gcal
export FILETAGS=WORK

curl "$PRIVATE_GOOGLE_CAL_URL" 2>/dev/null | \
  awk -f ./ical2org.awk > "$TARGET_CAL_ORG"

# Run this script periodically
