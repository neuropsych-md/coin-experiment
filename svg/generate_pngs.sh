#!/bin/sh
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
