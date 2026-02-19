# g - tab completion for available scripts
_g_completions() {
  local script_dir
  if [[ "${PWD:A}" == "${HOME:A}/.g" ]]; then
    script_dir="${PWD}/scripts"
  else
    script_dir="${PWD}/.g"
  fi
  [[ -d "$script_dir" ]] || return
  local -a scripts
  scripts=(${script_dir}/[^._]*(N:t))
  (( ${#scripts} )) && compadd -a scripts
}
compdef _g_completions ~/.g/g
