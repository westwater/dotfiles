#!/usr/bin/env bash

set -eo pipefail

brew_install() {
    if brew list $1 &>/dev/null; then
        echo "${1} is already installed"
    else
        brew install $1
    fi
}

curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

if open -Ra "kitty"
then
	# Install Kitty terminal on Apple silicon Mac (need to build from source)
	brew_install pkg-config
	brew_install harfbuzz
	brew_install little-cms2
	# git clone https://github.com/kovidgoyal/kitty /tmp/kitty && cd /tmp/kitty
	# make app
	# Move kitty.app to applications folder
else
	echo "kitty already installed"
fi
