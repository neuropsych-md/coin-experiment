#!/bin/bash
# This file is licensed under the BSD-3-Clause license.
# Alex Waite 2016

# Require Bash v4 because this script uses associative arrays
[ -z "$BASH_VERSINFO"  ] || [ "${BASH_VERSINFO[0]}" -lt 4 ] && printf 'Bash version >= 4 required. \n' && exit 1
set -e

#
# VARS
#
readonly VERSION='2.1.0'
readonly SCRIPT_NAME=${0##*/}
RULE_SET=''
PNG_FILES=''
VERBOSE='false'
MODE=''
NUM_FARBE=''
NUM_LINIE=''
NUM_CON=''
NUM_INCON=''

# master associative array of all PNGs and their attributes
declare -A PNGS

# lists of png IDs for each category
FARBE_CON=''
FARBE_INCON=''
LINIE_CON=''
LINIE_INCON=''

# Final events list consisting of the PNG ID for each event
EVENTS=''

#
# Functions
#
Fatal() {
  printf '%s\n' "$*" >&2
  exit 1
}

# return 0 if argument is an integer; 1 if not
IsInt() {
  [ -z "${1##*[!0-9]*}" ] && return 1 || return 0
}

Help() {
  cat << EOF
$SCRIPT_NAME v${VERSION}

Given a rule-set, feature/congruency ratios, and stimulus PNGs, this script will
filter for relevent PNGs, extract and generate all neccesary information, and
provide output ready for use as a conan set-file.

If the number of stimulus files is not evenly divisible into the number of
events, then a randomized, best-effort is made to distribute across them.

Syntax:
$SCRIPT_NAME [-h] [-V] | [-v] -r rule_set -ci|-fl int int -p file [...]

OPTIONS:
  -h,  --help        = print this help and exit
  -V,  --version     = print the version number and exit

  -ci, --con-incon   = number of congruent and incongruent events. Cannot be used
                       with --farbe-linie --- for which it'll use a 50/50 ratio.
  -fl, --farbe-linie = number of farbe and linie events. Cannot be used with
                       --con-incon --- for which it will use a 50/50 ratio.

  -p,  --pngs        = stimulus images to be used
  -r,  --rule-set    = rule-set to evaluate PNGs' characteristics against
  -v,  --verbose     = print to stderr about accepted vs rejected PNGs

EXAMPLE:
  $SCRIPT_NAME --rule-set gbNW_pvNE --con-incon 75 25 --pngs pngs/*.png

EOF
}

# Accepts the cue side and the answer
# Returns whether the cue and answer are congruent
IsCongruent() {
  local cue=$1
  local answer=$2

  [ "$cue" = 'left' ]  && [ "$answer" = 'f' ] && return 0 # congruent
  [ "$cue" = 'right' ] && [ "$answer" = 'j' ] && return 0 # congruent

  return 1 # incongruent
}


# What is the correct answer for a given rule-set, feature, and question
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

# Accept input, shuffle, and echo it
Shuffle() {
  local shuf_stuff
  shuf_stuff=$(printf '%s\n' $@ | shuf | tr '\n' ' ')
  printf '%s' "${shuf_stuff% }"
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

    '-ci'|'--con-incon')
        IsInt "$2" && IsInt "$3" || Fatal "'$1' requires two integers."
        MODE='con incon'
        NUM_CON=$2
        NUM_INCON=$3
        shift 2
        ;;
    '-fl'|'--farbe-linie')
        IsInt "$2" && IsInt "$3" || Fatal "'$1' requires two integers."
        MODE='farbe linie'
        NUM_FARBE=$2
        NUM_LINIE=$3
        shift 2
        ;;
    '-p'|'--pngs')
        [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."

        while [ -n "${2##-*}" ]; do
          PNG_FILES="${PNG_FILES:+$PNG_FILES }${2##*/}"
          shift 1
        done
        ;;
    '-r'|'--rule-set')
        [ -n "${2##-*}" ] || Fatal "'$1' requires an argument."
        RULE_SET=$2
        shift 1
        ;;
    '-v'|'--verbose')
        VERBOSE='true'
        ;;
    *) Fatal "'$1' is not a valid '$SCRIPT_NAME' option.";;
  esac
  [ -n "$1" ] && shift 1 # only shift if there's anything left to shift
done

# Check if any required arguments are missing
[ -z "$PNG_FILES" ]  && Fatal "-p/--pngs is required"
[ -z "$RULE_SET" ]   && Fatal "-r/--rule-set is required"
[ -z "$NUM_FARBE" ] && [ -z "$NUM_CON" ] && Fatal "either -ci or -fl are required"
[ -n "$NUM_FARBE" ] && [ -n "$NUM_CON" ] && Fatal "you can only use -ci XOR -fl --- not both"


#
# Main
#

# Loop over all supplied pngs, extract and generate just about every piece of
# info possible, assign all info into a master array that is creatively named
# "PNGS", determine if we're even interested in the png file from its generated
# info, and finally categorize pngs-of-interest into the appropriate array.
for PNG in $PNG_FILES; do
    FILE=$PNG

    # extract values from file-name (example: 02_green-SENW-330_farbe-left.png)
    ID=${FILE%%_*} && FILE=${FILE#${ID}_} # stim index (in Presentation) e.g. 01
    PNGS[$ID,file]=$PNG
    PNGS[$ID,farbe]=${FILE%%-*}   && FILE=${FILE#*-} # color of stim e.g. green
    PNGS[$ID,linie]=${FILE%%-*}   && FILE=${FILE#*-} # hatching dir (cardinal directions) e.g. SWNE
    PNGS[$ID,degrees]=${FILE%%_*} && FILE=${FILE#*_} # degrees of origin of hatching (redundant to above, but more specific)
    PNGS[$ID,feature]=${FILE%%-*} && FILE=${FILE#*-} # relevant feature e.g. farbe or linie
    PNGS[$ID,cue]=${FILE%%.*}     && FILE=${FILE#*.} # cue side e.g. left or right

    # get answers for both features
    PNGS[$ID,ans_farbe]=$(LookupAnswer "$RULE_SET" 'farbe' "${PNGS[$ID,farbe]}")
    PNGS[$ID,ans_linie]=$(LookupAnswer "$RULE_SET" 'linie' "${PNGS[$ID,linie]}")

    # answer for both relevant and irrelevant features
    if [ "${PNGS[$ID,feature]}" = 'farbe' ]; then
      PNGS[$ID,ans_rel]=${PNGS[$ID,ans_farbe]}
      PNGS[$ID,ans_irrel]=${PNGS[$ID,ans_linie]}
    else
      PNGS[$ID,ans_rel]=${PNGS[$ID,ans_linie]}
      PNGS[$ID,ans_irrel]=${PNGS[$ID,ans_farbe]}
    fi

    # now for all possible colors...
    PNGS[$ID,ans_green]=$(LookupAnswer  "$RULE_SET" 'farbe' 'green')
    PNGS[$ID,ans_blue]=$(LookupAnswer   "$RULE_SET" 'farbe' 'blue')
    PNGS[$ID,ans_pink]=$(LookupAnswer   "$RULE_SET" 'farbe' 'pink')
    PNGS[$ID,ans_violet]=$(LookupAnswer "$RULE_SET" 'farbe' 'violet')
    # and directions...
    PNGS[$ID,ans_SENW]=$(LookupAnswer "$RULE_SET" 'linie' 'SENW')
    PNGS[$ID,ans_SWNE]=$(LookupAnswer "$RULE_SET" 'linie' 'SWNE')

    # congruency of answer vs cue for both the relevant and irrelevant features
    IsCongruent "${PNGS[$ID,cue]}" "${PNGS[$ID,ans_rel]}"   && PNGS[$ID,con_rel]='c'   || PNGS[$ID,con_rel]='i'
    IsCongruent "${PNGS[$ID,cue]}" "${PNGS[$ID,ans_irrel]}" && PNGS[$ID,con_irrel]='c' || PNGS[$ID,con_irrel]='i'

    # PNGs are only used if the irrelevant feature's answer is congruent with the cue.
    # This means, for any given rule-set, only half of the PNGs are used.
    if [ "${PNGS[$ID,con_irrel]}" = 'c' ]; then
      # categorize the PNG; it helps us easily match the user specified ratios
      # while not falling into really gnarly corner-cases
      case "${PNGS[$ID,feature]}-${PNGS[$ID,con_rel]}" in
        'farbe-c') FARBE_CON="${FARBE_CON:+$FARBE_CON }${ID}" ;;
        'farbe-i') FARBE_INCON="${FARBE_INCON:+$FARBE_INCON }${ID}" ;;
        'linie-c') LINIE_CON="${LINIE_CON:+$LINIE_CON }${ID}" ;;
        'linie-i') LINIE_INCON="${LINIE_INCON:+$LINIE_INCON }${ID}" ;;
      esac
    else # we're not interested in this PNG
      continue
    fi
done

# shuffle/randomize the PNG category lists. This solves a /boatload/ of
# statistical problems when invoking this script multiple times to eventually
# concatenate into a larger whole
FARBE_CON=$(Shuffle "$FARBE_CON") ; FARBE_INCON=$(Shuffle "$FARBE_INCON")
LINIE_CON=$(Shuffle "$LINIE_CON") ; LINIE_INCON=$(Shuffle "$LINIE_INCON")

# build a list of the PNG IDs according to the ratios provided by the user
#   the ratio of the non-mode is 50/50 (so --farbe-linie 75 25 results in
#   farbe=75, linie=25, congruent=50, incongruent=50)
CLOCK='tick'
for M in $MODE ; do # used the space in the mode-name for splitting
  case $M in
    'farbe') ARR1=$FARBE_CON   ; ARR2=$FARBE_INCON ; NUM=$NUM_FARBE ;;
    'linie') ARR1=$LINIE_CON   ; ARR2=$LINIE_INCON ; NUM=$NUM_LINIE ;;
    'con')   ARR1=$LINIE_CON   ; ARR2=$FARBE_CON   ; NUM=$NUM_CON   ;;
    'incon') ARR1=$LINIE_INCON ; ARR2=$FARBE_INCON ; NUM=$NUM_INCON ;;
  esac

  I=0
  while [ $I -lt $NUM ]; do
    if [ "$CLOCK" = 'tick' ]; then
      ID=${ARR1%% *} # get first ID
      ARR1="${ARR1#${ID} } ${ID}" # rotate first ID to end
      CLOCK='tock'
    else
      ID=${ARR2%% *} # get first ID
      ARR2="${ARR2#${ID} } ${ID}" # rotate first ID to end
      CLOCK='tick'
    fi

    EVENTS="${EVENTS:+$EVENTS }${ID}"

    I=$(( $I + 1 ))
  done
done

# generate number of events for the unspecified mode --- for printing purposes
if [ "$MODE" = 'farbe linie' ]; then
  NUM_INCON=$(( ( $NUM_FARBE + $NUM_LINIE ) / 2 ))
else # con incon
  NUM_FARBE=$(( ( $NUM_CON + $NUM_INCON ) / 2 ))
fi


# now, finally, print out the events
for ID in $EVENTS ; do
    # print out the event's set-line
    printf '%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s \n' \
      "$ID" \
      "${PNGS[$ID,farbe]:0:1}" \
      "${PNGS[$ID,linie]}" \
      "${PNGS[$ID,feature]}" \
      "${PNGS[$ID,con_rel]}" \
      "${PNGS[$ID,ans_rel]}" \
      "${PNGS[$ID,degrees]}" \
      "$NUM_INCON" \
      "$NUM_FARBE" \
      "${PNGS[$ID,ans_farbe]}" \
      "${PNGS[$ID,ans_linie]}" \
      "${PNGS[$ID,ans_green]}" \
      "${PNGS[$ID,ans_blue]}" \
      "${PNGS[$ID,ans_pink]}" \
      "${PNGS[$ID,ans_violet]}" \
      "${PNGS[$ID,ans_SENW]}" \
      "${PNGS[$ID,ans_SWNE]}"
done


#
# Appendix of helpful output
#

# print stats to stderr
if [ "$VERBOSE" = 'true' ]; then
  NUM_PNGS=`printf '%s' "$PNG_FILES" | wc -w`
  NUM_RLVNT_PNGS=`printf '%s' "$FARBE_CON $FARBE_INCON $LINIE_CON $LINIE_INCON" | wc -w`
  BOLD_TEXT='\033[1;32m%s\033[0m'

  printf '\n'
  printf "$BOLD_TEXT out of $BOLD_TEXT PNGs were accepted for the $BOLD_TEXT rule-set:\n" \
         "$NUM_RLVNT_PNGS" "$NUM_PNGS" "$RULE_SET" >&2

  for FILE in $PNG_FILES; do
    ID=${FILE%%_*}
    # I'm tired; so I'm just going to brute-force this. Don't judge me
    if [ -z "${FARBE_CON##*${ID}*}" -o -z "${FARBE_INCON##*${ID}*}" -o \
         -z "${LINIE_CON##*${ID}*}" -o -z "${LINIE_INCON##*${ID}*}" ]; then
      printf "✓  ${BOLD_TEXT}\n" "$FILE" >&2
    else
      printf "✗  %s\n" "$FILE" >&2
    fi
  done
fi
