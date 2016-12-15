#!/bin/sh
# This file is licensed under the BSD-3-Clause license.
# Laura Waite 2016

#
# COIN project
#   generate pngs for a given svgtune file
#

#
# VARS
#
readonly VERSION='2.0.0'
readonly SCRIPT_NAME=${0##*/}
TUNE_FILE=''

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
generate pngs for a given svgtune file

Syntax:
$SCRIPT_NAME [-h] [-V] | -f filename

OPTIONS:
  -h, --help       = print this help and exit
  -V, --version    = print the version number and exit

  -f, --filename   = svgtune filename
EXAMPLE:
  $SCRIPT_NAME --filename COIN_layers.svgtune

EOF
}

# TODO: figure out why parse arguments causes script to fail
#
# Parse Arguments
#

# help out if there are no arguments
[ -n "$1" ] || { Help; exit 1; }

#while [ -n "$1" ]; do
#  case "$1" in
#    '-h'|'--help') Help; exit 0;;
#    '-V'|'--version') printf '%s v%s\n' "$SCRIPT_NAME" "$VERSION"; exit 0;;
#
#    -*) Fatal "'$1' is not a valid '$SCRIPT_NAME' option.";;
#    *) [ ! -f "$1" ] && Fatal "'$1' does not exist."
#       TUNE_FILE=$1
#       ;;
#  esac
#done

TUNE_FILE=$1
TUNE_DIR="${TUNE_FILE%.svgtune}_tuned" # match what svgtune does internally
PNG_DIR="${TUNE_DIR%_tuned}_png"

# TODO: check that both inkscape and svgtune are in the path

# TODO: check that neither TUNE_DIR nor PNG_DIR exist, otherwise bail (with message

# generate SVGs
svgtune "$TUNE_FILE"

# generate PNGs
mkdir -p "$PNG_DIR"
for SVG_IN in ${TUNE_DIR}/*.svg ; do
    PNG_OUT=${SVG_IN##*/} # remove dir, if any
    PNG_OUT="${PNG_OUT%.svg}.png" # swap .svg extension for .png

    inkscape -z -f $SVG_IN -e "${PNG_DIR}/${PNG_OUT}"
done

mv "${TUNE_DIR}" "${PNG_DIR}/${TUNE_DIR}"
