#!/usr/bin/env ruby

require "fileutils"

#FileUtils.rm_rf "images/galleries"

images = Dir["images/original-galleries/**/*.jpg"]
images.each do |src|
    dst = src.sub "original-galleries", "galleries"
    FileUtils.mkdir_p File.dirname dst

    puts src
    system "convert -resize 900x1000^ -gravity center -extent 900x1000 #{src} #{dst}"
end
