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

## copy the creation/modification times and exif tags
function sameSameFileData() {
  [[ $# != 2 ]] && { echo_rd "usage: $0 [in] [out]"; return 1; }
  infile="${1}"; outf="${2}";
  [ ! -e "$outf" ] && { echo_rd "sameSameFileData: $outf doesn't exist"; return 1; }
  touch -r "$infile" "$outf" || return 3; # copy the creation/modification times
  exiftool -overwrite_original -P -tagsFromFile "$infile" -Location:all -Time:all "$outf"  || { echo_rd "sameSameFileData error"; return 1; }
}

## re-encode a video to be 1/10th the size!
#  - uses exiftool to get orientation
#  - uses handbrake to re-encode the file
#  - uses touch to keep the same file-time
#  - uses exiftool to copy back the location and time data
function smallify() {
  [[ $# != 1 ]] && { echo_rd "usage: $0 [in]"; return 1; }
  local infile="${1}" fileData vopts;
  fileData="$(exiftool "$infile" -s2 -MIMEType -ImageWidth -ImageHeight -Rotation)" || { echo_rd "error reading file"; return 1; }
  fileData="${fileData//: /=}" #replace ': ' into = assignmant
  eval "${fileData// /_}" #strip spaces, put MIMEType, etc into the local scope

  echo_or "$infile -> type: ${MIMEType}, w: ${ImageWidth}, h: ${ImageHeight}, rot: ${Rotation}"

  if [[ "$MIMEType" == image/* ]]; then
    local outf;
    echo_bl "encoding $infile to $outf as a jpeg"
    outf="${infile%.*}.jpg"
    sips -s format jpeg -Z 2048 "$infile" --out "$outf"
    sameSameFileData "$infile" "$outf"
  elif [[ "$MIMEType" == video/* ]]; then
    outf="${infile%.*}.m4v"
    # if [[ "$ImageHeight" -gt 720 ]]; then
    #   echo_or "constraining height from $ImageWidth x $ImageHeight ($(( $ImageWidth / $ImageHeight)))"
    #   ImageWidth=$(( $ImageWidth * 720 / $ImageHeight )); ImageHeight=720;
    #   echo_or "constraining height to 720 (by $ImageWidth)"
    # fi
    ## set width/height (and support vertical)
    (( $Rotation % 180 == 0 )) && vopts=" -w$ImageWidth -l$ImageHeight " || vopts=" -w$ImageHeight -l$ImageWidth ";
    [[ $Rotation =  90 ]] && { vopts="$vopts --rotate=4 "; echo_ma "vertical video 90";  }
    [[ $Rotation = 270 ]] && { vopts="$vopts --rotate=7 "; echo_ma "vertical video 270"; }
    [[ $Rotation = 180 ]] && { vopts="$vopts --rotate=3 "; echo_ma "upside-down video";  }
    echo_bl "encoding $infile to $outf (rot=$Rotation) (vopts -> $vopts)"
    HandBrakeCLI -i "$infile" -o "$outf" --preset="Normal" --optimize -q22 $vopts || { echo_rd "error encoding"; return 1; }
    sameSameFileData "$infile" "$outf"  || { echo_rd "error copying metadata"; return 1; }
  else
    echo_rd "unknown type $MIMEType"
  fi

  [ ! -e "originals" ] && mkdir "originals"
  mv "$infile" "originals/$infile" || return 2;

  # echo_or "copying over exif information"
  # sameSameFileData "$infile" "$outf" || { echo_rd "error copying metadata"; return 1; }
  # echo_gr "done with $outf"
}

function smallifyAll() {
  mkdir -p "originals";
  for infile in "${@}"; do
    smallify "$infile" || return 1;
  done
}

## only execute this if this script is directly called
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  smallifyAll "${@}"
fi
