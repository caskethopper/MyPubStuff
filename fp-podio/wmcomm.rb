#copying from fp-pod to get it started
require 'net/smtp'
require 'active_support'
require 'active_support/deprecation'
require 'mail'
require 'nokogiri'
require 'podio'
require 'net/http'
require 'faraday'
require 'httparty'
require 'active_record'
require 'nori'


class MyPodio
  include Podio

  def getComments(id)
    comments = Array.new
    puts "Getting comments for #{id}"
    com_stream = Podio::Comment.find_all_for("item", id.to_s)
    watermark = 0
    com_stream.each do |comment|
      com_text = comment.attributes[:value]
      com_id   = comment.attributes[:comment_id]
      if com_text == "comments synced to footprints" && com_id > watermark
        watermark = com_id
        puts "ADDING WATERMARK #{watermark}"
      end
    end
    
    com_stream.each do |comment| 
      com_id   = comment.attributes[:comment_id]
      if com_id > watermark
        comments.push(comment.attributes)
      end
    end
    puts comments
    return comments
  end

  def waterMark(id)
    Podio::Comment.create("item", id, {:value => "comments synced to footprints"})

  end

#  def commDel(id)
    #Podio::Comment.delete(id)
#    puts "Can't delete other people's comments"
#  end

#  def commUpd(id)
#    Podio::Comment.update(id, {:value => "Testing update of user comments"})
#
#  end

#  def getIssues
#    status_arr = ["Open", "Awaiting Customer Response", "Awaiting Internal Response", "Escalated", "Escalation I", "Escalation II", "Escalation III", "Previously Closed", "Re-Escalated", "Scheduled", "Working With Vendor", "Await Approval", "Awaiting Parts"]
#    pods = Array.new
#    status_arr.each do |status|
#Deliverable.find_by_filter_values( Deliverable::APP_ID, { status2: [2], last_edit_on: {from: from, to: to} }, { limit: MAX_ITEMS, offset: offset})[:all]
#63311606  :filters => {6058630 => 6374}
#        case status
#        when "Open"
#          statuscat = 1
#        when "Closed"
#          statuscat = 2
#        when "Awaiting Internal Response"
#          statuscat = 3
#        when "Awaiting Customer Response"
#          statuscat = 4
#        when "Escalated"
#          statuscat = 5
#        when "Escalation III"
#          statuscat = 6
#        when "Scheduled"
#          statuscat = 7
#        when "Working With Vendor"
#          statuscat = 8
#       else
#          statuscat = 9
#       end
#
#      podsrch = Podio::Item.find_by_filter_values(8168312, { "category" => statuscat}).all 
    #return podsrch
#      podsrch.each do |stuff|
#        att = stuff.attributes
#        if att[:comment_count] > 0
#          issue_hash = Hash.new
#          item = stuff.attributes[:item_id]
#          title = stuff.attributes[:title]
#          fields = stuff.attributes[:fields]
#          fpsr = nil
#          fields.each do |field|
#            if field["label"] == "Footprints SR#"
#              fpsr = field["values"][0]["value"]
#            end
#          end
#          issue_hash[item] = {
#            :title => title,
#            :fpsr  => fpsr
#          }
#          pods.push(issue_hash) 
#        end
#      entries = iterate.attributes
#      pod_ids.push(entries)
#      end
#    end
#      return pods
#  end

end

class MyMail

  def msgSend(name,from,text,subject)
    opts = Hash.new
    opts[:server]      ||= 'posty.cpcc.edu'
    opts[:from]        ||= from
    opts[:from_alias]  ||= name
    opts[:subject]     ||= subject
    opts[:to]          ||= "CPCC-ITSHelpdesk@cpcc.edu"
    msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{opts[:to]}>
Subject: #{opts[:subject]}

#{text}
END_OF_MESSAGE
  #puts opts[:from]
  #puts opts[:to]
  #puts text
  Net::SMTP.start(opts[:server]) do |smtp|
    smtp.send_message msg, opts[:from], opts[:to]
  end
  end

end

class MiscOps

  def getIssueSR
    podsrlist = Array.new
    x = 0
    f = File.open("/home/mcc/podio-current-sr.list", "r")
    while !f.eof?
      map = f.readline
      hashmap = {
        :podid => map.split(':')[0],
        :fpid  => map.split(':')[1],
        :title => map.split(':')[2]
      }
      puts hashmap
      podsrlist[x] = hashmap
      x+=1
    end

    return podsrlist
  end

  def nameToEmail(name)
    prefix = name.split.join('.')
    mail = "#{prefix}@cpcc.edu"
    return mail

  end
#Fetcher to grab creds
#Need to set up SA's and maybe do something else to secure
#Returns credential hash
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


#init miscops and fetch cred
mo = MiscOps.new
mycr = mo.fetcher


email = mycr["pou"]
password = mycr["pop"]

comment_hash = Hash.new

#Could stand to be moved into the MyPodio class
#Maybe init?
I18n.enforce_available_locales = false
Podio.setup(:api_key => 'fptest', :api_secret => 'lFIv8iRtUTVVjLUF9EHFvnWAkC8LubzVnSe8aQXVaoC3me8HzRBCtzZV5tvdlJHM')
Podio.client.authenticate_with_credentials(email, password)

ml = MyMail.new
pi = MyPodio.new
#ish_arr = pi.getIssues
ish_arr = mo.getIssueSR
ish_arr.each do |hashmap|
   mycom = pi.getComments(hashmap[:podid])
   counter = 0
   mycom.each do |comm|
    com_id    = comm[:comment_id]
    com_val   = comm[:value]
    com_name  = comm[:created_by][:name]
    com_fpsr  = hashmap[:fpid]
    com_title = hashmap[:title]
    from      = mo.nameToEmail(com_name)
    subject   = "RE: #{com_title} ISSUE=#{com_fpsr} PROJ=1"
    if com_val.downcase.start_with? "internal:"
      text = com_val.sub(/[Ii][Nn][Tt][Ee][Rr][Nn][Aa][Ll]:/, '')
      body = "Internal=#{text}"
      ml.msgSend(com_name,from,body.gsub("\n", " "),subject)
#      pi.commDel(com_id)
#      pi.commUpd(com_id)
      counter = 1
    elsif com_val.downcase.start_with? "description:"
      text = com_val.sub(/[Dd][Ee][Ss][Cc][Rr][Ii][Pp][Tt][Ii][Oo][Nn]:/, '')
      ml.msgSend(com_name,from,text,subject)
#      pi.commDel(com_id)
#      pi.commUpd(com_id)
      counter = 1
    end

#    comment_hash[com_id] = {
#      :value => com_val,
#      :name => com_name,
#      :email => mo.nameToEmail(com_name)
#    }
   end

   if counter == 1
     pi.waterMark(hashmap[:podid])
   end
#  unless mycom.nil?
#    puts mycom.attributes
#  end
end
#comment_hash.each do |id, attributes|
#  comment = attributes[:value]
#  if comment.downcase.start_with? "internal:"
#do internal stuff

#  elsif comment.downcase.start_with? "description:"
#do description stuff

#  end
#end

