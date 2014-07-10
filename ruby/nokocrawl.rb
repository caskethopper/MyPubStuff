require 'nokogiri'
require 'httparty'

class Crawler

  def get(uri)
    response = HTTParty.get("#{uri}")
    return response.body
  end

  def relative?(url)
    url.match(/^http/) ? false : true
  end

  def find_urls_on_page(parsed_url, current_url)
    urls_list = []
    begin
      parsed_url.search('a[@href]').map do |x|
        new_url = x['href'].split('#')[0]
        unless new_url == nil
          if relative?(new_url)
            new_url = make_absolute(current_url, new_url)
          end
          urls_list.push(new_url)
        end
      end
    rescue
      puts "could not find links"
    end
    urls_list
    puts "LIST = #{urls_list}"
  end

  def make_absolute(potential_base, relative_url)
    if relative_url.match(/^\//)
      create_absolute_url_from_base(potential_base, relative_url)
    else
      create_absolute_url_from_context(potential_base, relative_url)
    end
  end

  def create_absolute_url_from_base(potential_base, relative_url)
    remove_extra_paths(potential_base) + relative_url
  end

  def remove_extra_paths(potential_base)
    index_to_start_slash_search = potential_base.index('://')+3
    index_of_first_relevant_slash = potential_base.index('/', index_to_start_slash_search)
    if index_of_first_relevant_slash != nil
      return potential_base[0, index_of_first_relevant_slash]
    end
    potential_base
  end

  def create_absolute_url_from_context(potential_base, relative_url)
    if potential_base.match(/\/$/)
      absolute_url = potential_base+relative_url
    else
      last_index_of_slash = potential_base.rindex('/')
      if potential_base[last_index_of_slash-2, 2] == ':/'
        absolute_url = potential_base+'/'+relative_url
      else
        last_index_of_dot = potential_base.rindex('.')
        if last_index_of_dot < last_index_of_slash
          absolute_url = potential_base+'/'+relative_url
        else
          absolute_url = potential_base[0, last_index_of_slash+1] + relative_url
        end
      end
    end
    absolute_url
  end

  def process_page(html)
    doc = Nokogiri(html)
    images, list_image = process_images(doc)
    links = process_links(doc)
    css = process_css(doc)
    return doc, images, list_image, links, css
  end

  def process_images(doc)
    images = doc.css("img")
    list_images = doc.search("img").map { |img| img["src"] }
    return images, list_images

  end

  def process_links(doc)
    links = doc.css("a")
  end

  def process_css(doc)
   #find all css includes
   css = doc.search("[@type='text/css']")
  end

end

crawl = Crawler.new
url = "http://dubendorfer.biz"
#print "Enter root domain: "
#dom = gets.chomp
html = crawl.get(url)
doc, images, list_image, links, css = crawl.process_page(html)
puts links

doc.search('a[@href]').map do |x|
  new_url = x['href'].split('#')[0]
  unless new_url == nil
    if crawl.relative?(new_url)
      new_url = crawl.make_absolute(url, new_url)
    end
    #urls_list.push(new_url)
    puts new_url
  end
end


#puts "DOC"
#puts doc

#puts "IMAGES"
#puts images

#puts "IMAGE LIST"
#puts list_image

#puts "LINKS"
#puts links

#puts "CSS"
#puts css

