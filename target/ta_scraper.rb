$LOAD_PATH << '..'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'cgi'

require 'utils'

$review_count = 0
FORUM_ID = 24
ROOT = "http://www.target.com"
CUT_OVER = Date.civil(2011,8,12)


class ForumProductName < ActiveRecord::Base
end

class Review < ActiveRecord::Base
end

def determine_fpn(title)
  ForumProductName.find_by_name(title)
end

def build_reviews(page_url)
  begin
    reviews_page = Nokogiri::HTML(open(page_url))
    title = reviews_page.at_css("title").text.sub(/ : Target/,"")
    title.gsub!(/[^A-z0-9\s\-]/, "").strip!
    title = title.sub(/^Target/,"")
    fpn = determine_fpn(title)
    puts "FPN NIL for #{title}" if fpn.nil?
    return if fpn.nil?
    puts fpn.prod_id
    reviews = reviews_page.css(".review-content")
    puts "page has #{reviews.size} reviews"
    reviews.each do |review|
      puts "\nREVIEW"
      summary = review.at_css(".review-title").text.strip
      date = review.at_css(".review-date").text.strip
      rev_date = Utils.build_date(date)
      next if rev_date < CUT_OVER
      author = review.at_css(".reviewer-info").text.strip
      cite = review.at_css("cite")
      unless cite.nil?
        cite.text =~ /(\([^\)]+\))/
        location = $1
      end
      content = review.at_css(".review-text").text.strip
      #puts "*#{content}*"
      r = review.at_css(".ratings").text.strip
      rating = r[0].to_f
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
    next_anchor = reviews_page.at_css(".next")
    unless next_anchor.nil?
      next_link = next_anchor[:href]
      puts "NEXT LINK #{next_link}"
      build_reviews(ROOT + next_link)
    end
  rescue => e
    puts e.message
    puts e.backtrace.inspect
  end
end

IO.readlines("links_list.txt").each do |link|
  build_reviews(link)
end

puts "inserted #{$review_count} reviews"
