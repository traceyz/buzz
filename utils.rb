require 'digest/md5'

module Utils
  
  ActiveRecord::Base.establish_connection(
    adapter: "mysql",
    host: "localhost",
    database: "boseBuzz",
    username: "root",
    password: "4124zell"
  )

  DUPLICATE_LIMIT = 3

  MONTHS = {
    "Jan" => 1,
    "Feb" => 2,
    "Mar" => 3,
    "Apr" => 4,
    "May" => 5,
    "Jun" => 6,
    "Jul" => 7,
    "Aug" => 8,
    "Sep" => 9,
    "Oct" => 10,
    "Nov" => 11,
    "Dec" => 12
  }

  #string1 would be a concatenation of material
  #can also work to combine two given strings
  def Utils.unique_key(string1, string2="")
    Digest::MD5.hexdigest(string1+string2)
  end
  
  # 12/20/2010
  def Utils.build_date3(str)
    array = str.split("/")
    yr = array[2].to_i
    mo = array[0].to_i
    day = array[1].to_i
    Date.civil(yr,mo,day)
  end
  
  def Utils.build_date2(str)
    array = str.split(/\s+/)
    yr = array[2].to_i
    mo = MONTHS[array[1]]
    d = array[0].to_i
    Date.civil(yr,mo,d)
  end

# Oct 20, 2011 or October 20, 2011
  def Utils.build_date(str)
    yr = year(str)
    mo = MONTHS[str[0..2]] #already an integer
    d = day(str)
    begin
      Date.civil(yr.to_i,mo,d.to_i)
    rescue => e
      puts "invalid date for  #{str}"
      return nil
    end
  end

  def Utils.day(str)
    str =~ /\s(\d+),/
    $1
  end

  def Utils.year(str)
    str =~ /(\d\d\d\d)/
    $1
  end

end