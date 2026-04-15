#!/usr/bin/env bash

set -eo pipefail

TEMPLATE='template.pdf'
OUTPUT='output.pdf'

US_LEGAL_W_PTS=612
US_LEGAL_H_PTS=1008

OFFSET_T_L='504 308'
OFFSET_T_R='504 11'
OFFSET_B_L='71 308'
OFFSET_B_R='71 11'

create_stamp() {
    local infile_landscape="$1"
    local offset="$2"
    local outfile="$3"
    local stamp_intermediate='intermediate-stamp-landscape.pdf'

    # Set page size & offset
    gs -q -dSAFER -dBATCH -dNOPAUSE \
        -o "$stamp_intermediate" \
        -sDEVICE=pdfwrite \
        -dUseCropBox \
        -dDEVICEWIDTHPOINTS=$US_LEGAL_H_PTS -dDEVICEHEIGHTPOINTS=$US_LEGAL_W_PTS -dFIXEDMEDIA \
        -c "<</PageOffset [$offset]>> setpagedevice" \
        -f "$infile_landscape"

    # trap "rm -f $stamp_intermediate" RETURN

    # Rotate
    gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite \
        -sOutputFile="$outfile" -dAutoRotatePages=/None \
        -c '<</Orientation 1>> setpagedevice' \
        -f "$stamp_intermediate"
}

fill_template() {
    local -a labels=( "$@" )
    local -a offsets=( "$OFFSET_T_L" "$OFFSET_T_R" "$OFFSET_B_L" "$OFFSET_B_R" )
    local -a stamps=( stamp-{t,b}-{l,r}.pdf )

    for i in {0..3}; do
        create_stamp "${labels[$i]}" "${offsets[$i]}" "${stamps[$i]}"
    done

    local -a partials=( template-partial-{1..3}.pdf )
    trap "rm -f ${stamps[*]} ${partials[*]}" RETURN
    partials=( "$TEMPLATE" "${partials[@]}" "$OUTPUT" )

    for i in {0..3}; do
        pdftk "${partials[$i]}" stamp "${stamps[$i]}" output "${partials[$i+1]}"
    done
}

fill_template "$@"
