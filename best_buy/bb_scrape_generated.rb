$LOAD_PATH << '..'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'cgi'

require 'utils'

$review_count = 0
FORUM_ID = 26
ROOT = "http://www.bestbuy.com"
CUT_OVER = Date.civil(2011,7,8)

class ForumProductName < ActiveRecord::Base
end

class Review < ActiveRecord::Base
end

def determine_fpn(title)
  title.gsub!(/[^A-z0-9\s]/,"")
  title.gsub!(/\s+/, " ")
  ForumProductName.find_by_name(title)
end


def process_review_page
  #reviews_page = Nokogiri::HTML(open(page_url))
  reviews_page = Nokogiri::HTML(File.open("index", "r"))
  title = reviews_page.at_css("title").text.strip
  fpn = determine_fpn(title)
  return if fpn.nil?
  reviews = reviews_page.css(".BVRRReviewDisplayStyle5")
  puts "page has #{reviews.size} reviews"
  reviews.each do |review|
    date = review.at_css(".BVRRReviewDate").text
    rev_date = Utils.build_date3(date)
    next if rev_date < CUT_OVER
    #if featured review has an older date,
    #return would have lost the recent reviews
    author = review.at_css(".BVRRNickname").text
    location = ""
    location_elt = review.at_css(".BVRRUserLocation")
    location = location_elt.text unless location_elt.nil?
    headline = review.at_css(".BVRRReviewTitle").text
    rating = review.at_css(".BVRRRatingNumber").text.to_f
    content = review.at_css(".BVRRReviewText").text
    begin
      Review.create(
        forum_id: FORUM_ID,
        prod_id: fpn.prod_id,
        forum_prod_name_id: fpn.id,
        rev_date: rev_date,
        author: author,
        location: location,
        rating: rating,
        headline: headline,
        content: content,
        uniqueKey: Utils.unique_key(headline+content),
        created_at: Time.now        
      )
      puts "review added #{rev_date.to_s}"
      $review_count += 1
    rescue ActiveRecord::RecordNotUnique => e
      
      puts "#{rev_date} record already exists"
    end
  end

end

process_review_page

puts "inserted #{$review_count} reviews"