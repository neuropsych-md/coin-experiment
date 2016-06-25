#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# Alex Waite 2016

#
# VARS
#
readonly VERSION='1.0.0'
readonly SCRIPT_NAME=${0##*/}
JITTERS=''
TOTAL=''

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

Given a set of jitters and a total number, provide output ready for use as a
conan set-file.

Basically a fancy for-loop. :-)

Syntax:
$SCRIPT_NAME [-h] [-V] | -j jitter [...] -t total

OPTIONS:
  -h, --help        = print this help and exit
  -V, --version     = print the version number and exit

  -j, --jitters     = jitter values to be used
  -t, --total       = total number of jitters to generate

EXAMPLE:
  $SCRIPT_NAME --total 100 --jitters 800 1000 1200 1400 1600 1800

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

    '-j'|'--jitters')
        [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."

        while [ -n "${2##-*}" ]; do
          IsInt "$2" || Fatal "'$2' must be an integer."
          JITTERS="${JITTERS:+$JITTERS }${2}"
          shift 1
        done
        ;;
    '-t'|'--total')
        [ -n "${2##-*}" ] || Fatal "'$1' requires an argument."
        IsInt "$2" || Fatal "'$2' must be an integer."
        TOTAL=$2
        shift 1
        ;;
    *) Fatal "'$1' is not a valid '$SCRIPT_NAME' option.";;
  esac
  [ -n "$1" ] && shift 1 # only shift if there's anything left to shift
done

# Check if any required flags are missing
[ -z "$JITTERS" ] && Fatal "-j/--jitters is required"
[ -z "$TOTAL" ]   && Fatal "-t/--total is required."


#
# Main
#

I=0
while [ $I -lt $TOTAL ]; do
    printf '%s\n' "${JITTERS%% *}" # print dat
    JITTERS="${JITTERS#* } ${JITTERS%% *}"  # cycle to next jitter value

    I=$(( $I + 1 ))
done
