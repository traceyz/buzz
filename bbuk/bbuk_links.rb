require 'rubygems'
require 'nokogiri'
require 'open-uri'

$f = File.open("links_list.txt", "w")

url = "http://www.reevoo.com/search?q=bose"
ROOT = "http://www.reevoo.com"
$link_count = 0

def build_links(my_url)
  doc = Nokogiri::HTML(open(my_url))
  links = doc.css("a[class='reviews']")
  links.each do |l|
    #we only want ones that have reviews
   next unless l.text =~ /Read \d+ reviews/im
   link =  ROOT + l[:href]
   #we don't track products that aren't bose
   next unless link =~ /bose/i
   #we don't track these products
   next if link =~ /bag/ || 
           link =~ /kit/ || 
           link =~ /uts20/ || 
           link =~ /ufs20/ || 
           link =~ /mount/ || 
           link =~ /enhancer/
   link.gsub!(/#reviews/,"")
   link += "/page/1"
   $f.puts link 
   $link_count += 1
  end
  
  next_anchor = doc.at_css("a[class='next_page']")
  unless next_anchor.nil?
    next_link = ROOT + next_anchor[:href]
    puts next_link
    build_links(next_link)
  end
  
end


build_links(url)

puts "wrote #{$link_count} links"