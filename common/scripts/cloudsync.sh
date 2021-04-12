#!/bin/sh
set -e -o pipefail

if [ -f "$HOME/.config/cloudsync/config.sh" ]; then
  . "$HOME/.config/cloudsync/config.sh"
fi

if [ ! "$REMOTES" ]; then
  echo '$REMOTES must be defined as a space-separated list of rclone remotes.'
  exit 1
fi

if [ ! "$DIRS" ]; then
  echo '$DIRS must be defined as a space-separated list of directories.'
  exit 1
fi

if [ "$PROGRESS" ]; then
  RCLONE_FLAGS+=" --progress "
fi

for remote in $REMOTES; do
  for dir in $DIRS; do
    echo "Syncing $dir to $remote..."
    rclone sync $RCLONE_FLAGS "$HOME/$dir/" "$remote:$(cat /etc/hostname)/$dir/"
  done
done
