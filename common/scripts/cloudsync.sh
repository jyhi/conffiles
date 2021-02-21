#!/bin/sh
set -e -o pipefail

DIRS='Documents Pictures'

if [ ! "$REMOTE" ]; then
  echo '$REMOTE must be defined first.'
  exit 1
fi

for dir in $DIRS; do
  echo "Syncing $dir to $REMOTE..."
  rclone sync --progress "$HOME/$dir/" "$REMOTE:$(cat /etc/hostname)/$dir/"
done
