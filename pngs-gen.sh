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
readonly VERSION='1.0.0'
readonly SCRIPT_NAME=${0##*/}

FILE=''

#
# Functions
#
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
  $SCRIPT_NAME --filename MiSIT_layers.svgtune

EOF
}

[ $# -ne 1 ] && printf "An .svgtune file is required as an argument.\n" && exit 1
[ ! -f "$1" ] && printf "'$1' does not exist.\n" && exit 1

TUNE_FILE=$1
TUNE_DIR="${TUNE_FILE%.svgtune}_tuned"
PNG_DIR="${TUNE_DIR%_tuned}_png"

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
