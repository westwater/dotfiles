#!/usr/bin/env bash

set -eo pipefail

if [ -d "kitty.app" ]
then
	# Install Kitty terminal on Apple silicon Mac (need to build from source)
	brew_install pkg-config
	brew_install harfbuzz
	brew_install little-cms2
	# git clone https://github.com/kovidgoyal/kitty && cd kitty
	# make app
	# Move kitty.app to applications folder
else
	echo "kitty already installed"
fi
