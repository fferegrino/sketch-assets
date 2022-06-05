#!/usr/bin/env bash

unzip -o -d tcsg tcsg.sketch

find ./tcsg -type f -name "*.json" -exec  sh -c "jq . {} | sponge {}" \;

rm -rf ./tcsg/previews/preview.png
