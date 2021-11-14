#!/bin/sh

set -e -o pipefail

DEV="$1"

if [ ! "$DEV" ]; then
  echo "Usage: $0 <dev>"
  exit 1
fi

echo 1 | sudo tee "/sys/block/$(basename $DEV)/device/delete"
