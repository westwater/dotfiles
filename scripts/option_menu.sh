#!/usr/bin/env bash

# set -e

# adapted from https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
#   Options:
#     -q: (question) - REQUIRED - the question to ask
#     -i: (inverse)  - sets the starting position to the last element - default: false
#     -s: (show)     - controls how many options to show - default: the number of options supplied
#     -p: (pattern)  - runs the selected answer through the provided regex pattern
#                      first before being printed as the answer next to the question
option_menu() {
  usage() { echo "Usage: menu [-is] -q <question> <answers>" 1>&2; exit 1; }

  debug() { echo "$@" >> /tmp/bash.log ;}

  # stops multiple calls to option_menu in the same session sharing OPTIND state
  unset OPTIND

  # options
  local QUESTION
  local INVERSE=false
  local SHOW
  local PATTERN

  # internal variables
  local selected=0 # keeps track of which option is selected

  while getopts ":is:q:p:" o; do
      case "${o}" in
          q) QUESTION="$OPTARG" ;;
          i) INVERSE=true ;;
          s) SHOW="$OPTARG" ;;
          p) PATTERN="$OPTARG" ;;
          *) usage ;;
      esac
  done

  debug "========================"

  # if no question was supplied, print usage and exit
  [[ -z "$QUESTION" ]] && { echo "Question was not provided"; usage; }

  # removes all the options that have been parsed by getopts
  # $1 will now refer to the first non-option argument
  shift "$((OPTIND-1))"

  # set SHOW to the amount of options supplied if
  # unset or greater than amount of options
  [[ -z "$SHOW" || "$SHOW" -gt "$#" ]] && SHOW=$#

  # helpers for terminal print control and key input
  cursor_blink_on()  { printf "\033[?25h"; }
  cursor_blink_off() { printf "\033[?25l"; }
  cursor_to()        { printf "\033[$1;${2:-1}H"; }
  print_option()     { printf "   $1 "; }
  print_selected()   { printf "  \033[7m $1 \033[27m"; }
  clear_selected()   { printf "  \033[K"; }
  get_cursor_row()   { IFS=';' read -sdR -p $'\033[6n' ROW COL; echo ${ROW#*[}; }
  key_input()        { read -s -n3 key 2>/dev/null >&2
                        if [[ $key = $'\033[A' ]]; then echo up;    fi
                        if [[ $key = $'\033[B' ]]; then echo down;  fi
                        if [[ $key = ""     ]]; then echo enter; fi; }

  green(){ echo -e "\033[0;32m$@\033[0m" ; }
  yellow(){ echo -e "\033[0;33m$@\033[0m" ; }

  cursor_blink_off

  # initially print empty new lines
  # will scroll down if at bottom of screen
  for ((n=0; n <= $SHOW; n++)); do printf "\n"; done

  debug "row after empty lines $(get_cursor_row) - show $SHOW"

  # store options here to access when printing
  IFS=$'\n' opts=($@)
  opts_size="${#opts[@]}"

  # determine bounds for displaying options
  lastrow=`get_cursor_row`
  startrow=$(($lastrow - $SHOW))

  debug "start $startrow"

  # used to determine the last page
  remainder=$((opts_size % SHOW))

  if [[ $remainder -eq 0 ]]; then
    last_page=$((opts_size / SHOW))
  else
    last_page=$(((opts_size / SHOW) + 1))
  fi

  # sets starting location
  if [[ "$INVERSE" = true ]]; then
    selected=$(($# - 1))
    page=$last_page
  else
    selected=0
    page=1
  fi

  # this is done after the empty lines are printed in case
  # the bottom of the terminal is hit and it scrolls down
  question_row=$(($(get_cursor_row) - $SHOW - 1))

  cursor_to $question_row 0
  clear_selected

  # write question with page number if more than 1 page
  if [ "$last_page" -gt 1 ]; then
    page_number=$(green "page $page of $last_page")
    echo -e "$QUESTION $page_number"
  else
    echo -e "$QUESTION"
  fi

  debug "question asked on line $question_row"

  while true; do

      for ((i=0; i < $opts_size; i++)); do
          # floor and ceiling set bounds for printing
          floor=$((SHOW * (page - 1)))
          ceiling=$((SHOW * page))

          if [[ $i -ge $floor && $i -lt $ceiling ]]; then
              cursor_to $(($startrow + ($i - $floor)))
              clear_selected
              if [ $page -eq $last_page ]; then
                if [[ $i -lt $((opts_size - 1)) ]]; then
                  print_option "${opts[i]}"
                else # last element
                  print_option "${opts[i]}"
                  # clear rest if not enough to fill last page
                  for ((j=1; j <= $((SHOW - remainder)); j++)); do
                    cursor_to $(($startrow + ($i + $j - $floor)))
                    clear_selected
                  done
                fi
                if [ $i -eq $selected ]; then
                  cursor_to $(($startrow + ($i - $floor)))
                  clear_selected
                  print_selected "${opts[i]}"
                fi
              elif [ $i -eq $selected ]; then
                cursor_to $(($startrow + ($i - $floor)))
                clear_selected
                print_selected "${opts[i]}"
              else # not selected or last page
                print_option "${opts[i]}"
              fi
          fi
      done

      # key_input waits for user key input
      case `key_input` in
          enter) break;;
          up)    ((selected--));
                  if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
          down)  ((selected++));
                  if [ $selected -ge $# ]; then selected=0; fi;;
      esac

      debug "selected $selected"

      # update page incase user has moved on
      page=$((($selected/$SHOW)+1))
      debug "page $page"

      # reprint question with page number if more than 1 page
      # incase it has changed
      if [ "$last_page" -gt 1 ]; then
        cursor_to $question_row 0
        clear_selected
        page_number=$(green "page $page of $last_page")
        echo -e "$QUESTION $page_number"
      fi
  done

  # clear options and question
  for ((n=0; n < $SHOW+2; n++)); do # 2 is the amount of new lines created from the question
    cursor_to $((lastrow-n)) 0
    clear_selected
  done

  cursor_blink_on

  # reprint question with answer over original question
  answer=$(green ${opts[$selected]})
  echo -n "$QUESTION $answer"

  # move cursor back to where the first option was placed (1 below the question)
  cursor_to $((startrow)) 0

  debug "end $((startrow))"

  return $selected
}
