#!/usr/bin/env ruby

require "nokogiri"
require "fileutils"
require "yaml"

HTML_DIR = "original/HTML"
IMAGE_DIR = "images"
OUT_DIR = "site"

CONFIG = YAML.load_file "config.yaml"

def assert expression, message = ""
    fail message if !expression
end

def load_file filename
    File.read File.join(HTML_DIR, filename)
end

def save_file content, filename
    path = File.join OUT_DIR, filename
    FileUtils.mkdir_p File.dirname path
    File.open path, "w" do |io|
        io.write content
    end
end

def load_html filename
    Nokogiri::HTML::Document.parse load_file filename
end

def save_html doc, filename
    save_file doc.to_html, filename
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
    system "rsync -a --delete #{IMAGE_DIR}/ #{OUT_DIR}/assets/images/"
end

def replace_original_images
    FileUtils.mv "#{OUT_DIR}/assets/images/hero-bg.jpg", "#{OUT_DIR}/assets/img/backgrounds/"
    FileUtils.mv "#{OUT_DIR}/assets/images/logo-white.png", "#{OUT_DIR}/assets/img/"
    FileUtils.mv "#{OUT_DIR}/assets/images/shop-header-bg.jpg", "#{OUT_DIR}/assets/img/backgrounds/"
end

def remove_elements_by_class doc, classes
    classes.each do |i|
        e = doc.at_css(".#{i}")
        assert e, "Can't file class '#{i}'"
        e.remove
    end
end

def remove_elements_by_id doc, ids
    ids.each do |i|
        e = doc.at_css("##{i}")
        assert e, "Can't file id '#{i}"
        e.remove
    end
end

def disable_link node
    node["onclick"] = "return false;"
end

def gallery_filename config
    "gallery-#{config['slug']}.html"
end

def load_and_clean_up_html filename
    doc = load_html filename

    # Lot's of elements we don't need
    remove_elements_by_class doc, %w[
        ws-topbar
        ws-subscribe-section
        ws-footer-payments
    ]

    remove_elements_by_id doc, %w[
        ws-instagram-section
    ]

    #
    # Left navbar
    #

    left_navbar = doc.css("ul.navbar-left > li")
    assert left_navbar.size == 3

    # Change home dropdown into a simple link
    li = doc.create_element "li"
    li.inner_html = '<a href="index.html">Home</a>'
    left_navbar[0].replace li

    # Disable "about" link
    left_navbar[1].at_css("a")["onclick"] = "return false;"

    # Remove "shop" link
    left_navbar[2].remove

    #
    # Right navbar
    #

    right_navbar = doc.css("ul.navbar-right > li")
    assert right_navbar.size == 3

    # Remove "pages" link
    right_navbar[0].remove

    # Change "journal" link to etsy
    link = right_navbar[1].at_css("a")
    link["href"] = CONFIG["links"]["etsy"]
    link.content = CONFIG["shop"]["buy_prints"]

    # Disable "contact" link
    disable_link right_navbar[2].at_css("a")

    #
    # Footer
    #

    footer = doc.at_css(".ws-footer")
    element_with_text(footer, "h3", "About Us").content = CONFIG["footer"]["about"]
    element_with_text(footer, "p", "We are a family").content = CONFIG["footer"]["description"]

    # Remove some columns (keep the columns, just remove the content)
    columns = footer.css(".ws-footer-col")
    assert columns.size == 4

    columns[1].inner_html = ""

    # Update social network links
    links = columns[2].css("li > a")
    assert links.size == 4
    links[0]["href"] = CONFIG["links"]["facebook"]
    links[1..-1].each do |i|
        disable_link i
    end

    # Update shop links
    links = columns[3].css("li > a")
    assert links.size == 4
    links[0]["href"] = CONFIG["links"]["etsy"]
    links[0].content = CONFIG["shop"]["prints"]
    links[1]["href"] = "contact.html"
    links[1].content = CONFIG["shop"]["originals"]
    disable_link links[1]
    links[2..-1].each do |i|
        i.remove
    end

    #
    # Footer bar
    #

    bar = doc.at_css(".ws-footer-bar")
    element_with_text(bar, "p", "Handcrafted with love").inner_html = CONFIG["copyright"]

    doc
end

def process_index_html
    doc = load_and_clean_up_html "index.html"

    # Lot's of elements we don't need
    remove_elements_by_class doc, %w[
        ws-arrivals-section
        ws-works-section
        ws-call-section
    ]

    # Document title
    doc.title = CONFIG["title"]

    # Title
    element_with_text(doc, "h1", "A selection of").content = CONFIG["name"]

    # Subtitle
    element_with_text(doc, "h4", "Spanning the fields of").content = CONFIG["description"]

    # Fix "View Collention"
    button = element_with_text(doc, "a", "View Collention")
    button.content = CONFIG["view_collection"]
    disable_link button

    #
    # About
    #

    about = doc.at_css(".ws-about-content")
    element_with_text(about, "h3", "Made with Love").content = CONFIG["about"]["title"]
    element_with_text(about, "p", "We are a family").inner_html = CONFIG["about"]["description"]

    #
    # Galleries
    #

    # Copy example items
    items = doc.css(".featured-collections-item")

    # Delete all but first
    items[1..-1].each do |i|
        i.remove
    end

    # And copy it
    item = items.first
    (CONFIG["galleries"].size - 1).times do
        item.add_next_sibling item.dup
    end

    # Populate items
    items = doc.css(".featured-collections-item")
    items.each_with_index do |i, index|
        g = CONFIG["galleries"][index]

        i.at_css("h3").content = g["name"]

        img = i.at_css("img")
        img["alt"] = g["name"]
        img["src"] = File.join "assets/images", g["image"]

        i.at_css("a")["href"] = gallery_filename g
    end

    #
    # Save
    #

    save_html doc, "index.html"
end

def generate_gallery doc, config
    # Lot's of elements we don't need
    remove_elements_by_class doc, %w[
        nav-tabs
        ws-more-btn-holder
        ws-logo
    ]

    remove_elements_by_id doc, %w[
        prints
        illustrated
        journals
        sale
    ]

    # Document title
    doc.title = config["name"]

    # Title
    element_with_text(doc, "h1", "Our Products").content = config["name"]

    # Find all items
    all = doc.at_css("#all")
    items = all.css(".ws-works-item")
    items[1..-1].each do |i|
        i.remove
    end

    # And copy it
    item = items.first
    (config["items"].size - 1).times do
        item.add_next_sibling item.dup
    end

    # Populate items
    items = doc.css(".ws-works-item")
    items.each_with_index do |i, index|
        image = config["items"][index]

        img = i.at_css("figure > img")
        img["src"] = File.join "assets/images/galleries", config["slug"], image['image']
        img["alt"] = image["name"]

        # Description
        i.at_css(".ws-item-category").content = image["description"]

        # Name
        i.at_css(".ws-item-title").content = image["name"]

        # Remove price
        i.at_css(".ws-item-price").content = image["description"]
    end
end

def generate_galleries
    CONFIG["galleries"].each do |i|
        doc = load_and_clean_up_html "shop.html"
        generate_gallery doc, i
        save_html doc, gallery_filename(i)
    end
end

def process_main_css
    doc = load_file "assets/css/main.css"

    # Fix buggy menu box at 768px wide screen
    doc.sub! "@media only screen and (max-width : 768px) {",
             "@media only screen and (max-width : 767px) {"

    doc += "
        .featured-collections-item {
            padding-top: 40px;
        }
    "
    save_file doc, "assets/css/main.css"
end

#
# main
#

copy_assets
replace_original_images
process_index_html
generate_galleries
process_main_css
