# Install brew
command -v brew > /dev/null || { echo "> installing brew"; brew install diff-so-fancy; /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; }

# Install terminal commands
command -v diff-so-fancy > /dev/null || { echo "> installing diff-so-fancy"; brew install diff-so-fancy; }
command -v rbenv > /dev/null || { echo "> installing rbenv"; brew install rbenv; }
command -v direnv > /dev/null || { echo "> installing direnv"; brew install direnv; }

# Install terminal theme
[ -d $HOME/.oh-my-zsh/custom/themes/powerlevel10k ] || { echo "> installing powerlevel10k"; git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k; }
