#!/bin/bash
# This file is licensed under the BSD-3-Clause license.
# Laura Waite 2016

#
# MiSIT project
#   generate conan set files, conan results files, and presentation input files
#
# TODO: invert the above descirption so that it's more correct from the user's
# perspective

#
# Vars
#
readonly VERSION='1.0.0'
readonly SCRIPT_NAME=${0##*/}
RESULTS_DIR=''
PNGS=''

# a horrible name for output files, I know, but they've long been referred to as
# "presentation input files" and they are so thusly dubbed.
declare -A infiles
infiles[gbNW_pvNE_1]='neutralA farbeA incongruentA linieA congruentA incongruentB neutralB farbeB linieB congruentB'
infiles[pvNW_gbNE_1]='neutralA farbeA incongruentA linieA congruentA incongruentB neutralB farbeB linieB congruentB'
infiles[bpSW_gvSE_1]='neutralA farbeA incongruentA linieA congruentA incongruentB neutralB farbeB linieB congruentB'
infiles[gvSW_bpSE_1]='neutralA farbeA incongruentA linieA congruentA incongruentB neutralB farbeB linieB congruentB'

infiles[gbNW_pvNE_2]='neutralA congruentA linieA farbeA incongruentA linieB congruentB neutralB farbeB incongruentB'
infiles[pvNW_gbNE_2]='neutralA congruentA linieA farbeA incongruentA linieB congruentB neutralB farbeB incongruentB'
infiles[bpSW_gvSE_2]='neutralA congruentA linieA farbeA incongruentA linieB congruentB neutralB farbeB incongruentB'
infiles[gvSW_bpSE_2]='neutralA congruentA linieA farbeA incongruentA linieB congruentB neutralB farbeB incongruentB'

infiles[gbNW_pvNE_3]='neutralA linieA incongruentA farbeA congruentA neutralB incongruentB farbeB congruentB linieB'
infiles[pvNW_gbNE_3]='neutralA linieA incongruentA farbeA congruentA neutralB incongruentB farbeB congruentB linieB'
infiles[bpSW_gvSE_3]='neutralA linieA incongruentA farbeA congruentA neutralB incongruentB farbeB congruentB linieB'
infiles[gvSW_bpSE_3]='neutralA linieA incongruentA farbeA congruentA neutralB incongruentB farbeB congruentB linieB'

infiles[gbNW_pvNE_4]='neutralA incongruentA congruentA linieA farbeA congruentB farbeB incongruentB linieB neutralB'
infiles[pvNW_gbNE_4]='neutralA incongruentA congruentA linieA farbeA congruentB farbeB incongruentB linieB neutralB'
infiles[bpSW_gvSE_4]='neutralA incongruentA congruentA linieA farbeA congruentB farbeB incongruentB linieB neutralB'
infiles[gvSW_bpSE_4]='neutralA incongruentA congruentA linieA farbeA congruentB farbeB incongruentB linieB neutralB'


#
# Functions
#
Fatal() {
  printf '%s\n' "$*" >&2
  exit 1
}

Help() {
# TODO: also fix help's description so it's intuitive for the user
  cat << EOF
$SCRIPT_NAME v${VERSION}
generate conan set files, conan results files, and presentation input files

Syntax:
$SCRIPT_NAME [-h] [-V] | -d directory -p pngs

OPTIONS:
  -h, --help      = print this help and exit
  -V, --version   = print the version number and exit

  -d, --directory = results directory
  -p, --pngs      = pngs
EXAMPLE:
  $SCRIPT_NAME --directory BH_input --pngs MiSIT_stims_png/*.png

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

    '-d'|'--directory')
       [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."
       RESULTS_DIR=$2
       [ -e "${RESULTS_DIR}" ] && Fatal "${RESULTS_DIR} already exists! (please delete it)"
       mkdir -p "${RESULTS_DIR}"
       shift 1
       ;;
    '-p'|'--pngs')
      [ -n "${2##-*}" ] || Fatal "'$1' requires at least one argument."

      while [ -n "${2##-*}" ]; do
        PNGS="${PNGS:+$PNGS }${2##*/}"
        shift 1
      done
      ;;
    *) Fatal "'$1' is not a valid '$SCRIPT_NAME' option.";;
  esac
  [ -n "$1" ] && shift 1 # only shift if there's anything left to shift
done

# Check if any required arguments are missing
[ -z "$RESULTS_DIR" ] && Fatal "-d/--directory is required"
[ -z "$PNGS" ] && "-p/--pngs is required"

TMP="${RESULTS_DIR}/tmp/"
mkdir -p "${TMP}"

#
# Main
#

# generate jitter set file
./jitter-gen.sh --total 100 --jitters 800 1000 1200 1400 1600 1800 | shuf > "${TMP}/jitter.set"

# loop over all ruleset and block combinations
for ruleset in gbNW_pvNE pvNW_gbNE bpSW_gvSE gvSW_bpSE ; do
    for block in neutralA neutralB farbeA farbeB linieA linieB incongruentA incongruentB congruentA congruentB; do
        printf "Automagicating: $ruleset $block\n"
        case "$block" in
             'neutralA'|'neutralB')         mode='--farbe-linie 50 50' ;;
             'farbeA'|'farbeB')             mode='--farbe-linie 75 25' ;;
             'linieA'|'linieB')             mode='--farbe-linie 25 75' ;;
             'incongruentA'|'incongruentB') mode='--con-incon 25 75'   ;;
             'congruentA'|'congruentB')     mode='--con-incon 75 25'   ;;
        esac
        # generate conan set files
        ./events-gen.sh --rule-set "$ruleset" $mode --pngs "${PNGS}" > "${TMP}/${ruleset}_${block}.set"

        case "$block" in
             'neutralA'|'neutralB')         cfg_file='neutral.cfg'     ;;
             'farbeA'|'farbeB')             cfg_file='farbe.cfg'       ;;
             'linieA'|'linieB')             cfg_file='linie.cfg'       ;;
             'incongruentA'|'incongruentB') cfg_file='incongruent.cfg' ;;
             'congruentA'|'congruentB')     cfg_file='congruent.cfg'   ;;
        esac
        # generate result files for events and jitters
        # TODO: this should probably be written as conan blah || Fatal WTF
        conan "./cfgs/${cfg_file}" "${TMP}/${ruleset}_${block}.set" 1> "${TMP}/${ruleset}_${block}.results" 2> /dev/null
        conan ./cfgs/jitter.cfg "${TMP}/jitter.set" 1> "${TMP}/${ruleset}_${block}_jitter.results" 2> /dev/null
    done
done

# TODO: ruleset vs RULE_SET block vs BLOCK? danger

RULE_SET=''
# build and output the final presentation "input" files
printf "Assembling the following files:\n"
for KEY in "${!infiles[@]}"; do
  RULE_SET=${KEY%_*}

  BLOCK_NUM=1
  printf "${KEY}\n"
  for BLOCK in ${infiles[${KEY}]}; do
    # convert into a presentation-ready format and join with jitter info and append block num
    join "${TMP}/${RULE_SET}_${BLOCK}.results" "${TMP}/${RULE_SET}_${BLOCK}_jitter.results" | \
      sed -f ./conan2input.sed | sed -e "1,\$ s/\$/ ${BLOCK_NUM}/" \
      >> "${RESULTS_DIR}/${KEY}.txt"

    BLOCK_NUM=$(( $BLOCK_NUM + 1 ))
  done
done
