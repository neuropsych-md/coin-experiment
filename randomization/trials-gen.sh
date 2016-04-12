#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# Alex Waite 2016

#
# VARS
#
readonly VERSION='1.0.0'
readonly SCRIPT_NAME=${0##*/}
BLOCKS=''
BLOCK_SIZE=''
FILES=''
JITTERS=''
RULE_SET=''
WORK_DIR=''

F_BLOCKS_RULES='blocks_rules.results'
F_JITTER='jitters.set'
F_TRIALS='trials.set'
F_TRIALS_SANE='trials.sane'


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

This is a simple script (turned ever-more-complex) to generate an appropriate
number of trials from a given set of stimulus files --- and its accompanying
options.

The output files are largely in conan-ready set-files, for its randomization
capabilities.

If the number of stimulus files are not evenly divisible into the block-size,
then they will be evenly distributed across all blocks. Note that while this
behavior has been tested in a few use-cases, it has not received widespread
testing.

A human readable set-file, not for conan consumption, is also generated --- to
aid verifying the results of this script.

Syntax:
$SCRIPT_NAME [-h] [-V] | -d directory -r rule_set -s block_size -b block_type [...] -j jitter [...] -f file [...]

OPTIONS:
  -h, --help        = print this help and exit
  -V, --version     = print the version number and exit

  -b, --block-types = block descriptors
  -d, --directory   = output directory
  -f, --files       = stimulus images to be used
  -j, --jitters     = jitter values to be used
  -r, --rule-set    = name of rule-set passed to 'stim-to-set-line.sh'
  -s, --block-size  = number of trials in a block

EXAMPLE:
  $SCRIPT_NAME -d candy/ -r gbw_pve -s 50 -b linie farbe -j 1000 1500 -f pngs/*.png

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

    '-b'|'--block-types')
        [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."

        while [ -n "${2##-*}" ]; do
          BLOCKS="${BLOCKS:+$BLOCKS }${2}"
          shift 1
        done
        ;;
    '-d'|'--directory')
        [ -n "${2##-*}" ] || Fatal "'$1' requires an argument."
        [ -e "$2" ] && Fatal "'$2' already exists! (please delete it, or choose a different dir name)"
        WORK_DIR="$(readlink -f $2)"
        shift 1
        ;;
    '-f'|'--files')
        [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."

        while [ -n "${2##-*}" ]; do
          FILES="${FILES:+$FILES }${2}"
          shift 1
        done
        ;;
    '-j'|'--jitters')
        [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."

        while [ -n "${2##-*}" ]; do
          JITTERS="${JITTERS:+$JITTERS }${2}"
          shift 1
        done
        ;;
    '-r'|'--rule-set')
        [ -n "${2##-*}" ] || Fatal "'$1' requires an argument."
        RULE_SET=$2
        shift 1
        ;;
    '-s'|'--block-size')
        [ -n "${2##-*}" ] || Fatal "'$1' requires an argument."
        IsInt "$2" || Fatal "'$2' must be an integer."
        BLOCK_SIZE=$2
        shift 1
        ;;
    *) Fatal "'$1' is not a valid '$SCRIPT_NAME' option.";;
  esac
  [ -n "$1" ] && shift 1 # only shift if there's anything left to shift
done

# Check if any required flags are missing
[ -z "$BLOCKS" ] && Fatal "-b/--block-types is required."
[ -z "$BLOCK_SIZE" ] && Fatal "-s/--block-size is required."
[ -z "$FILES" ] && Fatal "-f/--files is required"
[ -z "$JITTERS" ] && Fatal "-j/--jitters is required"
[ -z "$RULE_SET" ] && Fatal "-r/--rule-set is required"
[ -z "$WORK_DIR" ] && Fatal "-d/--directory is required"


#
# Main
#
# create work-dir
mkdir -p "$WORK_DIR" || Fatal "Couldn't create '$WORK_DIR'"

NUM_BLOCKS=`printf '%s' "$BLOCKS" | wc -w`
NUM_TRIALS=$(( $BLOCK_SIZE * $NUM_BLOCKS ))
I=0
while [ $I -lt $NUM_TRIALS ]; do
  for FILE in $FILES; do
    [ $I -lt $NUM_TRIALS ] || break 2 # don't overrun the top-level while-loop

    ### trial set-line
    { ./stim-to-set-line.sh -r "$RULE_SET" -f "$FILE" >> "${WORK_DIR}/${F_TRIALS_SANE}" ; } \
      || Fatal "Error with 'stim-to-set-line.sh'. Do '$RULE_SET' and '$FILE' look sane?"

    ### jitter set-line
    printf '%s\n' "${JITTERS%% *}" >> "${WORK_DIR}/${F_JITTER}"
    # cycle to next jitter value
    JITTERS="${JITTERS#* } ${JITTERS%% *}"

    ### block-type set-line
    # move on to the next block at $BLOCK_SIZE intervals
    [ $(( $I % $BLOCK_SIZE )) -eq 0 ] && [ $I -ne 0 ] && BLOCKS="${BLOCKS#* }"
    printf '%04d %s %s\n' "$I" "${BLOCKS%% *}" "$RULE_SET" >> "${WORK_DIR}/${F_BLOCKS_RULES}"

    I=$(( $I + 1 ))
  done
done

# convert trial-file from "sane format" to "conan friendly"
sed -f ./sane2conan.sed "${WORK_DIR}/${F_TRIALS_SANE}" > "${WORK_DIR}/${F_TRIALS}"

#
# Appendix of helpful output
#

NUM_FILES=`printf '%s' "$FILES" | wc -w`
BOLD_TEXT='\033[1;32m%s\033[0m'
printf '\nSuccess\n'
printf "A total of ${BOLD_TEXT} trials were generated across ${BOLD_TEXT} blocks.\n\n" "$I" "$NUM_BLOCKS"

printf "The following $BOLD_TEXT stimulus files were evaluated against the $BOLD_TEXT rule-set:\n" "$NUM_FILES" "$RULE_SET"
for F in $FILES; do
  printf "  ${BOLD_TEXT}\n" "$F"
done

printf "\nThe following files have been placed in ${BOLD_TEXT}:\n" "$WORK_DIR"
printf "  ${BOLD_TEXT} -- human-readable file containing trial attributes\n" "$F_TRIALS_SANE"
printf "  ${BOLD_TEXT} -- conan-ready set-file containing trial attributes\n" "$F_TRIALS"
printf "  ${BOLD_TEXT} -- conan-ready set-file containing jitter times\n" "$F_JITTER"
printf "  ${BOLD_TEXT} -- file in conan's 'results' output format containing the block-type and rule-set\n" "$F_BLOCKS_RULES"

