#!/usr/bin/env bash

# set -eo pipefail

source ~/dotfiles/scripts/select_option.sh
source ~/dotfiles/scripts/colours.sh

yesNo=("yes" "no")

if [[ -z $(git status -s) ]]; then
  blue "clean working directory"
  exit 0
fi

save_commit=$(git rev-parse --short HEAD)

yellow "> git add -A"
git add -A

yellow "> git commit --amend --no-edit"
git commit --amend --no-edit

echo
yellow "> git status"
git status

echo
blue "Ready to push?"
echo

select_option "${yesNo[@]}"
choice=$?
choice=${yesNo[$choice]}

if [ "$choice" == "no" ]; then
  blue "reverting..."
  yellow "> git reset --soft $save_commit"
  git reset --soft $save_commit
else
  branch=$(git rev-parse --abbrev-ref HEAD)
  yellow "> git push origin $branch --force-with-lease"
  git push origin $(git rev-parse --abbrev-ref HEAD) --force-with-lease
fi
