#!/usr/bin/env bash

set -eo pipefail

OUTPUT='output.pdf'

US_LEGAL_W_PTS=612
US_LEGAL_H_PTS=792

create_upper_stamp() {
    local infile="$1"
    local outfile="$2"

    # Set page size & offset
    gs -q -dSAFER -dBATCH -dNOPAUSE \
        -o "$outfile" \
        -sDEVICE=pdfwrite \
        -dUseCropBox \
        -dDEVICEWIDTHPOINTS=$US_LEGAL_W_PTS -dDEVICEHEIGHTPOINTS=$US_LEGAL_H_PTS -dFIXEDMEDIA \
        -c "<</PageOffset [0 502]>> setpagedevice" \
        -f "$infile"
}

create_lower_stamp() {
    local infile="$1"
    local outfile="$2"

    # Set page size & offset
    gs -q -dSAFER -dBATCH -dNOPAUSE \
        -o "$outfile" \
        -sDEVICE=pdfwrite \
        -dUseCropBox \
        -dDEVICEWIDTHPOINTS=$US_LEGAL_W_PTS -dDEVICEHEIGHTPOINTS=$US_LEGAL_H_PTS -dFIXEDMEDIA \
        -c "<</PageOffset [0 0]>> setpagedevice" \
        -f "$infile"
}

combine_labels() {
    local labels=$1

    local n_pages
    n_pages=$(pdftk "$labels" dump_data | awk '/^NumberOfPages:/{print $2}')
    echo "Labels: $n_pages"

    mkdir -p out

    local j o=0
    for (( i = 1; i < n_pages; i += 2 )); do
        j=$((i+1))
        echo $i $j

        pdftk "$labels" cat "$i" output out/l1.pdf
        pdftk "$labels" cat "$j" output out/l2.pdf
        create_upper_stamp out/l1.pdf out/l1_stamp.pdf
        create_lower_stamp out/l2.pdf out/l2_stamp.pdf
        rm out/l1.pdf out/l2.pdf

        ((o+=1))
        pdftk out/l1_stamp.pdf stamp out/l2_stamp.pdf output "out/out${o}.pdf"
        rm out/l1_stamp.pdf out/l2_stamp.pdf
    done

    outfiles=$(printf 'out/out%d.pdf ' $(seq 1 $o))
    pdftk $outfiles cat output out/out-combined.pdf

    zip -r shipping-labels.zip out
}

combine_labels "$@"
