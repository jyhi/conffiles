#!/bin/sh

BRI="$(cat /sys/class/backlight/intel_backlight/actual_brightness)"

if [ "$BRI" = "0" ]; then
  swaymsg output \* dpms on
else
  swaymsg output \* dpms off
fi
