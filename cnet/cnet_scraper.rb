$LOAD_PATH << '..'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'cgi'

require 'utils'

$review_count = 0
FORUM_ID = 21
ROOT = "http://reviews.cnet.com"
CUT_OVER = Date.civil(2011,7,8)
$too_old = false


class ForumProductName < ActiveRecord::Base
end

class Review < ActiveRecord::Base
end

def determine_fpn(doc)
  prod_name = doc.at_css("title").text.sub(/User Reviews.+/,"").strip
  ForumProductName.find_by_name(prod_name)
end


def build_reviews(page_url)
  return if $too_old
  begin
    doc = Nokogiri::HTML(open(page_url))
    fpn = determine_fpn(doc)
    if fpn.nil?
      puts "FPN NIL at #{page_url}\n"
      return
    end
    reviews = doc.css(".rateSum")
    reviews.each do |review|
      date = review.at_css("time").text
      rev_date = Utils.build_date(date)
      if rev_date < CUT_OVER 
        $too_old = true
        break
      end
      rating = review.at_css(".stars").text.sub(/stars/,"").strip.to_f
      summary = review.at_css(".userRevTitle").text.gsub(/\"/, "").strip
      author_elt = review.at_css(".author")
      author = ""
      author = author_elt.text unless author_elt.nil?
      review_string = review.to_s
      pros = ""
      pros = $1.strip if review_string =~ /Pros.<\/strong>(.+?)<\/p>/sm
      pros.gsub!(/<[^>]+>/,"")
      cons = ""
      cons = $1.strip if review_string =~ /Cons.<\/strong>(.+?)<\/p>/sm
      cons.gsub!(/<[^>]+>/,"")
      content = ""
      content = $1.strip if review_string =~ /Summary.<\/strong>(.+?)<\/p>/sm
      content.gsub!(/<[^>]+>/,"")
      begin
        Review.create(
          forum_id: FORUM_ID,
          prod_id: fpn.prod_id,
          forum_prod_name_id: fpn.id,
          rev_date: rev_date,
          author: author,
          rating: rating,
          summary: summary,
          strengths: pros,
          weaknesses: cons,
          content: content,
          uniqueKey: Utils.unique_key(summary, content),
          created_at: Time.now        
        )
        puts "review added #{rev_date.to_s}"
        $review_count += 1
      rescue ActiveRecord::RecordNotUnique => e
        puts "record already exists"
      end
     
    end
    next_anchor = doc.at_css("a[class='nextButton']")
    unless $too_old || next_anchor.nil?
      next_link = next_anchor[:href]
      next_link.gsub!(/\s/, "%20")
      build_reviews(ROOT + next_link)
    end
  rescue Exception => e
    puts e.message
    puts page_url
    puts e.backtrace.inspect
  end
  
end


IO.readlines("links_list.txt").each do |link|
  $too_old = false
  build_reviews(link)
end

puts "scraped #{$review_count} reviews"

