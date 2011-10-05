require 'open-uri'
require 'json'

# unfortunately, without using java script, this would only gets the first 15 products
BOSE_URL = 'http://store.apple.com/us/search?find=bose'
# this will actually get everything, set up for up to 30 products
URL = 'http://store.apple.com/us/internalsearch?searchConfig=&term=bose&page=1&pageSize=30&resultOffset=0'

json_hash = JSON.parse(open(URL).read)
raise "web service error" if json_hash.has_key? 'Error'

products = json_hash['body']['match']['list']

# if the program failed, we don't want to 
# overwrite the existing list
if products.empty?
  puts "failed to gather any codes"
  exit
end

#part numbers are of the form H1517VC/A
puts "#{products.size} codes"
f = File.open('codes.txt', 'w')
products.each do |product|
  puts product["partNumber"]
  f.puts product["partNumber"]
end
f.close

codes = products.collect{|product| product["partNumber"]}

codes.each {|code| puts code}
