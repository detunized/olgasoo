Unpack original template and artwork
====================================

    $ unzip ~/Dropbox/stuff/themeforest-14021721-artday-creative-shop-template.zip -d original
    $ rsync -av --delete ~/Dropbox/stuff/olgasoo-original-artwork/ original/artwork/

HTTP server with livereload
===========================

    $ npm -g install live-server
    $ live-server

Automatic build
===============

    $ brew install watchman
    $ watchman-make -p build.rb config.yaml --make ./build.rb -t ''
