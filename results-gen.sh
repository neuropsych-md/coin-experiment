#!/bin/bash
# This file is licensed under the BSD-3-Clause license.
# Laura Waite 2016

# horrible name for output files, I know, but they've long been referred to as
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

#
# Main
#

# set-up directories
[ -e "./sets/" ] && Fatal "./sets/ already exists! (please delete it)"
[ -e "./results/" ] && Fatal "./results/ already exists! (please delete it)"
[ -e "./infiles/" ] && Fatal "./infiles/ already exists! (please delete it)"
mkdir -p "./sets/"
mkdir -p "./results/"
mkdir -p "./infiles/"

# generate jitter set file
./jitter-gen.sh --total 100 --jitters 800 1000 1200 1400 1600 1800 | shuf > "./sets/jitter.set"

# loop over all ruleset and block combinations
for ruleset in gbNW_pvNE pvNW_gbNE bpSW_gvSE gvSW_bpSE ; do
    for block in neutralA neutralB farbeA farbeB linieA linieB incongruentA incongruentB congruentA congruentB; do
        case "$block" in
             'neutralA'|'neutralB')         mode='--farbe-linie 50 50' ;;
             'farbeA'|'farbeB')             mode='--farbe-linie 75 25' ;;
             'linieA'|'linieB')             mode='--farbe-linie 25 75' ;;
             'incongruentA'|'incongruentB') mode='--con-incon 25 75'   ;;
             'congruentA'|'congruentB')     mode='--con-incon 75 25'   ;;
        esac
        # generate conan set files
        ./events-gen.sh --rule-set "$ruleset" $mode --pngs svg/MiSIT_layers_png/*.png > "./sets/${ruleset}_${block}.set"

        case "$block" in
             'neutralA'|'neutralB')         cfg_file='neutral.cfg'     ;;
             'farbeA'|'farbeB')             cfg_file='farbe.cfg'       ;;
             'linieA'|'linieB')             cfg_file='linie.cfg'       ;;
             'incongruentA'|'incongruentB') cfg_file='incongruent.cfg' ;;
             'congruentA'|'congruentB')     cfg_file='congruent.cfg'   ;;
        esac
        # generate result files for events and jitters
        conan "./cfgs/${cfg_file}" "./sets/${ruleset}_${block}.set" > "./results/${ruleset}_${block}.results"
        conan ./cfgs/jitter.cfg "./sets/jitter.set" > "./results/${ruleset}_${block}_jitter.results"
    done
done

RULE_SET=''
# build and output the final presentation "input" files
for KEY in "${!infiles[@]}"; do
  RULE_SET=${KEY%_*}

  BLOCK_NUM=1
  for BLOCK in ${infiles[${KEY}]}; do
    # convert into a presentation-ready format and join with jitter info and append block num
    join ./results/${RULE_SET}_${BLOCK}.results ./results/${RULE_SET}_${BLOCK}_jitter.results | \
      sed -f ./conan2input.sed | sed -f ./conan2input.sed | sed -e "1,\$ s/\$/ ${BLOCK_NUM}/" \
      >> ./infiles/${KEY}.txt

    BLOCK_NUM=$(( $BLOCK_NUM + 1 ))
  done
done

