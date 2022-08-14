# Script supporting a Mullvad VPN widget on waybar.
#
# SPDX-FileCopyrightText: 2022 Junde Yhi <junde@yhi.moe>
# SPDX-License-Identifier: MIT

# Usage: output <class> [<text> [<tooltip>]]
output () {
  local class="${1:-undefined}"
  local text="$2"
  local tooltip="$3"

  local icon="${ICON:-\ue4e2}"

  if test -z "$text"; then
    if test -z "$tooltip"; then
      msg="{\"class\": \"$class\", \"text\": \"$icon\"}"
    else
      msg="{\"class\": \"$class\", \"text\": \"$icon\", \"tooltip\": \"$tooltip\"}"
    fi
  else
    if test -z "$tooltip"; then
      msg="{\"class\": \"$class\", \"text\": \"$icon $text\"}"
    else
      msg="{\"class\": \"$class\", \"text\": \"$icon $text\", \"tooltip\": \"$tooltip\"}"
    fi
  fi

  echo "$msg"
}

# Usage: outputStatus
outputStatus () {
  local raw="$(mullvad status -v)"

  local is="$(echo $raw | cut -d ' ' -f 1)"
  # local name="$(echo $raw | cut -d ' ' -f 3)"
  # local conn="$(echo $raw | cut -d ' ' -f 4)"
  # local ip="$(echo $conn | awk 'match($0, /[0-9]+(\.[0-9]+){3}/) { print substr($0, RSTART, RLENGTH)}')"
  # local port="$(echo $conn | awk 'match($0, /:[0-9]+\//) { print substr($0, RSTART+1, RLENGTH-2)}')"
  # local pkt="$(echo $conn | awk 'match($0, /\/.+\)/) { print substr($0, RSTART+1, RLENGTH-2)}')"
  local loc="$(echo $raw | cut -d ' ' -f 6,7)"
  # local city="$(echo $loc | cut -d ',' -f 1)"
  local country="$(echo $loc | cut -d ' ' -f 2)"
  # local type="$(echo $raw | cut -d ' ' -f 10)"

  # local tooltip="\uf233\t$name\n\uf0ac\t$ip:$port\n\uf124\t$loc\n\uf1b2\t$type/$pkt"
  local tooltip=$(printf "$raw" | tr '\n' ';' | sed -e 's/;/\\n/g')

  if test "$is" = 'Connected'; then
    output 'connected' "$country" "$tooltip"
  elif test "$is" = 'Connecting'; then
    output 'connecting' "" "$is"
  else
    output 'disconnected' "" "$is"
  fi
}

# Usage: doToggle
doToggle () {
  local raw="$(mullvad status -v)"
  local is="$(echo "$raw" | cut -d ' ' -f 1)"

  if test "$is" = 'Disconnected'; then
    mullvad connect 
  else
    mullvad disconnect
  fi
}

ACTION="$1"

case "$ACTION" in
  'status') outputStatus ;;
  'toggle') doToggle ;;
  *) ;;
esac
