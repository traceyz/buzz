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
  ForumProductName.find_by_name(title)
end


def process_review_page(page_url,fpn) 
  reviews_page = Nokogiri::HTML(open(page_url))
  reviews = reviews_page.css(".BVRRReviewDisplayStyle5")
  reviews.each do |review|
    date = review.at_css(".BVRRReviewDate").text
    rev_date = Utils.build_date3(date)
    next if rev_date < CUT_OVER
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
      puts "record already exists"
    end
  end
  next_anchor = reviews_page.at_css(".BVRRNextPage a")
  unless next_anchor.nil?
    next_link = next_anchor[:href]
    puts "NEXT LINK " + next_link
    process_review_page(next_link,fpn)
  end
end

def process_product_reviews(page_url)
  begin
    doc = Nokogiri::HTML(open(page_url))
    title = doc.at_css("title").text.strip
    title.gsub!(/[^A-z0-9\s]/,"")
    title.gsub!(/\s+/, " ")
    fpn = determine_fpn(title)
    puts "NIL FPN for #{title}" if fpn.nil?
    return if fpn.nil?
    reviews_link = doc.at_css("noscript iframe")[:src]
    process_review_page(reviews_link, fpn)
  rescue => e
    puts e.message
    puts e.backtrace.inspect
  end
end


IO.readlines("links_list.txt").each do |link|
  process_product_reviews(link)
end

puts "inserted #{$review_count} reviews"