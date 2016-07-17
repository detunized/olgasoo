#!/bin/bash
set -e

DIR=tmp

rm -rf $DIR
git clone --branch gh-pages . $DIR
rsync -a --delete --exclude .git site/ $DIR/
cd $DIR
git add -A
git commit -m "Publish generated site"
git remote set-url origin git@github.com:detunized/olgasoo.git
git push origin gh-pages
cd ..
