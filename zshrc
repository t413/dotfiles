export PREZTO=$HOME/.zprezto
zstyle ':prezto:*:*' color 'yes'
zstyle ':prezto:load' pmodule \
  'environment' 'terminal' 'history' 'directory' \
  'spectrum' 'utility' 'completion' 'prompt' python ruby rsync\
  git ssh 'history-substring-search' osx
zstyle ':prezto:module:prompt' theme 'sorin'
source $PREZTO/init.zsh
export PATH=/usr/local/bin:$PATH ## gives brew installs priority

source $HOME/.zsh/zsh-background-notify/bgnotify.plugin.zsh
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

## zsh-autosuggestions setup ##
source $HOME/.zsh/zsh-autosuggestions/autosuggestions.zsh
bindkey '^T' autosuggest-toggle # use ctrl+t to toggle autosuggestions

alias make="make -j 6"

## from https://news.ycombinator.com/item?id=10143143
# echo hello | clip copies hellp to clipboard
function clip { [ -t 0 ] && pbpaste || pbcopy }

## cool colored echo commands (where it's supported)
function echo_gr()  { [ -t 0 ] && echo "$(tput setaf 7)$(tput setab 2) $@ $(tput sgr 0)" || echo "$@"; }
function echo_bl()  { [ -t 0 ] && echo "$(tput setaf 7)$(tput setab 4) $@ $(tput sgr 0)" || echo "$@"; }
function echo_rd()  { [ -t 0 ] && echo "$(tput setaf 7)$(tput setab 1) $@ $(tput sgr 0)" || echo "$@"; }
function echo_or()  { [ -t 0 ] && echo "$(tput setaf 7)$(tput setab 3) $@ $(tput sgr 0)" || echo "$@"; }
function echo_ma()  { [ -t 0 ] && echo "$(tput setaf 7)$(tput setab 5) $@ $(tput sgr 0)" || echo "$@"; }
function endcolor() { [ -t 0 ] && echo "$(tput sgr 0)" || echo "$@"; }

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

function toggleBack() { # toggle *.back on a file
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

vnc_start() {
  echo -n "Set VNC Password: "; read -s passwd;
  echo "\n -> got it! (size ${#passwd}) - $passwd"
  sleep 1; echo "setting ARDAgent";
  sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -activate -configure -access -on -clientopts \
    -setvnclegacy -vnclegacy yes -clientopts -setvncpw \
    -vncpw "$passwd" -restart -agent -privs -all
  echo 'done!'
}

vnc_stop() {
  sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
    -deactivate -configure -access -off
}


## removes sketchy / unneeded ssl certs
function secureSSL() {
  ## from https://github.com/drduh/OS-X-Yosemite-Security-and-Privacy-Guide ##
  function remove {
    echo_bl "Removing ${2}"
    sudo /usr/bin/security delete-certificate \
      -t -Z $1 \
      /System/Library/Keychains/SystemRootCertificates.keychain && echo_gr "success" || echo_rd "failure";
  }
  remove "D1EB23A46D17D68FD92564C2F1F1601764D8E349" "AAA Certificate Services"
  remove "4F99AA93FB2BD13726A1994ACE7FF005F2935D1E" "China Internet Network Information Center Root CA"
  remove "8BAF4C9B1DF02A92F7DA128EB91BACF498604B6F" "CNNIC"
  remove "8C941B34EA1EA6ED9AE2BC54CF687252B4C9B561" "DoD Root CA 2"
  remove "10F193F340AC91D6DE5F1EDC006247C4F25D9671" "DoD CLASS 3 Root CA"
  remove "8C96BAEBDD2B070748EE303266A0F3986E7CAE58" "EBG"
  remove "51C6E70849066EF392D45CA00D6DA3628FC35239" "E-Tugra Certification Authority"
  remove "905F942FD9F28F679B378180FD4F846347F645C1" "Federal Common Policy CA"
  remove "FE45659B79035B98A161B5512EACDA580948224D" "Hellenic Academic and Research Institutions RootCA 2011"
  remove "D6DAA8208D09D2154D24B52FCB346EB258B28A58" "Hongkong Post Root CA 1"
  remove "D2441AA8C203AECAA96E501F124D52B68FE4C375" "I.CA"
  remove "270C500CC6C86ECB1980BC1305439ED282480BE3" "MPHPT Certification Authority"
  remove "06083F593F15A104A069A46BA903D006B7970991" "NetLock Arany"
  remove "E392512F0ACFF505DFF6DE067F7537E165EA574B" "NetLock Expressz"
  remove "016897E1A0B8F2C3B134665C20A727B7A158E28F" "NetLock Minositett Kozjegyzoi"
  remove "ACED5F6553FD25CE015F1F7A483B6A749F6178C6" "NetLock Kozjegyzoi"
  remove "2DFF6336E33A4829AA009F01A1801EE7EBA582BB" "Prefectural Association For JPKI"
  remove "8782C6C304353BCFD29692D2593E7D44D934FF11" "SecureTrust CA"
  remove "E19FE30E8B84609E809B170D72A8C5BA6E1409BD" "Trusted Certificate Services"
  remove "3BC0380B33C3F6A60C86152293D9DFF54B81C005" "Trustis FPS Root CA"
  remove "B091AA913847F313D727BCEFC8179F086F3A8C0F" "TW Government Root Certification Authority"
  remove "1B4B396126276B6491A2686DD70243212D1F1D96" "TurkTrust 1"
  remove "7998A308E14D6585E6C21E153A719FBA5AD34AD9" "TurkTrust 2"
  remove "B435D4E1119D1C6690A749EBB394BD637BA782B7" "TurkTrust 3"
  remove "F17F6FB631DC99E3A3C87FFE1CF1811088D96033" "TurkTrust 4"
  remove "0B972C9EA6E7CC58D93B20BF71EC412E7209FABF" "UCA Global Root"
  remove "8250BED5A214433A66377CBC10EF83F669DA3A67" "UCA Root"
  remove "CB44A097857C45FA187ED952086CB9841F2D51B5" "US Govt Common Policy"
  remove "FAA7D9FB31B746F200A85E65797613D816E063B5" "VRK Gov. Root CA"
  remove "E7B4F69D61EC9069DB7E90A7401A3CF47D4FE8EE" "WellsSecure Public Root Certificate Authority"
}

