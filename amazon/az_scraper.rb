$LOAD_PATH << '..'

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'cgi'

require 'utils'


$review_count = 0
$duplicate_count = 0
FORUM_ID = 17


CUT_OVER = Date.civil(2011,7,10)

class ForumProductName < ActiveRecord::Base
end

class Review < ActiveRecord::Base
end

def build_reviews(url)
  
  begin
  
    doc = Nokogiri::HTML(open(url))
  rescue => e
    puts "unable to get document at #{url}"
    puts e.message
    return
  end

  title = doc.at_css("title").text.gsub(/[^A-z0-9\.\s]+/,"")
  product_name = title.gsub("Amazon.com Customer Reviews ", "")
  product_name.gsub!(/\s+/, " ")
  return if product_name =~ /remote|kit/i #link may not contain these phrases
  fpn = ForumProductName.find_by_name(product_name)
  if fpn.nil?
    puts "\tNIL FPN"
    puts product_name
    puts url
    return  
  end
  
  $duplicate_count = 0
  doc.css("table#productReviews tr td >  div").each do |review|
    break if $duplicate_count > Utils::DUPLICATE_LIMIT
    begin
      fails = []
      review_text = review.to_s
      
      date = Date.new.to_s
      if review_text =~ /<nobr>([A-z]+ \d{1,2}, \d{4})/
        date = $1
      else
        fails << "date"
      end
      rev_date = Utils.build_date(date)
      next if rev_date.nil?
      next if rev_date <= CUT_OVER
      r = review.at_css(".swSprite").content.scan(/^\d/)[0]
      rating = r.to_f
      if rating.nil?
        fails << "rating"
        rating = -1.0
      end

      content = review_text.gsub(/<div[^>]+>.+?<\/div>/m,"")
      content.gsub!(/<[^b][^>]+>/m,"")
      if content.nil?
        fails << "content"
        content = "EMPTY"
      end
      content.gsub!(/<[^>]+>/,"").strip!
      content = CGI.unescapeHTML(content)

      summary = "EMPTY"
      if review_text =~ /<b>([^<]+)<\/b>/
        summary = $1
      else
        fails << "summary"
      end
      summary = CGI.unescapeHTML(summary)
  
      author = "EMPTY"
      if review_text =~ /By&nbsp\;.+?>([^<]+)<\/span/m
        author = $1
      else
        fails << "author"
      end
      author = CGI.unescapeHTML(author)
 
      location = "NA"
      if review_text =~ /By&nbsp\;.+?>[^<]+<\/span><\/a>\s(\([^)]+\))/m
        location = $1
        location.gsub!(/[()]/,"")
      end
  
      if fails.length > 0
        puts "review failed"
        fails.each { |f| puts f}
        puts
      end
      begin
        Review.create!(
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
          created_at: Date.today
        )
        $review_count += 1
        puts "added review #{rev_date.to_s}"
      rescue ActiveRecord::RecordNotUnique => e
        $duplicate_count += 1
        puts "record already exists, duplicate count #{$duplicate_count}"
      end
      
    rescue Exception => e
      puts "ERROR processing reviews"
      puts url
      puts e.message
      puts e.backtrace.inspect
    end
  
  end

end


IO.readlines("links_list.txt").each do |link|
  link.strip!
  build_reviews(link) if link.length > 0
end

puts "inserted #{$review_count} reviews"



