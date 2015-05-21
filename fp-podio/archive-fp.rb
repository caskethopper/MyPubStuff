require 'net/smtp'
require 'json'
require 'mail'
require 'active_support'
require 'active_support/deprecation'
require 'nokogiri'
require 'podio'
require 'net/http'
require 'faraday'
require 'httparty'
require 'active_record'
require 'nori'

class MyPodio

  def moveToArchive(podfields,email,password)
    I18n.enforce_available_locales = false
    Podio.setup(:api_key => 'fparchive', :api_secret => 'JCzbsS0xC1ELKIBNGCVF8Sc8w9aYQKTUHUq9HoFUDMJUUTAgNoXcgynSRn4MFImz')
    Podio.client.authenticate_with_credentials(email, password)


    item = Hash.new
    item[:fields] = podfields
    puts item
    response = Podio.connection.post do |req|
      req.url "/item/app/8659710"
      req.body = item.to_json
    end


  end

  def getClosed
    closed_status = "Closed"
    statuscat = 2
    pods = Array.new
    puts "PODSEARCH BY STATUS CALL"
    podsrch = Podio::Item.find_by_filter_values(8168312, { "category" => statuscat}).all
    podsrch.each do |stuff|
      att = stuff.attributes
      podid = att[:item_id]
      pods.push(podid)
    end
    return pods
  end
end

class MiscOps

  def fetcher
    f = File.open("/home/mcc/cr.txt", "r")
    lines = f.readlines
    fpu = lines[0].chomp
    fpp = lines[1].chomp
    pou = lines[2].chomp
    pop = lines[3].chomp
    imu = lines[4].chomp
    imp = lines[5].chomp
    cr_hash = {
      "fpu" => fpu,
      "fpp" => fpp,
      "pou" => pou,
      "pop" => pop,
      "imu" => imu,
      "imp" => imp
    }

    return cr_hash
  end


end

class PodGet
  def getClosed


    closed_status = "Closed"
    statuscat = 2
    pods = Array.new
    #podhash = Hash.new
    puts "PODSEARCH BY STATUS CALL"
    podsrch = Podio::Item.find_by_filter_values(8168312, { "category" => statuscat}).all
    podsrch.each do |stuff|
      att = stuff.attributes
      #podid = att[:item_id]
      #podhash[podid] = att[fields]
      podfields = att[:fields]
      pods.push(podfields)
    end
    return pods
  end

  def getRefs(podid)

    puts "get ref for #{podid}"
    response = Podio.connection.get("/item/#{podid}/reference")
    puts "response gathered"
    puts response.body

  end
end
mo = MiscOps.new
mycr = mo.fetcher
email = mycr["pou"]
password = mycr["pop"]

    I18n.enforce_available_locales = false
    Podio.setup(:api_key => 'fptest', :api_secret => 'lFIv8iRtUTVVjLUF9EHFvnWAkC8LubzVnSe8aQXVaoC3me8HzRBCtzZV5tvdlJHM')
    Podio.client.authenticate_with_credentials(email, password)


pi = MyPodio.new
pg = PodGet.new


close_ids = pg.getClosed
close_ids.each do |pods|

  pi.moveToArchive(pods,email,password)
end
