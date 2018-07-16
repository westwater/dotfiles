#!/usr/bin/env bash

# adapted from https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
#   Options:
#     -i: (inverse) - sets the starting position to the last element
function select_option {

    usage() { echo "Usage: select_option [-is] <options>" 1>&2; exit 1; }

    # options
    local INVERSE=false # sets the starting position to the last element
    local SHOW # sets the amount of options to show at once

    while getopts ":is:" o; do
        case "${o}" in
            i) INVERSE=true ;;
            s) SHOW="$OPTARG" ;;
            *) usage ;;
        esac
    done

    # removes all the options that have been parsed by getopts
    # $1 will now refer to the first non-option argument
    shift "$((OPTIND-1))"

    # set SHOW to the amount of options supplied if unset
    SHOW="${SHOW:-$#}"

    echo "======================" >> /tmp/bash.log

    echo "show $SHOW" >> /tmp/bash.log

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    clear_selected()   { printf "  $ESC[K"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    # for opt in {1..$SHOW}; do printf "\n"; done
    for opt in {0..3}; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    # local startrow=$(($lastrow - $#))
    local startrow=$(($lastrow - 3))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    # trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0

    # sets starting location
    [[ "$INVERSE" = true ]] && selected=$(($# - 1)) || selected=0

    # store options here to access later
    IFS=$'\n' options=($@)
    echo "options size ${#options[@]}" >> /tmp/bash.log

    while true; do
        # print options by overwriting the last lines
        local slice
        local idx=0
        # maybe rebuild slice based on selected
        IFS=$'\n' slice=($(printf "%s\n" "${*:0:4}"))
        local slice_size="${#slice[@]}"

        for opt in "${slice[@]}"; do
            # only prints options up to the limit (slice size)
            if [ $idx -lt $slice_size ]; then
              if [ $selected -lt $slice_size ]; then
                cursor_to $(($startrow + $idx))
                if [ $idx -eq $selected ]; then
                    print_selected "$opt"
                else
                    print_option "$opt"
                fi
              else
                # slide options here - replace previous X lines with slide
                for slice_idx in {0..2}; do
                  cursor_to $(($startrow + $slice_idx))
                  if [ $slice_idx -eq $((slice_size - 1)) ]; then
                    clear_selected
                    print_selected "${options[(($selected - $slice_idx))]}"
                  else
                    clear_selected
                    print_option "${options[(($selected - $slice_idx))]}"
                  fi
                done
              fi
            fi

            ((idx++))
        done

        # key_input waits for user key input
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac

        echo "selected $selected" >> /tmp/bash.log
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}
