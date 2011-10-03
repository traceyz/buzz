require 'rubygems'
require 'nokogiri'
require 'open-uri'

$f = File.open("links_list.txt", "w")

url = "http://reviews.cnet.com/1770-5_7-0.html?query=bose&searchtype=products&tag=contentMain;contentBody;allr;rf"

ROOT = "http://reviews.cnet.com"
TAIL = "?tag=srt;date&uoShowOnly=full&ord=creationDate%20desc"

$link_count = 0

def build_links(my_url)
  doc = Nokogiri::HTML(open(my_url))
  products = doc.css(".resultInfo")
  products.each do |product|
    rating = product.at_css(".userRateOutOf")
    next if rating.nil? #we only want products that have been rated by users
    #puts rating.to_s
    link = product.at_css("a[class='resultName']")[:href]
    next unless link =~ /bose/i
    #this link has a /4505- in the url and will go to a "watch video review" page
    #changing that to /4852- will give a page with just the reviews
    #and appending this query string will give the recent ones
    #?tag=srt;date&uoShowOnly=full&ord=creationDate%20desc
    link.sub!(/\/4505-/, "/4852-")
    $f.puts ROOT + link + TAIL
    $link_count += 1
    
  end
  next_anchor = doc.at_css("li[class='next'] > a")
  unless next_anchor.nil?
    next_link = ROOT + next_anchor[:href]
    puts next_link
    build_links(next_link)
  end
end

build_links(url)

puts "wrote #{$link_count} links"