 require 'rio'
 require 'open-uri'
 require 'uri'

 unless ARGV[0] and ARGV[1]
     puts "You must specify an operation and URL."
     puts "USAGE: scrape.rb [page|images|links] <url to scrape>"
     exit
 end


 case ARGV[0]

 when "page"
     rio(ARGV[1]) > rio("#{URI.parse(ARGV[1].strip).host}.html")
     exit
 when "images"
     begin
         open(url, "User-Agent" => "Mozilla/4.0 (compatible; MSIE 5.5; Windows
 98)") do |source|
         source.each_line do |x|
             if x =~ /<img src="(.+.[jpeg|gif])"\s+/
                 name = $1.split('"').first

                 name = url + name if Pathname.new(name).absolute?
                     copy = name.split('/').last
                
                 File.open(copy, 'wb') do |f|
                     f.write(open(name).read)
                 end
             end
         end
     end
     rescue => e
         puts "An error occurred, please try again."
         puts e
     end
     exit
 when "links"
     links = File.open("links.txt","w+b")
     begin

        open(ARGV[1], "User-Agent" => "Mozilla/4.0 (compatible; MSIE 5.5; Windows
 98)") do |source|
             links.puts URI.extract(source, ['http', 'https'])
        end
     rescue => e
         puts "An error occurred, please try again."
         puts e
     end
     links.close
     exit
 else
     puts "You entered an invalid instruction, please try again."
     puts "USAGE: scrape.rb [page|images|links] <url to scrape>"
     exit
 end