#!/bin/sh

sudo mount -o uid=$(id -u),gid=$(id -g),fmask=133,dmask=022 $@
