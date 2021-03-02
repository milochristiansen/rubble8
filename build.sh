#!/bin/zsh

rm -r build
mkdir -p build

cp -r std_lib/docs/ build/other
cp -r std_lib/addons/ build/addons

CGO_ENABLED=0
go build -o build/rubble ./interface/universal
