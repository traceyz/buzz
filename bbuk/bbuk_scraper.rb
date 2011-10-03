$LOAD_PATH << '..'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'cgi'

require 'utils'

$review_count = 0
FORUM_ID = 27
ROOT = "http://www.reevoo.com"
CUT_OVER = Date.civil(2011,7,6)

class ForumProductName < ActiveRecord::Base
end

class Review < ActiveRecord::Base
end

def unique_key(strengths, weaknesses)
  key = strengths+weaknesses
  key.gsub!(/[^A-z0-9]/,"")
  key = key[0..19] if key.length > 20
  key
end

def determine_fpn(doc)
  prod_name = doc.at_css("title").text.sub(/\sReviews.+/,"")
  fpn = ForumProductName.find_by_name(prod_name)
  puts "NIL FPN for #{prod_name}" if fpn.nil?
  fpn
end

def build_reviews(page_url)
  begin
    doc = Nokogiri::HTML(open(page_url))
    fpn = determine_fpn(doc)
    puts "NIL FPN for #{page_url}" if fpn.nil?
    return if fpn.nil?
    reviews = doc.css(".review")
    reviews.each do |review|
      date = review.at_css(".date").text
      rev_date = Utils.build_date2(date)
      next if rev_date <= CUT_OVER
      attribution = review.at_css(".attribution").text.split(/\s+/)
      author = attribution[0].strip
      author.sub!(/,\z/,"")
      location = ""
      if attribution.length > 1
        location = attribution[1,attribution.length-1].join(" ")
      end
      rating = review.at_css(".value").text.to_f
      strengths = review.css(".pros")[1].text.gsub(/\s+/, " ")
      weaknesses = review.css(".cons")[1].text.gsub(/\s+/, " ")
    
      content = "Strengths: #{strengths} Weaknesses: #{weaknesses}"

      begin
        Review.create(
          forum_id: FORUM_ID,
          prod_id: fpn.prod_id,
          forum_prod_name_id: fpn.id,
          rev_date: rev_date,
          author: author,
          location: location,
          rating: rating,
          content: content,
          strengths: strengths,
          weaknesses: weaknesses,
          uniqueKey: Utils.unique_key(content),
          created_at: Time.now
        )
        puts "inserted review at #{rev_date.to_s}"
        $review_count += 1
      rescue ActiveRecord::RecordNotUnique => e
        puts "record already exists"
      end
    end
  
    next_anchor = doc.at_css("a[class='next_page']")
    unless next_anchor.nil?
      next_link = ROOT + next_anchor[:href]
      puts next_link
      build_reviews(next_link)
    end
  rescue Exception => e
    puts "error processing reviews"
    puts e.message
    puts e.backtrace.inspect
  end

end

links = IO.readlines("links_list.txt")
links.each do |link| 
  build_reviews(link)
end

puts "inserted #{$review_count} reviews"