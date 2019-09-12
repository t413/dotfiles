# my useful dotfiles
yet another dotfiles repo. probably only useful to me 0_o

here's what I run on every new VM I setup:

```
sudo apt install git zsh fping screen byobu aptitude; [ -d ~/.zsh ] || git clone https://github.com/t413/dotfiles.git ~/.zsh; grep -q init.zsh ~/.zshrc || echo 'source $HOME/.zsh/init.zsh; [ -e $HOME/bin ] && export PATH="${PATH}:${HOME}/bin"; [ -e $HOME/.local/bin ] && export PATH="${PATH}:${HOME}/.local/bin"' | tee -a ~/.zshrc; zsh -c 'source ~/.zshrc && dotfileSetup'; [ ! -f ~/.ssh/authorized_keys ] && mkdir -p ~/.ssh && curl -sS https://github.com/t413.keys | tee -a ~/.ssh/authorized_keys; chsh -s $(which zsh) && loginctl terminate-user $USER;
```
