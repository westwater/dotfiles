# g - tab completion for available scripts
_g_completions() {
  local script_dir
  if [[ "${PWD:A}" == "${HOME:A}/.g" ]]; then
    script_dir="${PWD}/scripts"
  else
    script_dir="${PWD}/.g"
  fi
  local -a scripts
  [[ -d "$script_dir" ]] && scripts=(${script_dir}/[^._]*(N:t))
  scripts+=(${HOME}/.g/bin/[^._]*(N:t))
  (( ${#scripts} )) && compadd -a scripts
}
compdef _g_completions '~/.g/g'
