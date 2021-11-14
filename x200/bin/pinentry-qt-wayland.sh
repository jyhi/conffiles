#!/bin/sh

export QT_QPA_PLATFORM=wayland-egl
export DISPLAY=$WAYLAND_DISPLAY
export LC_TYPE=$LANG
exec /usr/bin/pinentry-qt $@
