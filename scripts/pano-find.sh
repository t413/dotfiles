#!/bin/bash

which echo_gr &>/dev/null || {
  ## fancy color output shortcuts ##
  [ -t 0 ] && hash tput 2>/dev/null && COLOR_SHELL=true || COLOR_SHELL=false
  function endcolor() { [ "$COLOR_SHELL" = true ] && echo "$(tput sgr 0)" || echo "$@"; }
  function echo_gr()  { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 0)$(tput setab 2) $@ $(endcolor)" || echo "$@"; }
  function echo_bl()  { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 7)$(tput setab 4) $@ $(endcolor)" || echo "$@"; }
  function echo_rd()  { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 7)$(tput setab 1) $@ $(endcolor)" || echo "$@"; }
  function echo_or()  { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 0)$(tput setab 3) $@ $(endcolor)" || echo "$@"; }
  function echo_ma()  { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 7)$(tput setab 5) $@ $(endcolor)" || echo "$@"; }
}
eerror() { echo_rd "$@" 1>&2; }

## find absolute value of difference between two values
function absDiff() {
  local diff;
  diff="$(echo "(${1//+/}) - (${2//+/})" | bc -l 2>&1)"
  [[ $diff =~ error ]] && return 1; ## { eerror "bc got error from $0 $@ -> $diff"; return 3; }
  printf "%0.3f" "${diff//-/}";
}

# function f() { printf "%0.3f" "${@}"; }

function findPano() {
  [ -d "$1" ] || { eerror "findPano needs directory"; return 1; }
  local f
  echo_bl "-- $1 --"
  local lastLat lastLon lastYaw lastPitch lastAlt
  for f in "$1/"*; do
    [ -d "$f" ] && { findPano "$f"; continue; }
    [[ "${f##*.}" != "JPG" ]] && continue;
    local fileData GPSLatitude GPSLongitude CameraYaw CameraPitch ImageWidth ImageHeight AbsoluteAltitude SpeedX SpeedY SpeedZ
    fileData="$(exiftool "${f}" -s2 -fast -n -GPSLatitude -GPSLongitude -CameraYaw -CameraPitch -ImageWidth -ImageHeight -AbsoluteAltitude -SpeedX -SpeedY -SpeedZ)" || { eerror "error reading file $f"; continue; }
    fileData="${fileData//: /=}" #replace ': ' into = assignmant
    eval "${fileData// /_}" #strip spaces, put vars into the local scope
    echo -n "$(basename "${f}") "
    echo -n "-> ${CameraYaw%.*}º<> ${CameraPitch%.*}º^ ${SpeedX%.*},${SpeedY%.*},${SpeedZ%.*}m/s"
    #@${GPSLatitude},${GPSLongitude}
    # if [[ ${ImageWidth} -gt ${ImageHeight} ]]; then
    #   echo "not vertical";
    #   continue; ##skip saving last* values
    if (( $(echo "(${SpeedX//+/} + ${SpeedY//+/} + ${SpeedZ//+/}) > 4" | bc -l) )); then
      echo_or "too fast";
    elif [[ -z ${lastAlt} ]]; then ## further tests need last* variables
      echo_or "need last photo first";
    elif [[ ${ImageWidth} -gt ${ImageHeight} && ${lastWidth} -lt ${lastHeight} ]]; then
      echo_or "change of orientation ${ImageWidth},${ImageHeight} vs ${lastWidth}, ${lastHeight}"
    elif [[ ${ImageWidth} -lt ${ImageHeight} && ${lastWidth} -gt ${lastHeight} ]]; then
      echo_or "change of orientation 2 ${ImageWidth},${ImageHeight} vs ${lastWidth}, ${lastHeight}"
    elif (( $(echo "$(absDiff ${AbsoluteAltitude} ${lastAlt}) > 1.0" | bc -l) )); then
      echo_or "too different altitudes: $(absDiff ${AbsoluteAltitude} ${lastAlt})";
    elif [[ ! -z $GPSLatitude ]] && (( $(echo "$(absDiff ${GPSLatitude} ${lastLat}) > 0.00005" | bc -l) )); then #roughly 15ft
      echo_or "too different lat: $(absDiff ${GPSLatitude} ${lastLat})";
    elif [[ ! -z $GPSLongitude ]] && (( $(echo "$(absDiff ${GPSLongitude} ${lastLon}) > 0.00005" | bc -l) )); then #roughly 15ft
      echo_or "too different lon: $(absDiff ${GPSLongitude} ${lastLon})";
    elif [[ ${ImageWidth} -gt ${ImageHeight} ]] && (( $(echo "$(absDiff ${CameraPitch} ${lastPitch}) < 10.0" | bc -l) )); then
      echo_or "vertical pano doens't change pitch enough: $(absDiff ${CameraPitch} ${lastPitch})º"
    elif [[ ${ImageWidth} -lt ${ImageHeight} ]] && (( $(echo "$(absDiff ${CameraYaw} ${lastYaw}) < 10.0" | bc -l) )); then
      echo_or "pano doens't change yaw enough: $(absDiff ${CameraYaw} ${lastYaw})º"
    else
      echo_gr "success! $(basename "$f") $(endcolor) $(absDiff ${CameraYaw} ${lastYaw})∆º"
      # hash tag 2>/dev/null && tag -a grey "$f"; ##color tag the file
    fi

    lastLat="${GPSLatitude}"
    lastLon="${GPSLongitude}"
    lastYaw="${CameraYaw}"
    lastPitch="${CameraPitch}"
    lastAlt="${AbsoluteAltitude}"
    lastWidth="${ImageWidth}"
    lastHeight="${ImageHeight}"
  done
}

## only execute this if this script is directly called
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  hash exiftool 2>/dev/null || { eerror "missing exiftool!"; return 1; }
  
  [ ! $# ] && findPano "$(pwd)";
  for f in "${@}"; do
    findPano "$f"
  done
fi
