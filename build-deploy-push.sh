#! /bin/bash

if [[ -z $1 ]]; then
    echo ERROR: you must supply a commit message
    exit -1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
./venv/bin/mkdocs build && ./venv/bin/mkdocs gh-deploy && git add . && git commit -am "$1" && git push
cd -



