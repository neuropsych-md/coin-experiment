#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# Alex Waite 2016

#
# MiSIT project
#   generate a conan set-file line for a given stimulus filename and rule-set
#
# Rule sets are defined near the bottom of this script

#
# VARS
#
readonly VERSION='1.0.0'
readonly SCRIPT_NAME=${0##*/}

FILE=''
RULE_SET=''

#
# Functions
#
Fatal() {
  printf '%s\n' "$*" >&2
  exit 1
}

Help() {
  cat << EOF
$SCRIPT_NAME v${VERSION}
generate a conan set-file line for a given stimulus file and rule-set

Syntax:
$SCRIPT_NAME [-h] [-V] | -r rule_set -f filename

OPTIONS:
  -h, --help       = print this help and exit
  -V, --version    = print the version number and exit

  -r, --rule-set   = rule-set to be used to calculate the answer and congruency.
                     please read this script's source for available rule-sets.
  -f, --filename   = stimulus filename

EXAMPLE:
  $SCRIPT_NAME --rule-set gbNW_pvNE --filename 02_green-SENW_farbe-left.png

EOF
}

#
# Parse Arguments
#

# help out if there are no arguments
[ -n "$1" ] || { Help; exit 1; }

while [ -n "$1" ]; do
  case "$1" in
    '-h'|'--help') Help; exit 0;;
    '-V'|'--version') printf '%s v%s\n' "$SCRIPT_NAME" "$VERSION"; exit 0;;

    '-f'|'--filename')
        [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."
        [ -z "${2##*_*-*_*-*.*}" ] || Fatal "Invalid stimulus filename. '$2' is not in the correct format (e.g. 02_green-SENW_farbe-left.png)."
        FILE=${2##*/}
        shift 1
        ;;
    '-r'|'--rule-set')
        [ -n "${2##-*}" ] || Fatal "'$1' requires an argument."
        RULE_SET=$2
        shift 1
        ;;
    *) Fatal "'$1' is not a valid '$SCRIPT_NAME' option.";;
  esac
  [ -n "$1" ] && shift 1 # only shift if there's anything left to shift
done

# Check if any required flags are missing
[ -z "$FILE" ] && Fatal "-f/--filename is required."
[ -z "$RULE_SET" ] && Fatal "-r/--rule-set is required."

#
# Main
#

# grab values from file-name (example: 02_green-SENW_farbe-left.png)
INDEX=${FILE%%_*} && FILE="${FILE#${INDEX}_}" # stim index (in Presentation) e.g. 01
COLOR=${FILE%%-*} && FILE="${FILE#${COLOR}-}" # color of stim e.g. green
DIREC=${FILE%%_*} && FILE="${FILE#${DIREC}_}" # hatching dir (cardinal directions) e.g. SWNE
FEATR=${FILE%%-*} && FILE="${FILE#${FEATR}-}" # relevant feature e.g. linie or farbe
CSIDE=${FILE%%.*} && FILE="${FILE#${CSIDE}.}" # cue side e.g. left or right

ANSWER='OOPS' # in case there's a foul-up in the rule-sets
case "$RULE_SET" in
  'gbNW_pvNE') # green,blue,northwest = left ; pink,violet,northeast = right
    case "$FEATR" in
         'farbe')
            case "$COLOR" in
              'green'|'blue') ANSWER='f' ;; # left
              'pink'|'violet') ANSWER='j' ;; # right
            esac ;;
         'linie')
            case "$DIREC" in # Hatching Direction
              'SENW'|'NWSE') ANSWER='f' ;; # left
              'SWNE'|'NESW') ANSWER='j' ;; # right
            esac ;;
    esac ;;
  *) Fatal "Invalid rule '$RULE_SET'"
esac

# check in case there was a non-match
[ "$ANSWER" = 'OOPS' ] && Fatal "'$COLOR' and/or '$DIREC' did not match in rule-set '$RULE_SET'."

# determine (in)congruency of cue and answer
CONGRUENCY=''
if [ "$CSIDE" = 'left' ] && [ "$ANSWER" = 'f' ]; then
  CONGRUENCY='con' # congruent
elif [ "$CSIDE" = 'right' ] && [ "$ANSWER" = 'j' ]; then
  CONGRUENCY='con' # congruent
else
  CONGRUENCY='incon' # incongruent
fi

# print out the sane set-line
printf '%s %s %s %s %s %s\n' "$INDEX" "$COLOR" "$DIREC" "$FEATR" "$CONGRUENCY" "$ANSWER"
