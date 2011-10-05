# scrape reviews for all products listed on the apple store
# assumes codes have been accumulated form the latest product_list.html
# and stored in codes.txt
$LOAD_PATH << '..'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'mysql'

require 'utils'


class ForumProductName < ActiveRecord::Base
end

require 'open-uri'
require 'json'

class Review < ActiveRecord::Base
end

# this will get the keys for up to 30 products
URL = 'http://store.apple.com/us/internalsearch?searchConfig=&term=bose&page=1&pageSize=30&resultOffset=0'
json_hash = JSON.parse(open(URL).read)
raise "web service error" if json_hash.has_key? 'Error'

products = json_hash['body']['match']['list']

raise "empty product codes" if products.empty?

codes = products.collect{|product| product["partNumber"]}

root = 'http://store.apple.com/us/reviews/'
tail = '?rs=newest'
#before this date, reviews run with perl on the PC
#used a different function to calculate the unique key
cut_over = Date.civil(2011,7,10)

$review_count = 0

codes.each do |code| #each code ends with a new line
  begin
    url = root+code.strip+tail
    doc = Nokogiri::HTML(open(url))
    #want a name that is only letters, numbers, parentheses and single spaces
    title = doc.at_css("title").text.gsub(/[^A-z0-9\s\(\)]/,"")
    title.gsub!(/\s+Apple Store \(US\)/,"")
    title.sub!("Customer Reviews ","")
    prod_name = title.gsub(/\s+/," ")
    fpn = ForumProductName.find_by_name(prod_name)
    if fpn.nil?
      puts "*#{prod_name}* FPN nil"
      puts url
      next
    end
    doc.css('.hreview').each do |product|
    
      date = product.css(".dtreviewed").text.strip
      rev_date = Utils.build_date(date)
      next if rev_date <= cut_over
    
      summary = product.css(".summary").text
      rating = product.css("img").to_s
      rating.to_s[/alt=\"(\d)\.\d\"/]
      rating = $1

      author = product.css(".vcard > .fn").text
      location = product.css(".vcard > .region").text || "NA"
      content = product.css(".description").text.strip
    
      begin
        Review.create!(
          forum_id: 18,
          prod_id: fpn.prod_id,
          forum_prod_name_id: fpn.id,
          rev_date: rev_date,
          author: author,
          location: location,
          rating: rating,
          summary: summary,
          content: content,
          uniqueKey: Utils.unique_key(summary,content),
          created_at: Time.now
        )
        puts "review added #{rev_date.to_s}"
        $review_count += 1
      rescue ActiveRecord::RecordNotUnique => e
        puts "record already exists"
      end
    end
  
  rescue => e
    puts e.message
    puts e.backtrace.inspect
  end
  
end

puts "inserted #{$review_count} reviews"


