#!/usr/bin/env ruby

require "fileutils"
require "tmpdir"

ART_DIR = "original/artwork"
OUT_DIR = "processed-images"

REBUILD = ARGV.include?("-r") || ARGV.include?("--rebuild")

def sh s
    system s
        .split("\n")
        .map { |i| i.strip }
        .reject { |i| i.empty? }
        .join " "
end

def make src, dst, command_or_commands
    if REBUILD || !File.exist?(dst) || File.mtime(src) > File.mtime(dst)
        [command_or_commands].flatten.each do |i|
            sh i
        end
    end
end

FileUtils.rm_rf OUT_DIR if REBUILD
FileUtils.mkdir_p OUT_DIR

# Covers
images = Dir["#{ART_DIR}/covers/*.jpg"]
images.each_with_index do |src, index|
    filename = File.basename(src).sub(".jpg", "-cover.jpg")
    dst = File.join OUT_DIR, filename

    w = 1200
    h = 1200

    puts "[#{index + 1}/#{images.size}] #{src} -> #{dst}"

    Dir.mktmpdir do |dir|
        # Resize only if bigger
        make src, dst, "convert '#{src}' -resize #{w}x#{h}\\> '#{dst}'"
    end
end

# Headers
images = Dir["#{ART_DIR}/headers/*.jpg"]
images.each_with_index do |src, index|
    filename = File.basename(src).sub(".jpg", "-header.jpg")
    dst = File.join OUT_DIR, filename

    w = 1200
    h = 1200

    puts "[#{index + 1}/#{images.size}] #{src} -> #{dst}"

    Dir.mktmpdir do |dir|
        make src, dst, "convert '#{src}' -resize #{w}x#{h} '#{dst}'"
    end
end

# Galleries
images = Dir["#{ART_DIR}/galleries/*/*.jpg"]
images.each_with_index do |src, index|
    filename = File.basename src
    gallery = File.basename File.dirname src
    dst = File.join OUT_DIR, gallery, filename

    FileUtils.mkdir_p File.dirname dst

    w = 900
    h = 1000
    k = 0.8

    iw = (w * k).to_i
    ih = (h * k).to_i

    puts "[#{index + 1}/#{images.size}] #{src} -> #{dst}"

    Dir.mktmpdir do |dir|
        tmp = File.join dir, "cropped.jpg"

        make src, dst, ["
            convert #{src} -resize #{iw}x#{ih}^
            -gravity center -extent #{iw}x#{ih} #{tmp}
        ", "
            convert #{tmp}
            \\( +clone -background black -shadow 75x10+9+9 \\)
            +swap -background 'gray(94%)' -layers merge +repage
            -gravity center -extent #{w}x#{h} #{dst}
        "]

        odst = dst.sub ".jpg", "-original.jpg"
        ow = 1200
        oh = 1200

        make src, odst, "convert '#{src}' -resize #{ow}x#{oh}\\> '#{odst}'"
    end
end
