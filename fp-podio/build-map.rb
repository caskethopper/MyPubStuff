require 'active_support'
require 'active_support/deprecation'
require 'podio'


class MyPodio

  def getIssues
#    status_arr = ["Open", "Awaiting Customer Response", "Awaiting Internal Response", "Escalated", "Escalation I", "Escalation II", "Escalation III", "Previously Closed", "Re-Escalated", "Scheduled", "Working With Vendor", "Await Approval", "Awaiting Parts"]
    pods = Array.new
#    status_arr.each do |status|
#Deliverable.find_by_filter_values( Deliverable::APP_ID, { status2: [2], last_edit_on: {from: from, to: to} }, { limit: MAX_ITEMS, offset: offset})[:all]
#63311606  :filters => {6058630 => 6374}
#      case status
#      when "Open"
#        statuscat = 1
#      when "Closed"
#        statuscat = 2
#      when "Awaiting Internal Response"
#        statuscat = 3
#      when "Awaiting Customer Response"
#        statuscat = 4
#      when "Escalated"
#        statuscat = 5
#      when "Re-Escalated"
#        statuscat = 6
#      when "Escalation III"
#        statuscat = 6
#      when "Scheduled"
#        statuscat = 7
#      when "Working With Vendor"
#        statuscat = 8
#      when "_DELETED_"
#        statuscat = 10
#      when "Previously Closed"
#        statuscat = 11
#     else
#        statuscat = 9
#     end
    statuscat = 1
    until statuscat == 12 do
      podsrch = Podio::Item.find_by_filter_values(8168312, { "category" => statuscat}).all 
    #return podsrch
      podsrch.each do |stuff|
        att = stuff.attributes
          issue_hash = Hash.new
          item = stuff.attributes[:item_id]
          title = stuff.attributes[:title]
          fields = stuff.attributes[:fields]
          fpsr = nil
          fields.each do |field|
            if field["label"] == "Footprints SR#"
              fpsr = field["values"][0]["value"]
            end
          end
          issue_hash[item] = {
            :title => title,
            :fpsr  => fpsr
          }
          pods.push(issue_hash) 
#      entries = iterate.attributes
#      pod_ids.push(entries)
      end
    statuscat += 1
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

mo = MiscOps.new
mycr = mo.fetcher


email = mycr["pou"]
password = mycr["pop"]

I18n.enforce_available_locales = false
Podio.setup(:api_key => 'fptest', :api_secret => 'lFIv8iRtUTVVjLUF9EHFvnWAkC8LubzVnSe8aQXVaoC3me8HzRBCtzZV5tvdlJHM')
Podio.client.authenticate_with_credentials(email, password)

pi = MyPodio.new

issues = pi.getIssues
f = File.open("/home/mcc/podio-current-sr.list", "r+")
issues.each do |myhash|
  puts myhash
  myhash.each do |podid, fphash|
    f.puts "#{podid}:#{fphash[:fpsr]}:#{fphash[:title]}"
  end
end

