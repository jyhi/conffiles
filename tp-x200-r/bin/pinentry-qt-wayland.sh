#!/bin/sh

export QT_QPA_PLATFORM=wayland-egl
/usr/bin/pinentry-qt $@
