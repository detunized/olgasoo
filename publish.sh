#!/bin/bash
set -e

DIR=tmp

rm -rf $DIR
git clone --branch gh-pages . $DIR

cd $DIR
    git remote set-url origin git@github.com:detunized/olgasoo.git
    git pull --ff

    rsync -a --delete --exclude .git ../site/ ./
    find . -name .DS_Store -delete
    git add -A
    git commit -m "Publish generated site"
    git push origin gh-pages
cd ..
