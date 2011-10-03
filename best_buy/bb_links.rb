require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'cgi'

$f = File.open("links_list.txt", "w")

url = "http://www.bestbuy.com/site/Brands/Bose/pcmcat168900050013.c?id=pcmcat168900050013&searchterm=bose&searchresults=1"

ROOT = "http://www.bestbuy.com"

$link_count = 0

def build_links(my_url)
  all_categories = Nokogiri::HTML(open(my_url))
  category_links = all_categories.css(".center a")
  category_links.each do |l|
    link = ROOT + l[:href]
    category_page = Nokogiri::HTML(open(link))
    title = category_page.at_css("title").text
    next if title =~ /Accessories/
    puts
    puts "CATEGORY #{title}"
    #note that the mobile solutions category doesn't have a 'sub-categories page'
    #so it doesn't have any matches here.
    #however, all its products show up through the headphones category
    sub_category_links = category_page.css("h4[class='center'] a")
    sub_category_links.each do |l|
      _link = ROOT + l[:href]
      begin
        products_page = Nokogiri::HTML(open(_link))
        title = products_page.at_css("title").text.strip
        next if title =~ /Accessories/
        puts _link
        puts title
        product_blocks = products_page.css(".hproduct")
        product_blocks.each do |product|
          next unless product.to_s =~ /\d+ reviews/i
          link = product.at_css(".uri")[:href]
          next if link =~ /bag|battery/i
          #we want to elminate the session info, since it will be out of date
          head = link.split(";")[0].strip
          tail = link.split("?")[1].strip
          $f.puts ROOT + head + "?" + tail + '#tabbed-customerreviews'
          $link_count += 1
        end
          
      rescue => e
        #some links upset Nokogiri
        puts "\n#{link}"
        puts e.message
        puts
      end
    end
    
  end
end

build_links(url)

puts "wrote #{$link_count} links"