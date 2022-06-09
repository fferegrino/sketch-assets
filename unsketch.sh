#!/usr/bin/env bash

function unsketch {
    source=$1
    filename=$(basename -- $1)
    folder="${filename%.*}"
    echo "Decompressing $filename"

    unzip -qq -o -d $folder $source

    find $folder -type f -name "*.json" \
        -exec sh -c "jq . {} | sponge {}" \;

    rm -rf $folder/previews/preview.png
}

for i in `find . -name "*.sketch" -type f`; do
    unsketch "$i"
done
