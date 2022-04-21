#!/bin/sh

tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    --format=posix --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    $@
