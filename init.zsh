#!/bin/zsh

THISZDIR="$(dirname "$0")"
HISTFILE="$THISZDIR/.zhistory"
export PREZTO="$THISZDIR/.zprezto"
if [ -e "$PREZTO" ]; then
  zstyle ':prezto:*:*' color 'yes'
  zstyle ':prezto:load' pmodule \
    environment terminal history directory \
    spectrum utility prompt completion 'syntax-highlighting' \
    git ssh tmux 'history-substring-search'
  zstyle ':prezto:module:prompt' theme sorin
  source "$PREZTO/init.zsh"
  
  [[ "$OSTYPE" == "darwin"* ]] && pmodload osx
else
  export ZSH="$THISZDIR/oh-my-zsh"
  if [ -e "$ZSH" ]; then
    plugins=(git bgnotify)
    source "$ZSH/oh-my-zsh.sh"
    source "$THISZDIR/custom-ohmyzsh-sorin.zsh" # ZSH_THEME="sorin"
  else
    echo "not setup, run dotfileSetup to clone stuff"
  fi
fi
# echo "$(date +"%Y-%m-%d %H:%M:%S.%3N") finished loading zshrc in $(( $(($(date +%s%N)/1000000000.0)) - $start))s"

## fancy color output shortcuts ##
[ -t 0 ] && hash tput 2>/dev/null && COLOR_SHELL=true || COLOR_SHELL=false
function clr_gr()   { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 0)$(tput setab 2)"; }
function clr_bl()   { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 7)$(tput setab 4)"; }
function clr_rd()   { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 7)$(tput setab 1)"; }
function clr_or()   { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 0)$(tput setab 3)"; }
function clr_ma()   { [ "$COLOR_SHELL" = true ] && echo "$(tput setaf 7)$(tput setab 5)"; }
function endcolor() { [ "$COLOR_SHELL" = true ] && echo "$(tput sgr 0)" || echo "$@"; }

function echo_gr()  { [ "$COLOR_SHELL" = true ] && echo "$(clr_gr) $@ $(endcolor)" || echo "$@"; }
function echo_bl()  { [ "$COLOR_SHELL" = true ] && echo "$(clr_bl) $@ $(endcolor)" || echo "$@"; }
function echo_rd()  { [ "$COLOR_SHELL" = true ] && echo "$(clr_rd) $@ $(endcolor)" || echo "$@"; }
function echo_or()  { [ "$COLOR_SHELL" = true ] && echo "$(clr_or) $@ $(endcolor)" || echo "$@"; }
function echo_ma()  { [ "$COLOR_SHELL" = true ] && echo "$(clr_ma) $@ $(endcolor)" || echo "$@"; }
function vmd5() { openssl md5 "$1" | awk '{ print $2 }'; }

BG_NOTIFY="$THISZDIR/bgnotify"
[ -e "$BG_NOTIFY" ] && source "$BG_NOTIFY/bgnotify.plugin.zsh"

function versionCompare() {
  [ "$1" = "$(echo -e "$1\n$2" | sort -t '.' -k 1,1 -k 2,2 -k 3,3 -k 4,4 -g | head -n1)" ]
}

function dotfileSetup() {
  versionCompare '4.3.17' $(zsh --version | awk '{print $2}') && ZSH_RECENT=true
  if [[ $ZSH_RECENT = true && ! -e "$PREZTO" ]]; then
    echo_or "cloning zprezto"
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$PREZTO"
  elif [[ ! -e "$THISZDIR/oh-my-zsh" ]]; then
    echo_or "cloning oh-my-zsh"
    git clone git://github.com/robbyrussell/oh-my-zsh.git "$THISZDIR/oh-my-zsh"
  fi
  if [[ ! -e "$BG_NOTIFY" && -e $PREZTO ]]; then
    echo_or "cloning zsh-background-notify"
    git clone https://github.com/t413/zsh-background-notify.git "$BG_NOTIFY"
  fi
  [[ ! -e "$HOME/.screenrc"  ]] && { echo_gr "linking screenrc";  ln -s "$THISZDIR/screenrc" "$HOME/.screenrc" }
  [[ ! -e "$HOME/.tmux.conf" ]] && { echo_gr "linking tmux.conf"; ln -s "$THISZDIR/tmux.conf" "$HOME/.tmux.conf" }
}

alias make="make -j 6"

function ssh-copy-id() {
    cat ~/.ssh/id_rsa.pub | ssh "$1" "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
}

function gitx() {
  [ -z "$*" ] && args="." || args=("$@")
  for var in "${args[@]}"; do
    base=$(git -C "${var}" rev-parse --show-toplevel) || return 3;
    if hash gitup 2>/dev/null; then #osx with gitup installed
      ( cd "${base}" && command gitup &> /dev/null &)
    elif hash gitx 2>/dev/null; then #osx with gitx installed
      ( cd "${base}" && command gitx &> /dev/null &)
    elif hash gitg 2>/dev/null; then #linux with gitg
      reponame=$(basename "${base}")
      # try and get window id
      hash xdotool 2>/dev/null && owindow=$(xdotool search --name "gitg - $reponame" 2>/dev/null)
      if [ "$owindow" != "" ]; then
        echo "opening existing window for '$reponame'"
        xdotool windowactivate "$owindow"
      else
        ( gitg "${base}" &> /dev/null &)
      fi
    else
      echo "error, no supported git-visualizer"
    fi
  done
}

# toggle *.back on a file
function toggleBack() {
  for var; do
    if [ -f "${var}" ]; then
      mv "${var}" "${var}".back
    elif [ -f "${var}.back" ]; then
      mv "${var}.back" "${var}"
    else
      echo "file ${var}.back not found!"
    fi
  done
}

## from https://github.com/kepkin/dev-shell-essentials/blob/master/highlight.sh
function highlight() {
    declare -A fg_color_map
    fg_color_map[black]=30
    fg_color_map[red]=31
    fg_color_map[green]=32
    fg_color_map[yellow]=33
    fg_color_map[blue]=34
    fg_color_map[magenta]=35
    fg_color_map[cyan]=36

    fg_c=$(echo -e "\e[1;${fg_color_map[$1]}m")
    c_rs=$'\e[0m'
    while read -r line; do echo $line | sed s"/$2/$fg_c\0$c_rs/"; done
}
