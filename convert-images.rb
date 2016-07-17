#!/usr/bin/env ruby

require "fileutils"
require "tmpdir"

#FileUtils.rm_rf "images/galleries"

def sh s
    system s
        .split("\n")
        .map { |i| i.strip }
        .reject { |i| i.empty? }
        .join " "
end

images = Dir["images/original-galleries/**/*.jpg"]
images.each do |src|
    dst = src.sub "original-galleries", "galleries"
    FileUtils.mkdir_p File.dirname dst

    w = 900
    h = 1000
    k = 0.8

    iw = (w * k).to_i
    ih = (h * k).to_i

    puts src

    Dir.mktmpdir do |dir|
        tmp = File.join dir, "cropped.jpg"

        sh "
            convert #{src} -resize #{iw}x#{ih}^
            -gravity center -extent #{iw}x#{ih} #{tmp}
        "

        sh "
            convert #{tmp}
            \\( +clone -background black -shadow 75x10+9+9 \\)
            +swap -background 'gray(94%)' -layers merge +repage
            -gravity center -extent #{w}x#{h} #{dst}
        "
    end
end
