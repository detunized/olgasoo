#!/usr/bin/env ruby

require "mechanize"
require "cgi"
require "titleize"
require "stringio"
require "fileutils"

FileUtils.rm_rf "galleries"

config = StringIO.new "", "w"

config.puts "galleries:"

m = Mechanize.new
m.get("http://olgasoo.com") do |page|
    page.css(".albumdesc a").each do |link|
        album_name = link.text
        album_slug = album_name.downcase.gsub(/\s+/, "-")
        puts album_slug

        config.puts "  - name: #{album_name}"
        config.puts "    slug: #{album_slug}"
        config.puts "    image: #{album_slug}.jpg"
        config.puts "    items:"

        album = m.click link
        album.css(".imagethumb > a").each_with_index do |link, index|
            picture = m.click link
            picture.at_css("#gallerytitle h2 span").remove

            name = picture.at_css("#gallerytitle h2").text.strip.titleize
            slug = name.downcase.gsub(/\s+/, "-")
            filename = "%02d-%s.jpg" % [index + 1, slug]
            description = picture.at_css("#narrow").inner_html[/(.*?)</, 1].strip

            config.puts "    - name: #{name}"
            config.puts "      image: #{filename}"
            config.puts "      description: #{description}"

            puts "  - #{filename}"
            jpg = m.click picture.at_css("#image a")

            path = File.join "galleries", album_slug, filename

            puts "    saving to #{path}"
            jpg.save File.join("galleries", CGI.unescape(album_slug), filename)

            # Save config all the time
            File.open "galleries/config.yaml", "w" do |io|
                io.write config.string
            end
        end
    end
end

