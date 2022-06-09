#!/usr/bin/env bash

function dosketch {
    source_folder=$(basename -- $1)
    tmp_folder="${source_folder}_tmp"
    extension="sketch"
    sketch_name="${source_folder%%_*}.${extension}"
    echo "Compressing ${source_folder} into $sketch_name"
    cp -r $source_folder $tmp_folder


    find $tmp_folder -type f -name "*.json" \
        -exec  sh -c "jq -c . {} | sponge {}" \;

    rm -rf $tmp_folder/previews/preview.png

    rm -rf $tmp_folder/previews/.DS_Store

    cd $tmp_folder; zip -r -X ../$sketch_name *

    cd ..; rm -rf $tmp_folder
}

for d in */
do
    if [ -d "$d" ]; then
        if [ -d "$d/pages" ]; then
            dosketch "$d"
        fi
    fi
done