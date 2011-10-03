# reads the apple product page saved to a file, and identifies the codes to build links to review lists
# in general a code will be something like TK201VC/B
# the page holding the reviews starting with the most recent will be at
# http://store.apple.com/us/reviews/TK201VC/B?rs=newest

require 'rubygems'
require 'nokogiri'

f = File.open('codes.txt', 'w')
doc = Nokogiri::HTML(File.open("index"))
count = 0
doc.css(".superlink").each do |product|
  link = product.at_css("a").to_s
  link =~ /p=([A-Z0-9]+\/[A-Z])/
  code = $1
  unless code.nil?
    count += 1
    f.puts code
  end
end
puts "wrote #{count.to_s} codes" 

