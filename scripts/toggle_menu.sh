#!/usr/bin/env bash

# Input: array of associative arrays (dictionary)

# todos:
# - format printf to pad space ebtween key and value to length of longest key

# set -e

toggle_menu() {

	debug() { echo "$@" >> /tmp/bash.log ;}

	local selected=0 # keeps track of which option is selected

    declare -A _toggles
    declare -n inhash=$1

    # helpers for terminal print control and key input
        cursor_blink_on()  { printf "\033[?25h"; }
        cursor_blink_off() { printf "\033[?25l"; }
        cursor_to()        { printf "\033[$1;${2:-1}H"; }
        print_toggle()     { local key=$1 local value="${_toggles[$key]}";
        					 if [ $value -eq 0 ]; then value="\033[0;31moff\033[0m";
        					 else value="\033[0;32mon\033[0m"; fi
        					 printf "  $key $value"; }
        print_selected()   { local key=$1 local value="${_toggles[$key]}";
        					 if [ $value -eq 0 ]; then value="\033[0;31moff\033[0m";
              			     else value="\033[0;32mon\033[0m"; fi
        					 printf "\033[0;33m>\033[0m $key $value"; }
        clear_selected()   { printf "  \033[K"; }
        get_cursor_row()   { IFS=';' read -sdR -p $'\033[6n' ROW COL; echo ${ROW#*[}; }
       	toggle()           { local key=$1; local value="${_toggles[$key]}"
	     				     if [ $value -eq 0 ]; then _toggles[$key]=1; else _toggles[$key]=0; fi }
        key_input()        { read -s -n3 key 2>/dev/null >&2
                            if [[ $key = $'\033[A' ]]; then echo up;    fi
                            if [[ $key = $'\033[B' ]]; then echo down;  fi
                            if [[ $key = $'\033[D' ]]; then echo left;  fi
                            if [[ $key = $'\033[C' ]]; then echo right; fi
                            if [[ $key = ""     ]]; then echo enter;    fi; }

    for param in "${!inhash[@]}"; do
        debug $param
        _toggles[$param]="${inhash[$param]}"
    done
    
    toggles_size="${#_toggles[@]}"

	# Array to hold indexes for associative array
    keys=("${!_toggles[@]}")

    debug "keys size: ${#keys[@]}"

    echo -e "Docker services:"

    # initially print empty new lines
    # will scroll down if at bottom of screen
    for ((n=0; n <= $toggles_size; n++)); do printf "\n"; done

    cursor_blink_off

    last_row=`get_cursor_row`
    starting_row=$(($last_row - $toggles_size))

	debug "starting row: $starting_row"
    debug "last row: $last_row"

    cursor_to $starting_row 0

	debug "pre while"

	while true; do

		for ((i=0; i < $toggles_size; i+=1)); do
			key=${keys[$i]}
			cursor_to $(($starting_row + $i))
			clear_selected
			print_toggle $key

			if [ $i -eq $selected ]; then
				cursor_to $(($starting_row + $i))
				clear_selected
				print_selected $key
			fi
		done

		debug "selcted $selected"
	
        # key_input waits for user key input
	    case `key_input` in
	        enter) break;;
	        up)    ((selected--));
	                if [ $selected -lt 0 ]; then selected=$(($toggles_size - 1)); fi;;
	        down)  ((selected++));
	                if [ $selected -ge $toggles_size ]; then selected=0; fi;;
			left)  toggle "${keys[$selected]}";;					
			right) toggle "${keys[$selected]}";;
	    esac
	done

	debug "done"
	cursor_blink_on

	return 1
}
