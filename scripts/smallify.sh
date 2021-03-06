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
  local infile="${1}" outf="${2}" metadata;
  [ ! -e "$outf" ] && { echo_rd "sameSameFileData: $outf doesn't exist"; return 1; }

  if file "${infile}" | grep -q "image data"; then
    metadata="$(exiftool -p '${Latitude}${Longitude}${AbsoluteAltitude}' -fast "${infile}" 2>/dev/null)" || return 1;
    echo "using ffmpeg to copy photo location $metadata to video $infile";
    mv "$outf" "${outf}.back" &&
    ffmpeg -i "${outf}.back" -metadata location="${metadata}" -metadata location-eng="${metadata}" -acodec copy -vcodec copy "$outf" -hide_banner -loglevel panic &&
    rm -f "${outf}.back" || return 1;
    # maybe use avmetareadwrite instead
  else
    mp4extract moov/meta "$infile" temp.txt || mp4extract moov/udta "$infile" temp.txt || { echo_rd "no mp4 loc"; return 3; }
    mv "$outf" "${outf}.back" &&
    mp4edit --insert moov:temp.txt "${outf}.back" "$outf" &&
    rm -f temp.txt "${outf}.back";
  fi

  touch -r "$infile" "$outf" || return 3; # copy the creation/modification times
  exiftool -overwrite_original -P -tagsFromFile "$infile" -Time:all "$outf" || { echo_rd "sameSameFileData error"; return 1; }
  return 0;
}

## re-encode a video to be 1/10th the size!
#  - uses exiftool to get orientation
#  - uses handbrake to re-encode the file
#  - uses touch to keep the same file-time
#  - uses exiftool to copy back the location and time data
function smallify() {
  [[ $# -lt 1 ]] && { echo_rd "usage: $0 [in] [outfile optional]"; return 1; }
  local infile="${1}" fileData vopts;
  fileData="$(exiftool "$infile" -api largefilesupport=1 -s2 -MIMEType -ImageWidth -ImageHeight -Rotation)" || { echo_rd "error reading file"; return 1; }
  fileData="${fileData//: /=}" #replace ': ' into = assignmant
  local ImageHeight ImageWidth Rotation MIMEType
  eval "${fileData// /_}" #strip spaces, put MIMEType, etc into the local scope

  echo_or "$infile -> type: ${MIMEType}, w: ${ImageWidth}, h: ${ImageHeight}, rot: ${Rotation}"

  if [[ "$MIMEType" == image/* ]]; then
    local outf;
    echo_bl "encoding $infile to $outf as a jpeg"
    outf="${infile%.*}.jpg"
    sips -s format jpeg -Z 2048 "$infile" --out "$outf"
    sameSameFileData "$infile" "$outf"
  elif [[ "$MIMEType" == video/* ]]; then
    outf="${2:-$(basename "${infile%.*}.mp4")}"; #
    [ "$outf" -ef "$infile" ] && { echo_rd "infile name == outfile"; return 2; }

    if [[ -z "$MAX_HEIGHT" ]]; then
      echo "export MAX_HEIGHT=720 to limit size (is $ImageHeight x $ImageWidth)";
    elif [[ "$ImageHeight" -gt "$MAX_HEIGHT" ]]; then
      ImageWidth=$(( $ImageWidth * $MAX_HEIGHT / $ImageHeight )); ImageHeight="$MAX_HEIGHT";
      echo_or "constraining to $ImageWidth x $ImageHeight"
    fi
    [[ -z "$QUALITY" ]] && echo "export QUALITY=22 to set quality (20 huge file, 28 tiny file)";
    vopts=("-q${QUALITY:-26}");
    ## set width/height (and support vertical)
    (( $Rotation % 180 == 0 )) && vopts+=("-w$ImageWidth" "-l$ImageHeight") || vopts+=("-w$ImageHeight" "-l$ImageWidth");
    [[ $Rotation =  90 ]] && { vopts+=("--rotate=4"); echo_ma "vertical video 90";  }
    [[ $Rotation = 270 ]] && { vopts+=("--rotate=7"); echo_ma "vertical video 270"; }
    [[ $Rotation = 180 ]] && { vopts+=("--rotate=3"); echo_ma "upside-down video";  }
    echo_bl "encoding $infile to $outf (rot=$Rotation) (vopts -> ${vopts[@]})"
    # --subtitle scan,1,2,3,4,5,6,7,8,9,10 -a 1,2,3,4,5,6,7,8,9,10
    HandBrakeCLI -i "$infile" -o "$outf" --preset="Normal" --optimize "${vopts[@]}" 2> /dev/null || { echo_rd "error encoding"; return 1; }
    # HandBrakeCLI -i "$infile" -o "$outf" -e x265 --optimize -q22 $vopts 2> /dev/null || { echo_rd "error encoding"; return 1; }
    sameSameFileData "$infile" "$outf"  || { echo_rd "error copying metadata"; return 1; }
  else
    echo_rd "unknown type $MIMEType"
  fi

  # mkdir -p "originals"
  # mv "$infile" "originals/$(basename "$infile")" || return 2;
  return 0;
  # echo_or "copying over exif information"
  # sameSameFileData "$infile" "$outf" || { echo_rd "error copying metadata"; return 1; }
  # echo_gr "done with $outf"
}

function smallifyAll() {
  local infile startt elapsed;
  for infile in "${@}"; do
    startt=$EPOCHSECONDS
    smallify "$infile"; #|| return 1;
    elapsed=$(( EPOCHSECONDS - startt ))
    type bgnotify_formatted 2> /dev/null | grep -q 'function' && bgnotify_formatted 0 "smallify \"$infile\"" "$elapsed" || tput bel;
  done
}

## only execute this if this script is directly called
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  smallifyAll "${@}"
fi
