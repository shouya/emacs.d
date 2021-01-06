#!/bin/bash

set -e

cd "$(dirname "$0")"

# secrets.sh exports:
#
#  - PRIVATE_GOOGLE_CAL_URL
#  - TARGET_DIARY_FILE
source secrets.sh

export AUTHOR=Shou
export EMAIL=shou@lain.li
export CALENDAR=gcal
export FILETAGS=WORK

import_ical() {
  local src dest
  src="$1"
  dest="$2"

  import_expr="(icalendar-import-file \"$src\" \"$dest\")"
  emacs --batch -q --eval "$import_expr"
}

download_and_import() {
  curl -o "/tmp/work.ical" "$PRIVATE_GOOGLE_CAL_URL"
  tmp=$(mktemp)
  import_ical "/tmp/work.ical" "$tmp"
  mv "$tmp" "$TARGET_DIARY_FILE"
}


# download_and_import

# Run this script periodically
