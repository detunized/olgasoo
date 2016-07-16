Unpack original template
========================

    $ unzip ~/Dropbox/stuff/themeforest-14021721-artday-creative-shop-template.zip -d original

HTTP server with livereload
===========================

    $ npm -g install live-server
    $ live-server

Automatic build
===============

    $ brew install watchman
    $ watchman-make -p build.rb config.yaml --make ./build.rb -t ''
