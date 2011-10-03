require 'rubygems'
require 'nokogiri'
require 'open-uri'

ROOT = "http://www.target.com"

$f = File.open("links_list.txt", "w")

url = "http://www.target.com/s?keywords=bose"


def build_links(page_url)
  doc = Nokogiri::HTML(open(page_url))
  products = doc.css(".productTitle a")
  count = 0
  products.each do |p|
    link = p[:href]
    next unless link =~ /\/Bose/
    link =~ /(\/Bose.+?)\/ref=sr/
    $f.puts link
    count += 1
  end
  puts "wrote #{count} links"
end

build_links(url)