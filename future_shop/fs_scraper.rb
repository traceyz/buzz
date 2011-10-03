$LOAD_PATH << '..'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'cgi'

require 'utils'

$review_count = 0
FORUM_ID = 23
ROOT = "http://www.futureshop.ca"
#before this date we used a different unique key function
#this was the latest review before transferring over to the Mac
CUT_OVER = Date.civil(2011,6,7)

class ForumProductName < ActiveRecord::Base
end

class Review < ActiveRecord::Base
end

def determine_fpn(title)
  ForumProductName.find_by_name(title)
end

def build_reviews
  begin
    doc = Nokogiri::HTML(File.open("index.html", "r"))
    title = doc.at_css("title").text.sub(/\s+\:.+/,"")
    fpn = determine_fpn(title)
    puts "FPN NIL #{title}" if fpn.nil?
    return if fpn.nil?
    puts "#{title} => #{fpn.prod_id}"
    reviews = doc.css(".customer-review")
    reviews.each do |review|
      summary = review.at_css(".title").text
      review_data = review.at_css(".block").text.gsub(/\s+/, " ")
      #review_data like Glen, Toronto - May 25, 2011
      #could also be Deval Singh, Calgary,AB - February 12, 2011
      reviewer, date = review_data.split(" - ")
      rev_date = Utils.build_date(date.strip)
      
      next if rev_date <= CUT_OVER
      reviewer =~ /\A([^,]+), (.+)\z/
      author = $1
      location = $2
      rating = nil
      rating_elt = review.at_css(".rating")
      #of the form 4.0 /5
      rating = rating_elt.text.strip[0].to_f unless rating_elt.nil?
      content = review.css(".text")[1].text.strip
      begin
        Review.create(
          forum_id: FORUM_ID,
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

build_reviews