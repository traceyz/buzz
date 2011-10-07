puts "Enter report date: yyyy-mm-dd"

date = gets
date.chomp!
raise "#{date} is not valid" unless date.match(/^201[0-9]-[0-1][0-9]-[0-3][0-9]$/)
year, month, day = date.split('-')

`zip -r allBuzz_#{year}_#{month}_#{day}.zip boseBuzz`

f = File.open("index.html", "w")
f.puts "<html>"
f.puts "<head><title>Index</title></head>"
f.puts "<body>"
f.puts "<p>Follow the link to download the current Buzz Report.</p>"
f.puts "<a href=\"allBuzz_#{year}_#{month}_#{day}.zip\">allBuzz_#{year}_#{month}_#{day}.zip</a>"
f.puts "</body>"
f.puts "</html>"

f.close