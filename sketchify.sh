#!/usr/bin/env bash

cp -r ./tcsg ./tcsg_temp

find ./tcsg_temp -type f -name "*.json" -exec  sh -c "jq -c . {} | sponge {}" \;

rm -rf ./tcsg_temp/previews/preview.png

cd ./tcsg_temp; zip -r -X ../tcsg.sketch *

cd ..; rm -rf ./tcsg_temp
