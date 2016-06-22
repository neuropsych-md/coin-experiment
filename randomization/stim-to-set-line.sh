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
readonly VERSION='1.1.0'
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
  $SCRIPT_NAME --rule-set gbNW_pvNE --filename 02_green-SENW-330_farbe-left.png

EOF
}

# consult rule tables and return appropriate answer for a given rule-set
#
# Accepts a rule-set, relevant feature, and relevant feature's question
#  e.g. LookupAnswer 'gbNW_pvNE' 'farbe' 'green'
# Echos the answer in the format of  'f' (left) or 'j' (right)
LookupAnswer() {
  local rule_set=$1
  local feature=$2
  local question=$3

  local answer='OOPS' # in case there's a foul-up in the rule-sets
  case "$rule_set" in
    'gbNW_pvNE') # green,blue,northwest = left ; pink,violet,northeast = right
      case "$feature" in
           'farbe')
              case "$question" in # color
                'green'|'blue') answer='f' ;; # left
                'pink'|'violet') answer='j' ;; # right
              esac ;;
           'linie')
              case "$question" in # Hatching Direction
                'SENW'|'NWSE') answer='f' ;; # left
                'SWNE'|'NESW') answer='j' ;; # right
              esac ;;
      esac ;;
    'pvNW_gbNE') # pink,violet,northwest = left ; green,blue,northeast = right
      case "$feature" in
           'farbe')
              case "$question" in # color
                'pink'|'violet') answer='f' ;; # left
                'green'|'blue') answer='j' ;; # right
              esac ;;
           'linie')
              case "$question" in # Hatching Direction
                'SENW'|'NWSE') answer='f' ;; # left
                'SWNE'|'NESW') answer='j' ;; # right
              esac ;;
      esac ;;
    'bpSW_gvSE') # blue,pink,southwest = left ; green,violet,southeast = right
      case "$feature" in
           'farbe')
              case "$question" in # color
                'blue'|'pink') answer='f' ;; # left
                'green'|'violet') answer='j' ;; # right
              esac ;;
           'linie')
              case "$question" in # Hatching Direction
                'SWNE'|'NESW') answer='f' ;; # left
                'SENW'|'NWSE') answer='j' ;; # right
              esac ;;
      esac ;;
    'gvSW_bpSE') # green,violet,southwest = left ; blue,pink,southeast = right
      case "$feature" in
           'farbe')
              case "$question" in # color
                'green'|'violet') answer='f' ;; # left
                'blue'|'pink') answer='j' ;; # right
              esac ;;
           'linie')
              case "$question" in # Hatching Direction
                'SWNE'|'NESW') answer='f' ;; # left
                'SENW'|'NWSE') answer='j' ;; # right
              esac ;;
      esac ;;
    *) Fatal "Invalid rule '$rule_set'"
  esac

  # check in case there was a non-match
  [ "$answer" = 'OOPS' ] && Fatal "'$question' did not match in rule-set '$rule_set'."
  printf '%s' "$answer" && return 0
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
        [ -z "${2##*_*-*-*_*-*.*}" ] || Fatal "Invalid stimulus filename. '$2' is not in the correct format (e.g. 02_green-SENW-330_farbe-left.png)."
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

# grab values from file-name (example: 02_green-SENW-330_farbe-left.png)
INDEX=${FILE%%_*} && FILE="${FILE#${INDEX}_}" # stim index (in Presentation) e.g. 01
COLOR=${FILE%%-*} && FILE="${FILE#${COLOR}-}" # color of stim e.g. green
DIREC=${FILE%%-*} && FILE="${FILE#${DIREC}-}" # hatching dir (cardinal directions) e.g. SWNE
DEGRS=${FILE%%_*} && FILE="${FILE#${DEGRS}_}" # degrees of origin of hatching (redundant to above, but more specific)
FEATR=${FILE%%-*} && FILE="${FILE#${FEATR}-}" # relevant feature e.g. linie or farbe
CSIDE=${FILE%%.*} && FILE="${FILE#${CSIDE}.}" # cue side e.g. left or right

[ "$FEATR" = 'farbe' ] && Q=$COLOR || Q=$DIREC
REAL_ANS=$(LookupAnswer "$RULE_SET" "$FEATR" "$Q")
COLR_ANS=$(LookupAnswer "$RULE_SET" 'farbe' "$COLOR")
DIRC_ANS=$(LookupAnswer "$RULE_SET" 'linie' "$DIREC")
# now for all possible colors...
GRN_ANS=$(LookupAnswer "$RULE_SET" 'farbe' 'green')
BLU_ANS=$(LookupAnswer "$RULE_SET" 'farbe' 'blue')
PNK_ANS=$(LookupAnswer "$RULE_SET" 'farbe' 'pink')
VLT_ANS=$(LookupAnswer "$RULE_SET" 'farbe' 'violet')
# and directions...
SENW_ANS=$(LookupAnswer "$RULE_SET" 'linie' 'SENW')
SWNE_ANS=$(LookupAnswer "$RULE_SET" 'linie' 'SWNE')

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
printf '%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s \n' \
  "$INDEX" "$COLOR" "$DIREC" "$FEATR" "$CONGRUENCY" "$REAL_ANS" "$DEGRS" \
  "$COLR_ANS" "$DIRC_ANS" "$GRN_ANS" "$BLU_ANS" "$PNK_ANS" "$VLT_ANS" "$SENW_ANS" "$SWNE_ANS"
