#!/usr/bin/env bash

set -eo pipefail

# Install brew (there is an m1 version but you need to specify arch before brew everytime)
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" 
 Then add the following to zshrc
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/westwater/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
