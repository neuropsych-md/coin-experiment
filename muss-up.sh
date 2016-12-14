#!/bin/bash
# This file is licensed under the BSD-3-Clause license.
# Laura Waite 2016

# Require Bash v4 because this script uses associative arrays
#[ -z "$BASH_VERSINFO" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ] && printf 'Bash version >= 4 required. \n' && exit 1
#set -e

#
# VARS
#
#readonly VERSION='1.0.0'
#readonly SCRIPT_NAME=${0##*/}
RESULTS_FILE=''

# master index array of conan results file content
declare -a ORIG

#
# Functions
#
#Fatal() {
#  printf '%s\n' "$*" >&2
#  exit 1
#}

#Help() {
#  cat << EOF
#$SCRIPT_NAME v${VERSION}

#Given a conan results file, this script will "muss up" the relevant feature
#pattern created by conan in 10 different random locations across the 100 lines
#while maintain the contraints of the randomization set by conan.

#Syntax:
#$SCRIPT_NAME [-h] [-V]

#OPTIONS:
#  -h,  --help       = print this help and exit
#  -V,  --version    = print the version number and exit

#  -f,  --file   = file to be used

#EXAMPLE:
#  $SCRIPT_NAME --filename

#EOF
#}

#
# Parse Arguments
#
[ -n "$1" ] || { Help; exit 1; }

while [ -n "$1" ]; do
  case "$1" in
#    '-h'|'--help') Help; exit 0;;
#    '-V'|'--version') printf '%s v%s\n' "$SCRIPT_NAME" "$VERSION"; exit 0;;
#
    '-f'|'--file')
      [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."
      RESULTS_FILE=$2
      shift 1
      ;;
    *) Fatal "'$1' is not a valid '$SCRIPT_NAME' option.";;
  esac
  [ -n "$1" ] && shift 1 # only shift if there's anything left to shift
done

#
# Main
#

# Read in file
IFS=$'\n' read -d '' -r -a ORIG < $RESULTS_FILE

declare -a LINE1_ARR
declare -a LINE2_ARR
declare -a SWAPPED  # track which lines are swapped
COUNTER=0

while [ $COUNTER -lt 5 ]; do
  LINE1_INDEX=$(($RANDOM % 100))
  while [ ${SWAPPED[$LINE1_INDEX]} ] || [ $LINE1_INDEX -lt 10 ]; do
    LINE1_INDEX=$(($RANDOM % 100))
  done
  LINE1=${ORIG[$LINE1_INDEX]}

  IFS=' ' read -a LINE1_ARR <<< $LINE1

  LINE2_INDEX=$(($RANDOM % 100))
  while [ ${SWAPPED[$LINE2_INDEX]} ] || [ $LINE2_INDEX -lt 10 ]; do
    LINE2_INDEX=$(($RANDOM % 100))
  done
  LINE2=${ORIG[$LINE2_INDEX]}

  IFS=' ' read -a LINE2_ARR <<< $LINE2

  # make sure the degrees of the lines before and after LINE1 are different
  [ -n "${ORIG[$(($LINE2_INDEX - 1))]##* * * * * * * ${LINE1_ARR[7]} * * * * * * * * * *}" ] || continue
  [ -n "${ORIG[$(($LINE2_INDEX + 1))]##* * * * * * * ${LINE1_ARR[7]} * * * * * * * * * *}" ] || continue
  # make sure the degrees of the lines before and after LINE2 are different
  [ -n "${ORIG[$(($LINE1_INDEX - 1))]##* * * * * * * ${LINE2_ARR[7]} * * * * * * * * * *}" ] || continue
  [ -n "${ORIG[$(($LINE1_INDEX + 1))]##* * * * * * * ${LINE2_ARR[7]} * * * * * * * * * *}" ] || continue

  # make sure the answers are the same
  [ "${LINE1_ARR[6]}" == "${LINE2_ARR[6]}" ] || continue

  # make sure the rel. feat. are different
  [ "${LINE1_ARR[4]}" != "${LINE2_ARR[4]}" ] || continue

  # make sure the image index of the lines before and after LINE1 are different
  [ -n "${ORIG[$(($LINE2_INDEX - 1))]##* ${LINE1_ARR[1]} * * * * * * * * * * * * * * * *}" ] || continue
  [ -n "${ORIG[$(($LINE2_INDEX + 1))]##* ${LINE1_ARR[1]} * * * * * * * * * * * * * * * *}" ] || continue
  # make sure the image index of the lines before and after LINE2 are different
  [ -n "${ORIG[$(($LINE1_INDEX - 1))]##* ${LINE2_ARR[1]} * * * * * * * * * * * * * * * *}" ] || continue
  [ -n "${ORIG[$(($LINE1_INDEX + 1))]##* ${LINE2_ARR[1]} * * * * * * * * * * * * * * * *}" ] || continue

  # swap lines
  ORIG[$LINE1_INDEX]="${LINE1_ARR[0]} ${LINE2#* }"
  ORIG[$LINE2_INDEX]="${LINE2_ARR[0]} ${LINE1#* }"

  # push both line indexes to swap array
  SWAPPED[$LINE1_INDEX]=true
  SWAPPED[$LINE2_INDEX]=true
  COUNTER=$(($COUNTER + 1))
done

printf '%s\n' "${ORIG[@]}"

