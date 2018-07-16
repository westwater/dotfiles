#!/usr/bin/env bash

# Renders an interactive menu of remote branches, ordered by most recently updated
# Selected branch will be checked out

source ~/dotfiles/scripts/option_menu.sh
source ~/dotfiles/scripts/colours.sh

branches=$(git for-each-ref --sort=-committerdate refs/remotes/ --format='%(HEAD) %(refname:short) - %(authorname) (%(committerdate:relative))')

SAVEIFS=$IFS         # Save current IFS
IFS=$'\n'            # Change IFS to new line
branches=($branches) # split to array $branches
IFS=$SAVEIFS         # Restore IFS

option_menu -q "Select a branch:" -s 10 "${branches[@]}"

choice=$?
choice=${branches[$choice]}

branch=$(echo $choice | grep -Eow "origin/[a-zA-Z0-9_-]+" | sed "s/origin\///g") # get branch and strip 'origin/'

yellow "  git checkout $branch"
git checkout -q $branch
