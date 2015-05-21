require 'htmlentities'
require 'nokogiri'
require 'active_support'
require 'active_support/deprecation'
require 'podio'
require 'net/http'
require 'faraday'
require 'httparty'
require 'active_record'
require 'nori'

class MyPodio
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

  def poditemcreate(issue)

    status = issue["status"]
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
   end

#Create a new podio issue in the indicated app
#Some fields are blanked due to issues
#Adding to do to fix them
    unless statuscat == 2 || statuscat == 10
     puts "NEW ITEM CALL"
     newitem = Podio::Item.create(8168312, {
       :fields => {
         :'title' => issue["subject"].encode("UTF-8"),
         :'footprints-sr' => issue["sr"],
         :'priority' => issue["priority"],
         :'category' => statuscat,
         :'submitted-by' => issue["submitter"].encode("UTF-8"),
         :'email-address' => issue["email"],
#      :'location' => issue[:location],
         :'phone' => issue["phone"],
#      :'department' => issue[:dept],
#      :'primary-assignment' => issue[:primary],
#        :'cc' => issue[:cc],
         :'all-assignees' => issue["allass"],
#        :'sla-due-date-2' => issue[:due],}
         :'description' => issue["desc"],
         :'internal' => issue["internal"],
         :'fp-link-2'  => issue["link"],
         :'date'     => issue["lastdate"]
         }
       }, { :external_id => issue["sr"] })
    puts "TESTING NEW ITEM (PODID)"
    puts newitem
    puts newitem.attributes[:item_id]
    return newitem.attributes[:item_id]
    end
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
      val = HTMLEntities.new.decode(val)
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

  def cssSearch(project_id, fpu, fpp)
    ret_array = Array.new
    ret_data = ""
    assignee_array = ["dtj7158e","tim.dobs","pkj8748e","kunal.patel","bab3990e","brooks.bevil","rma1688e","marcus.redlinger","mrd2893e","ryan.moore","fds4511e","daniel.forthman","cmc1933e","chad.campbell","Core__bSystems__band__bServices","Telecommunication"]
    assignee_array.each do |assignee|

        url = "https://support.cpcc.edu/MRcgi/MRWebServices.pl"
        user = fpu
        pword = fpp

        query = "select mrID from MASTER1 where mrASSIGNEES LIKE '%#{assignee}%' and mrSTATUS != 'Closed'"
#        query = "select * from MASTER#{dbnum} where mrUPDATEDATE LIKE '2014'"
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
                 <namesp1:MRWebServices__search xmlns:namesp1=\"MRWebServices\">
                   <user xsi:type=\"xsd:string\">#{user}</user>
                   <password xsi:type=\"xsd:string\">#{pword}</password>
                   <extrainfo xsi:type=\"xsd:string\"/>
                   <query xsi:type=\"xsd:string\">#{query}</query>
                 </namesp1:MRWebServices__search>
               </SOAP-ENV:Body>
            </SOAP-ENV:Envelope>
                        "
        data8 = data.encode('UTF-8')
        headers = {
          "SOAPAction" => "MRWebServices#MRWebServices__search",
          "Content-Type" => 'text/xml; charset=utf-8',
          "Content-Length" => "%d {data8.length}"
          }

        req = HTTParty.post(url,
          :body => data8,
          :headers => headers
        )
#Returns a horribly mangled, nested xml doc
#I mapped the nori parsed hash in an example if necessary for review
        ret_data << req.body
        ret_array.push(req.body)
    end

    #puts ret_data
    return ret_array
  end

  def getFp(project_id, issue_id, fpu, fpp)
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
  def fetcher
    f = File.open("/opt/cr.txt", "r")
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

  def xmlItems(xml_arr)
    ret_arr = Array.new

    xml_arr.each do |ass_list|
      doc = Nokogiri::XML(ass_list)
      items = doc.css("item")
      items.each do |item|
        ret_arr.push(item.text)
       end
    end
    ret_arr = ret_arr.uniq
    
    return ret_arr.sort
  end
  
  def srChecker(chk_arr)
    ret_arr = Array.new
    podsrlist = Array.new
    x = 0
    f = File.open("/home/mcc/podio-current-sr.list", "r")
    while !f.eof?
      line = f.readline
      fpid = line.split(':')[1]
      podsrlist[x] = fpid.to_i
      x+=1
    end
    chk_arr.each do |num|
      inum = num.to_i
      if podsrlist.include?(inum)
        puts "DELETING #{num} from chk_arr"
      else
        puts "#{num} not in podsrlist, adding to return array"
        ret_arr.push(num)
      end
    end
    return ret_arr
  end

  def txtUpdate(podid,srid,title)
    f = File.open("/home/mcc/podio-current-sr.list", "a")
    puts podid
    puts srid
    puts title
    f.puts "#{podid}:#{srid}:#{title}"
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
puts "getting all css and telco footprints sr numbers"
issues = fp.cssSearch(1, mycr["fpu"], mycr["fpp"])
puts "getting the sr number out of the xml"
srnums = mo.xmlItems(issues)
puts "checking against local text file"
newfpiss = mo.srChecker(srnums)
puts "debug output for new fp iss var"
puts "start loop creation of podio issues"
unless newfpiss.empty?
 newfpiss.each do |srid|
  pod_issue = Hash.new
  #puts srid
  puts "getting details for #{srid}"
  output = fp.getFp(1, srid, mycr["fpu"], mycr["fpp"])
  issue_hash = mo.baseToHash(output)
  issue_hash = issue_hash["SOAP_ENV:Envelope"]["SOAP_ENV:Body"]["namesp1:MRWebServices__getIssueDetailsResponse"]["return"]
  puts "fix encoding and sanitize keys"
  issue_hash.keys.each do |key|
    newkey = fp.fixEncoding(key)
    issue_hash[newkey] = issue_hash[key]
  end
  hashmap = { "priority"      => "priority",
              "Internal"      => "internal",
              #"description"   => "desc",
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

#Iterate over the keys defined in hashmap, sanitize, and push to the issue hash
#You know, I'm not really sure I even need separate hashes, unless it was just to reduce
#the size of the object passed to functions
  hashmap.each do |from, to|
    fpval = issue_hash[from]
    fpval = fp.sanitize(fpval)
    pod_issue[to] = fpval
  end

#Build a footprints quick url
  link = "https://support.cpcc.edu/MRcgi/MRlogin.pl?DL=#{pod_issue["sr"]}DA1"
  pod_issue["link"] = link
#Retrieve and parse the last edit time (UTC)
  pod_issue["lastdate"] = pi.podDateToString(issue_hash["lasttime"])

  fpdesc = issue_hash["allDescriptions"]["item"]
  if fpdesc.is_a? Hash
    d_string = "\n#{fpdesc["stamp"]} \n #{fpdesc["data"]}"
    pod_issue["desc"] = d_string
  elsif fpdesc.is_a? Array
    desc_arr = Array.new
    fpdesc.each do |desc_hash|
      d_string = "\n#{desc_hash["stamp"]}\n#{desc_hash["data"]}\n"
      desc_arr.push(d_string)
    end
    joined = desc_arr.join
    pod_issue["desc"] = joined
  end

  podid = pi.poditemcreate(pod_issue)
  unless podid.nil?
   mo.txtUpdate(podid, srid, pod_issue["subject"])
  end
 end
end
#puts "NOKOGIRI TRAVERSE"
#puts "-----------------------"


