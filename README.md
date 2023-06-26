# my useful dotfiles
yet another dotfiles repo. probably only useful to me 0_o

here's what I run on every new VM I setup:

### Deps

``` bash
sudo apt install git zsh fping screen byobu aptitude curl wget rsync nano avahi-daemon cryptsetup;
```

### ZSH Shell
``` bash
[ -d ~/.zsh ] || git clone https://github.com/t413/dotfiles.git ~/.zsh; grep -q init.zsh ~/.zshrc || echo 'source $HOME/.zsh/init.zsh; [ -e $HOME/bin ] && export PATH="${PATH}:${HOME}/bin"; [ -e $HOME/.local/bin ] && export PATH="${PATH}:${HOME}/.local/bin"' | tee -a ~/.zshrc;
```

``` bash
zsh -c 'source ~/.zshrc && dotfileSetup';
```

``` bash
chsh -s $(which zsh) && loginctl terminate-user $USER;
```

### SSH Keys
``` bash
[ ! -f ~/.ssh/authorized_keys ] && mkdir -p ~/.ssh && curl -sS https://github.com/t413.keys | tee -a ~/.ssh/authorized_keys; 
```

### Rmate
```bash
sudo wget -O /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate && sudo chmod a+x /usr/local/bin/rmate
```
