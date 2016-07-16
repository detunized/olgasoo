#!/usr/bin/env ruby

require "nokogiri"
require "fileutils"
require "yaml"

HTML_DIR = "original/HTML"
OUT_DIR = "site"

CONFIG = YAML.load_file "config.yaml"

def load_html filename
    Nokogiri::HTML::Document.parse File.read File.join(HTML_DIR, filename)
end

def save_html doc, filename
    path = File.join OUT_DIR, filename
    FileUtils.mkdir_p File.dirname path
    File.open path, "w" do |io|
        io.write doc.to_html
    end
end

def element_with_text doc, tag, text
    doc.css(tag).find { |i| i.text.start_with? text }
end

def append_to_file filename, text
    File.open File.join(OUT_DIR, filename), "a" do |io|
        io.write text
    end
end

def copy_assets
    FileUtils.mkdir_p OUT_DIR
    system "rsync -a --delete #{HTML_DIR}/assets #{OUT_DIR}/"
end

def remove_elements_by_class doc, classes
    classes.each do |i|
        doc.at_css(".#{i}").remove
    end
end

def remove_elements_by_id doc, ids
    ids.each do |i|
        doc.at_css("##{i}").remove
    end
end

def process_index_html
    doc = load_html "index.html"

    # Document title
    doc.title = CONFIG["title"]

    # Lot's of elements we don't need
    remove_elements_by_class doc, %w[
        ws-topbar
        ws-arrivals-section
        ws-works-section
        ws-call-section
        ws-subscribe-section
        ws-logo
        ws-about-content
    ]

    remove_elements_by_id doc, %w[
        ws-instagram-section
    ]

    #
    # Left navbar
    #

    left_navbar = doc.css("ul.navbar-left > li")

    # Change home dropdown into a simple link
    li = doc.create_element "li"
    li.inner_html = '<a href="/">Home</a>'
    left_navbar[0].replace li

    # Disable "about" link
    left_navbar[1].at_css("a")["onclick"] = "return false;"

    # Remove "shop" link
    left_navbar[2].remove

    #
    # Right navbar
    #

    right_navbar = doc.css("ul.navbar-right > li")

    # Remove "pages" link
    right_navbar[0].remove

    # Disable "about" link
    right_navbar[1].at_css("a")["onclick"] = "return false;"

    # Disable "about" link
    right_navbar[2].at_css("a")["onclick"] = "return false;"

    # Title
    element_with_text(doc, "h1", "A selection of").content = CONFIG["name"]

    # Subtitle
    element_with_text(doc, "h4", "Spanning the fields of").content = CONFIG["description"]

    # Fix "View Collention"
    element_with_text(doc, "a", "View Collention").content = "View Collection"

    #
    # Galleries
    #

    # Copy example items

    items = doc.css(".featured-collections-item")

    # Delete all by first
    items[1..-1].each do |i|
        i.remove
    end

    item = items.first
    (CONFIG["galleries"].size - 1).times do
        item.add_next_sibling item.dup
    end

    # Populate data names
    items = doc.css(".featured-collections-item")
    items.each_with_index do |i, index|
        i.at_css("h3").content = CONFIG["galleries"][index]["name"]
    end

    #
    # Save
    #

    save_html doc, "index.html"
end

def process_main_css
    append_to_file "assets/css/main.css", <<-EOT

/*--------------------------------------
    15) Added by detunized
---------------------------------------*/
.featured-collections-item {
    padding-top: 40px;
}
EOT
end

#
# main
#

copy_assets
process_index_html
process_main_css
