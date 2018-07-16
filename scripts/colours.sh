# colour variables
RED=31
GREEN=32
YELLOW=33
BLUE=34

# colour functions
# note: \e[0m resets the colour after the text

colour_text(){ echo -e "\033[0;${BLUE}m$@\033[0m" ; }
dark_colour_text(){ echo -ne "\033[2;$1m$2\033[0m" ; }

blue(){ echo -e "\033[0;${BLUE}m$@\033[0m" ; }
dark_blue(){ echo $(dark_colour_text $BLUE $1) ; }
yellow(){ echo -e "\033[0;${YELLOW}m$@\033[0m" ; }
dark_yellow(){ echo $(dark_colour_text $YELLOW $1) ; }
