output () {
  local class="${1:-undefined}"
  local text="$2"
  local tooltip="$3"

  local msg='\ue4e2'

  if test -z "$text"; then
    if test -z "$tooltip"; then
      msg="$msg\n\n$class"
    else
      msg="$msg\n$tooltip\n$class"
    fi
  else
    if test -z "$tooltip"; then
      msg="$msg $text\n\n$class"
    else
      msg="$msg $text\n$tooltip\n$class"
    fi
  fi

  echo -e "$msg"
}

parseStatus () {
    if test "$is" = 'Connected'; then
    return 0
  else
    return 1
  fi
}

outputStatus () {
  local raw="$(mullvad status -v | head -n 1)"

  local is="$(echo $raw | cut -d ' ' -f 1)"
  # local name="$(echo $raw | cut -d ' ' -f 3)"
  # local conn="$(echo $raw | cut -d ' ' -f 4)"
  # local ip="$(echo $conn | awk 'match($0, /[0-9]+(\.[0-9]+){3}/) { print substr($0, RSTART, RLENGTH)}')"
  # local port="$(echo $conn | awk 'match($0, /:[0-9]+\//) { print substr($0, RSTART+1, RLENGTH-2)}')"
  # local pkt="$(echo $conn | awk 'match($0, /\/.+\)/) { print substr($0, RSTART+1, RLENGTH-2)}')"
  local loc="$(echo $raw | cut -d ' ' -f 6,7)"
  # local city="$(echo $loc | cut -d ',' -f 1)"
  local country="$(echo $loc | cut -d ',' -f 2)"

  if test "$is" = 'Connected'; then
    output 'connected' "$country" "$raw"
  elif test "$is" = 'Connecting'; then
    output 'connecting' "" "$is"
  else
    output 'disconnected' "" "$is"
  fi
}

doToggle () {
  local raw="$(mullvad status -v)"
  local is="$(echo $raw | cut -d ' ' -f 1)"

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
