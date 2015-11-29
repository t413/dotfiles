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

## re-encode a video to be 1/10th the size!
#  - uses exiftool to get orientation
#  - uses handbrake to re-encode the file
#  - uses touch to keep the same file-time
#  - uses exiftool to copy back the location and time data
function smallify() {
  [[ $# != 2 ]] && { echo_rd "usage: $0 [in] [out]"; return 1; }
  video="${1}"; outf="${2}";

  ROT=$(exiftool "$video" -Rotation -s3) || { echo_rd error; return 1; }
  if   [[ $ROT =  90 ]]; then vopts=" -w720 -l1280 --rotate=4 "; echo_ma "vertical video 90";
  elif [[ $ROT = 270 ]]; then vopts=" -w720 -l1280 --rotate=7 "; echo_ma "vertical video 270";
  else vopts=" -w1280 -l720 ";
  fi
  echo_bl "encoding $video to $outf (rot=$ROT)"
  HandBrakeCLI -i "$video" -o "$outf" --preset="Normal" --optimize -q22 $vopts || { echo_rd error; return 1; }
  touch -r "$video" "$outf" # copy the creation/modification times
  echo_or "copying over exif information"
  exiftool -overwrite_original -P -tagsFromFile "$video" -Location:all -Time:all "$outf"  || { echo_rd error; return 1; }
  echo_gr "done with $outf"
}

function smallifyAll() {
  for video in "${@}"; do
    smallify "$video" "${video%.*}.m4v"
  done
}

## only execute this if this script is directly called
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  smallifyAll "${@}"
fi
