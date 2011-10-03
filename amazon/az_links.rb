# reads the amazon product page saved to a file, and identifies the codes to build links to review lists
# will recognize

require 'rubygems'
require 'nokogiri'
require 'open-uri'

f = File.open("links_list.txt", "w")

url = "http://www.amazon.com/s/ref=bl_sr_electronics?_encoding=UTF8&node=172282&field-brandtextbin=Bose"

$pg_count = 0

$all_links = []

def build_links(my_url)
  
doc = Nokogiri::HTML(open(my_url))
  product_data = doc.css('.product')
  product_data.each do |product|
    #note that scrapes do not show my prime status
    #lacking a rating means there are no images, and we should skip
    next unless product.at_css('.ratingWithoutPrimeImage') #note that scrapes do not show my prime status
    if product.to_s =~ /(http:\/\/www.amazon.com[^>]+product-reviews\/[A-Z0-9]+)/
      $all_links << $1
    end
  end
  if doc.at_css(".pagnNext a")
    next_link = doc.at_css(".pagnNext a")[:href]
    puts "next link " + next_link
    $pg_count += 1
    build_links(next_link)
  end
end

build_links(url)


links_count = 0
$all_links.flatten.uniq.each do |link|
  if link =~ /changer/i || 
          link =~/kit/i || 
          link =~ /stand/i || 
          link =~ /antenna/i || 
          link =~ /antena/i || 
          link =~ /tips/i || 
          link =~ /bracket/i || 
          link =~ /charger/i ||
          link =~ /earbuds/i ||
          link =~ /replacement/i ||
          link =~ /battery/i ||
          link =~ /connector/i ||
          link =~ /remote/i ||
          link =~ /amplifier/i ||
          link =~ /renewed/i ||
          link =~ /aviation/i ||
          link =~ /pedestal/i ||
          link =~ /travel/i || #this is a bag
          link =~ /AL8/i ||
          link =~ /Equalizer/i ||
          link =~ /converter/i ||
          link =~ /controller/i ||
          link =~ /control/i ||
          link =~ /enhancer/i
          link =~ /kit/i
          
       next
     end
  link += "/ref=cm_cr_dp_synop?ie=UTF8&showViewpoints=0&sortBy=bySubmissionDateDescending"
  f.puts link 
  puts link 
  links_count += 1
end

puts "wrote #{links_count} links"

f.close





