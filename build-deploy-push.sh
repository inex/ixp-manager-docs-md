#! /bin/bash

if [[ -z $1 ]]; then
    echo ERROR: you must supply a commit message
    exit -1
fi

mkdocs build && mkdocs gh-deploy && git add . && git commit -am "$1" && git push



