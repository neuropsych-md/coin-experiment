#!/bin/bash
# This file is licensed under the BSD-3-Clause license.
# Laura Waite 2016

#
# COIN project
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
infiles[gpNW_boNE_1]='orientA farbeA farbeB orientB farbeC orientC'
infiles[boNW_gpNE_1]='orientA farbeA farbeB orientB farbeC orientC'

infiles[gpNW_boNE_2]='farbeA orientA orientB farbeB orientC farbeC'
infiles[boNW_gpNE_2]='farbeA orientA orientB farbeB orientC farbeC'

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
for ruleset in gpNW_boNE boNW_gpNE ; do
    for block in farbeA farbeB farbeC orientA orientB orientC; do
        printf "Automagicating: $ruleset $block\n"
        case "$block" in
#             'neutralA'|'neutralB'|'neutralC'|'neutralD') mode='--farbe-orient 50 50' ;;
             'farbeA'|'farbeB'|'farbeC')                  mode='--farbe-orient 75 25' ;;
             'orientA'|'orientB'|'orientC')               mode='--farbe-orient 25 75' ;;
        esac
        # generate conan set files
        ./events-gen.sh --rule-set "$ruleset" $mode --pngs "${PNGS}" > "${TMP}/${ruleset}_${block}.set"
        echo "post event"
        case "$block" in
#             'neutralA')                        cfg_file='neutralA.cfg' ;;
#             'neutralB')                        cfg_file='neutralB.cfg' ;;
#             'neutralC')                        cfg_file='neutralC.cfg' ;;
#             'neutralD')                        cfg_file='neutralD.cfg' ;;
             'farbeA'|'farbeB'|'farbeC')        cfg_file='farbe.cfg'   ;;
             'orientA'|'orientB'|'orientC')     cfg_file='orient.cfg'  ;;
        esac
        # generate result files for events and jitters
        # TODO: this should probably be written as conan blah || Fatal WTF
        conan "./cfgs/${cfg_file}" "${TMP}/${ruleset}_${block}.set" 1> "${TMP}/${ruleset}_${block}.results" 2> /dev/null
        conan ./cfgs/jitter.cfg "${TMP}/jitter.set" 1> "${TMP}/${ruleset}_${block}_jitter.results" 2> /dev/null
        echo "post conan"

        case "$block" in
#             'neutralB')   ./muss-up.sh --file "${TMP}/${ruleset}_${block}.results" > "${TMP}/${ruleset}_${block}.final" ;;
#             'neutralC')   ./muss-up.sh --file "${TMP}/${ruleset}_${block}.results" > "${TMP}/${ruleset}_${block}.final" ;;
#             'neutralD')   ./muss-up.sh --file "${TMP}/${ruleset}_${block}.results" > "${TMP}/${ruleset}_${block}.final" ;;
#             'neutralA')                    cp "${TMP}/${ruleset}_${block}.results" "${TMP}/${ruleset}_${block}.final" ;;
             'farbeA'|'farbeB'|'farbeC')    cp "${TMP}/${ruleset}_${block}.results" "${TMP}/${ruleset}_${block}.final" ;;
             'orientA'|'orientB'|'orientC') cp "${TMP}/${ruleset}_${block}.results" "${TMP}/${ruleset}_${block}.final" ;;
        esac
        echo "post muss-up"
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
    join "${TMP}/${RULE_SET}_${BLOCK}.final" "${TMP}/${RULE_SET}_${BLOCK}_jitter.results" | \
      sed -f ./conan2input.sed | sed -e "1,\$ s/\$/ ${BLOCK_NUM}/" \
      >> "${RESULTS_DIR}/${KEY}.txt"

    BLOCK_NUM=$(( $BLOCK_NUM + 1 ))
  done
done
