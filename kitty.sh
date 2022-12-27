#!/usr/bin/env bash

set -eo pipefail

if ! open -Ra "kitty"
then
	curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
else
	echo "kitty already installed"
fi
