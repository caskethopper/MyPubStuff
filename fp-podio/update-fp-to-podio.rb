#copying from fp-pod to get it started
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
  include Podio

  def podStringToDate(dt)
    if dt.is_a? String
      dstring = DateTime.parse(dt)
      return dstring
    end
  end

  def podDateToString(dt)
    date_string = dt.strftime("%Y-%m-%d %H:%M:%S")
    return date_string
  end

#This is just a quick function to update a service request in Podio
  def podUpdate(id, update_hash)
    puts "PODIO ITEM UPDATE CALL"
    convert = Hash.new
    convert["fields"] = update_hash
    #h_string = "{\"fields\" : "
       # h_string << "#{k} => #{v}"
      #end
    #puts h_string 
#    Podio::Item.update(id, {:fields => "#{update_hash}"})
      response = Podio.connection.put do |req|
        req.url "/item/#{id}/"
        req.body = convert.to_json
        puts req.body
      end

    #Podio::Item.update(id, {:fields => {"#{h_string}"}})
  end

  def podSync(fpdate, id, issue)
#get all fields from podio into hash
    puts "PODIO GET ITEM CALL"
    begin
      response = Podio.connection.get("/item/#{id}/value/v2")
    podhash = response.body
    pdt = podhash["date"]["start"]
 #####   if self.podStringToDate(pdt) < fpdate
    case issue["status"]
    when "Open"
      statuscat = 1
    when "Closed"
      statuscat = 2
    when "Awaiting Internal Response"
      statuscat = 3
    when "Awaiting Customer Response"
      statuscat = 4
    when "Escalated"
      statuscat = 5
    when "Re-Escalated"
      statuscat = 6
    when "Escalation III"
      statuscat = 6
    when "Scheduled"
      statuscat = 7
    when "Working With Vendor"
      statuscat = 8
    when "_DELETED_"
      statuscat = 10
    when "Previously Closed"
      statuscat = 11
   else
      statuscat = 9
      puts issue
   end

   update_hash = Hash.new
#case statement iterating across issue keys/vals
#might be a better way to do it, but this is working for now
      issue.each do |key, val|
        case key
        when "submitter"
          if podhash["submitted-by"] != val
            update_hash["submitted-by"] = val
#            self.podUpdate(id, "submitted-by", val)
          end
        when "phone"
          if podhash["phone"] != val
            update_hash["phone"] = val
            #self.podUpdate(id, "phone", val)
          end
        when "priority"
          if podhash["priority"] != val
            update_hash["priority"] = val
            #self.podUpdate(id, "priority", val)
          end
        when "email"
          if podhash["email-address"] != val
            update_hash["email-address"] = val
            #self.podUpdate(id, "email-address", val)
          end
        when "dept"
          if podhash["department"] != val
            update_hash["department"] = val
            #self.podUpdate(id, "department", val)
          end
        when "status"
          if podhash["category"]["id"] != statuscat
            update_hash["category"] = statuscat
            #self.podUpdate(id, "category", statuscat)
          end
        when "location"
          if podhash["location"] != val
            update_hash["location"] = val
            #self.podUpdate(id, "location", val)
          end
        when "allass"
          if podhash["all-assignees"] != val
            update_hash["all-assignees"] = val
            #self.podUpdate(id, "all-assignees", val)
          end
#        when "due"
#          if podhash["sla-due-date-2"] != val
#            update_hash["sla-due-date-2"] = val
#            #self.podUpdate(id, "sla-due-date-2", val)
#          end
        when "desc"
          if podhash["description"] != val
            update_hash["description"] = val
            #self.podUpdate(id, "description", val)
          end
        when "internal"
          if podhash["internal"] != val
            update_hash["internal"] = val
            #self.podUpdate(id, "internal", val)
          end
        when "lastdate"
          if podhash["date"] != val
            update_hash["date"] = val
            #self.podUpdate(id, "date", val)
          end
        end
      
      end
      unless update_hash.empty?
        self.podUpdate(id.to_i, update_hash)
      end
    rescue => e
      puts e
    end
 
 ######  else
   ######   puts "Already Updated"
   ##### end
  end

  def podcompare(id,fpdate)
    puts "PODCOMPARE CALL, SHOULD BE REMOVED"
    response = Podio.connection.get("/item/#{id}/value/v2")
    podhash = response.body

    puts podhash["footprints-sr"]
    puts podhash["category"]

    pdt = podhash["date"]["start"]
    if self.podStringToDate(pdt) < fpdate
      return "update"
    else
      return "ignore"
    end

  end


  def getIssues
    puts "def getIssues"
    status_arr = ["Closed", "Open", "Awaiting Customer Response", "Awaiting Internal Response", "Escalated", "Escalation I", "Escalation II", "Escalation III", "Previously Closed", "Re-Escalated", "Scheduled", "Working With Vendor", "Await Approval", "Awaiting Parts"]
    pods = Array.new
    status_arr.each do |status|
#Deliverable.find_by_filter_values( Deliverable::APP_ID, { status2: [2], last_edit_on: {from: from, to: to} }, { limit: MAX_ITEMS, offset: offset})[:all]
#63311606  :filters => {6058630 => 6374}
        case status
        when "Open"
          statuscat = 1
        when "Closed"
          statuscat = 2
        when "Awaiting Internal Response"
          statuscat = 3
        when "Awaiting Customer Response"
          statuscat = 4
        when "Escalated"
          statuscat = 5
        when "Escalation III"
          statuscat = 6
        when "Scheduled"
          statuscat = 7
        when "Working With Vendor"
          statuscat = 8
       else
          statuscat = 9
       end


      puts "PODSEARCH BY STATUS CALL"
      podsrch = Podio::Item.find_by_filter_values(8168312, { "category" => statuscat}).all 
      podsrch.each do |stuff|
        att = stuff.attributes
          issue_hash = Hash.new
          item = stuff.attributes[:item_id]
          title = stuff.attributes[:title]
          fields = stuff.attributes[:fields]
          fpsr = nil
          srcat = 9
          fields.each do |field|
            if field["label"] == "Footprints SR#"
              fpsr = field["values"][0]["value"]
            elsif field["label"] == "Category"
              srcat = field["values"][0]["value"]["id"]
            end
          end
          issue_hash[item] = {
            :title  => title,
            :fpsr   => fpsr,
            :status => srcat
          }
          pods.push(issue_hash) 
#      entries = iterate.attributes
#      pod_ids.push(entries)
      end
    end
      return pods
  end

end

class Footprints

#footprints api outputs a lot of garbage.
#sanitize method checks to ensure the input data is not a hash (because
#footprints returns a hash for nil values) and not nil (because some values may
#be converted to nil in processing).
#It then utf-8 encodes and runs them through the encoding map I built for footprints
#Returns the sanitized value
  def sanitize(val)
    if val.is_a? Hash
      val = "NONE"
    elsif val.nil?
      val = "NONE"
    else
      val = val.encode('UTF-8')
      val = self.fixEncoding(val)
    end
    return val

  end

#Returns corrected value
  def fixEncoding(mystring)
    map = {
      "__b" => " ",
      "__a" => "'",
      "__q" => "\"",
      "__t" => "`",
      "__m" => "@",
      "__d" => ".",
      "__u" => "-",
      "__s" => ";",
      "__c" => ":",
      "__p" => ")",
      "__P" => "(",
      "__3" => "#",
      "__4" => "$",
      "__5" => "%",
      "__6" => "^",
      "__7" => "&",
      "__8" => "*",
      "__0" => "~",
      "__f" => "/",
      "__F" => "\\",
      "__Q" => "?",
      "__e" => "]",
      "__E" => "[",
      "__g" => ">",
      "__G" => "<",
      "__B" => "!",
      "__W" => "{",
      "__w" => "}",
      "__C" => "=",
      "__A" => "+",
      "__I" => "|",
      "__M" => ",",
      "_HISTORY_LINE_BREAK_" => "\n"
  }

    map.each do |wrong, right|
      mystring = mystring.gsub(/#{wrong}/, right)
    end

    return mystring

  end

  def getIssue(project_id, issue_id, fpu, fpp)
    url = "https://support.cpcc.edu/MRcgi/MRWebServices.pl"
    user = fpu
    pword = fpp
#Emery sorted out the soap envelope for me
#Thanks Chris
    data = "
       <SOAP-ENV:Envelope
         xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
         xmlns:namesp2=\"http://xml.apache.org/xml-soap\"
         xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
         xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\">
           <SOAP-ENV:Header/>
           <SOAP-ENV:Body>
             <namesp1:MRWebServices__getIssueDetails xmlns:namesp1=\"MRWebServices\">
               <user xsi:type=\"xsd:string\">#{user}</user>
               <password xsi:type=\"xsd:string\">#{pword}</password>
               <extrainfo xsi:type=\"xsd:string\"/>
               <projectnumber xsi:type=\"xsd:int\">#{project_id}</projectnumber>
               <mrid xsi:type=\"xsd:int\">#{issue_id}</mrid>
             </namesp1:MRWebServices__getIssueDetails>
           </SOAP-ENV:Body>
         </SOAP-ENV:Envelope>
                        "
    data8 = data.encode('UTF-8')
    headers = {
      "SOAPAction" => "MRWebServices#MRWebServices__getIssueDetails",
      "Content-Type" => 'text/xml; charset=utf-8',
      "Content-Length" => "%d {data8.length}"
      }

    req = HTTParty.post(url,
      :body => data8,
      :headers => headers
    )
#Returns a horribly mangled, nested xml doc
#I mapped the nori parsed hash in an example if necessary for review
    return req.body
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
      podsrlist[x] = hashmap
      x+=1
    end

    return podsrlist
  end



  def baseToHash(input)
    doc = Nokogiri::XML(input)
    doc.traverse do |node|
      begin
        if node.attribute_nodes.join == "xsd:base64Binary"
          plain = Base64.urlsafe_decode64(node.content)
          #plain = Nokogiri::XML(plain)
          plain = plain.encode(:xml => :text)
          input = input.sub(node.content, plain)
        end
      rescue Exception=>e
        puts e
      end
    end
    input = input.gsub(/base64Binary/, "string")
    parser = Nori.new
    myhash = parser.parse(input).to_hash
    return myhash
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
mo = MiscOps.new
mycr = mo.fetcher
email = mycr["pou"]
password = mycr["pop"]

I18n.enforce_available_locales = false
Podio.setup(:api_key => 'fptest', :api_secret => 'lFIv8iRtUTVVjLUF9EHFvnWAkC8LubzVnSe8aQXVaoC3me8HzRBCtzZV5tvdlJHM')
Podio.client.authenticate_with_credentials(email, password)

#init miscops and fetch cred
fp = Footprints.new
pi = MyPodio.new

ish_arr = mo.getIssueSR
ish_arr.each do |hashmap|
  issue = Hash.new
  podid = hashmap[:podid]
  fpid  = hashmap[:fpid]
  output = fp.getIssue(1, fpid.to_i, mycr["fpu"], mycr["fpp"])
  temp_hash = mo.baseToHash(output)
  foot_hash = temp_hash["SOAP_ENV:Envelope"]["SOAP_ENV:Body"]["namesp1:MRWebServices__getIssueDetailsResponse"]["return"]
  foot_hash.keys.each do |key|
    newkey = fp.fixEncoding(key)
    foot_hash[newkey] = foot_hash[key]
  end#foot hash do

  hashmap = { "priority"      => "priority",
              "Internal"      => "internal",
#                  "description"   => "desc",
              "assignees"     => "allass",
              "title"         => "subject",
              "mr"            => "sr",
              "Full Name"     => "submitter",
              "status"        => "status",
              "Email Address" => "email",
              "Office"        => "location",
              "SLA Due Data"  => "due",
              "Phone"         => "phone",
              "User ID"       => "uid",
             }

  hashmap.each do |from, to|
    fpval = foot_hash[from]
    fpval = fp.sanitize(fpval)
    issue[to] = fpval
  end#hashmap do

  fpdesc = foot_hash["allDescriptions"]["item"]
  if fpdesc.is_a? Hash
    d_string = "\n#{fpdesc["stamp"]} \n #{fpdesc["data"]}"
    issue["desc"] = d_string
  elsif fpdesc.is_a? Array
    desc_arr = Array.new
    fpdesc.each do |desc_hash|
      d_string = "\n#{desc_hash["stamp"]}\n#{desc_hash["data"]}\n"
      desc_arr.push(d_string)
    end#fpdesc do
    joined = desc_arr.join
    issue["desc"] = joined
  end#if fpdesc is?

  issue["lastdate"] = pi.podDateToString(foot_hash["lasttime"])
      #process = pi.podcompare(podsr, pi.podStringToDate(issue["lastdate"]))
      #if process == "ignore"
      #  puts "Issue #{issue["sr"]} already up to date"
      #elsif process == "update"
  puts "PODSYNC"
  pi.podSync(issue["lastdate"], podid, issue)
      #end

end

