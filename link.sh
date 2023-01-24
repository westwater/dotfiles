# symlinks dotfiles to the home directory
ln -s $PWD/.zshrc ~
ln -s $PWD/.gitconfig ~
ln -s $PWD/kitty.conf $HOME/.config/kitty/kitty.conf
ln -s $PWD/global.sbt $HOME/.sbt/1.0/global.sbt

# symlink zsh plugins
ln -s $PWD/zsh/prepend-sudo $HOME/.oh-my-zsh/plugins/prepend-sudo
