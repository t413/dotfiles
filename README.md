# my useful dotfiles
yet another dotfiles repo. probably only useful to me 0_o

here's what I run on every new VM I setup:

```
sudo apt install git zsh fping screen byobu aptitude; [ -d ~/.zsh ] || git clone https://github.com/t413/dotfiles.git ~/.zsh; grep -q init.zsh ~/.zshrc || echo 'source $HOME/.zsh/init.zsh' | tee -a ~/.zshrc; zsh -c 'source ~/.zshrc && dotfileSetup';
```
