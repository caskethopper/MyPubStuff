require 'csv'
require 'fileutils'
require 'active_support'
require 'httparty'
require 'net/http'
require 'podio'
require 'rubygems'
require 'faraday'

class MyPodio
  def poditemcreate(issue)
    if issue["status"] = true
      statuscat = 1
    else
      statuscat = 2
    end

    if issue["projectname"].nil?
      project = "NONE"
    else
      project = issue["projectname"]
    end

    comm_arr = issue["comments"]
    rawcom = ""
    unless comm_arr.nil? || comm_arr.empty?
     comm_arr.each do |item|
      item.each do |k,v|
        rawcom << "#{v["commenter"]} said: #{v["text"]} \n"
      end
     end
    end
    title = issue["name"]
    owner = issue["owner"]
    package = issue["lpcontainer"]
    if issue["note"].nil?
      notes = "NONE"
    elsif issue["note"]["note"].length < 1
      notes = "NONE"
    else
      notes = issue["note"]["note"]
    end

    unless package.length > 0
      package = "NONE"
    end

    unless rawcom.length > 0
      rawcom = "No Comments"
    end
    checkstring = ""
    unless issue["check_items"].nil? || issue["check_items"].empty?
      issue["check_items"].each do |k,v|
        checkstring << "Name = #{v["assignee"]} : Item = #{v["description"]} : Status = #{v["status"]}"
      end
    end
    unless checkstring.length > 1
      checkstring = "NONE"
    end

    puts title
    puts statuscat
    puts owner
    puts package
    puts notes
    puts rawcom


    newitem = Podio::Item.create(8681969, {
      :fields => {
        :'title' => title,
        :'status' => statuscat,
        :'owner' => owner,
        :'package' => package,
        :'notes' => notes,
        :'comments-raw' => rawcom,
        :'project' => project,
        :'checklist-items' => checkstring
      }, })

  att = newitem.attributes
  id = att[:item_id]
  return id

  end

  def podupload(filename, ptid, dirmk)
      podfileid = nil
puts "FILENAME"
puts filename
puts "PTID"
puts ptid
puts "DIRMK"
puts dirmk

      File.open("#{dirmk}/#{filename}") do |upfile|
        response = Podio.client.connection.post do |req|
          req.options[:timeout] = 12000
          req.url "/file/v2/"
          req.headers['Content-Type'] = 'multipart/form-data'
          req.body = {:source => Faraday::UploadIO.new(upfile, nil, nil), :filename => "#{filename}"}
        end

        podbod = response.body
        podfileid = podbod['file_id']
puts "PODBOD"
puts podbod
        #podfileup = Podio::FileAttachment.upload(upfile, "#{name}")
        #podfileupbody = podfileup.body
        #podfileid = podfileupbody['file_id']
      end
puts "PODFILEID"
puts podfileid
      unless podfileid == nil
        Podio::FileAttachment.attach(podfileid, "item", ptid)
      end

      #unless Dir.exists?("./#{dirmk}")
      #  FileUtils.mkdir_p("./#{dirmk}")
      #end

      #FileUtils.mv("./#{filename}", "./#{dirmk}/#{filename}")
      puts "File Complete"


  end


end

class LiquidPlanner
  include HTTParty

  base_uri 'https://app.liquidplanner.com/api'
  format :json

  attr_accessor :workspace_id

  def initialize(email, password)
    @opts = { :basic_auth => { :username => email, :password => password },
              :headers => { 'content-type' => 'application/json' },
            }
  end

  def get(url, options={})
    self.class.get(url, options.merge(@opts))
  end

  def post(url, options={})
    options[:body] = options[:body].to_json if options[:body]
    self.class.post(url, options.merge(@opts))
  end

  def put(url, options={})
    options[:body] = options[:body].to_json if options[:body]
    self.class.put(url, options.merge(@opts))
  end

  def usermap(userid)
    userhash = {
      "274871" => "Brooks Bevil",
      "233968" => "Chad Campbell",
      "334889" => "Daniel Forthman",
      "251067" => "Jordyn Newton",
      "316021" => "Kunal Patel",
      "249526" => "Marcus Redlinger",
      "232565" => "Patrick Dugan",
      "286468" => "Ryan Moore",
      "249660" => "Tim Dobs",
      "334852" => "Christopher Walls",
      "274875" => "Jonathan Garrett",
      "280839" => "Justin Harwood",
      "256150" => "Matt Rubright",
      "273981" => "Tam Nguyen",
      "345272" => "Todd Henderson",
      "0"      => "Unassigned"
    }
    uname = userhash[userid]
    return uname
  end

  def workspaces
    get('/workspaces')
  end

  def filtertask(pid)
    get("/workspaces/#{workspace_id}/tasks?filter[]=project_id=#{pid}")
  end

  def tasks
    get("/workspaces/#{workspace_id}/tasks")
  end

  def getprojects
    get("/workspaces/#{workspace_id}/projects")
  end

  def projmap
    projinfo = self.getprojects
    phash = Hash.new
    projinfo.each do |project|
      key = project['id']
      value = project['name']
      phash[key] = value
    end
    return phash

  end

  def getleaves
    get("/workspaces/#{workspace_id}/treeitems?depth=1")
  end

  def walktree(contid)
    get("/workspaces/#{workspace_id}/treeitems/#{contid}?depth=-1&leaves=true")
  end

  def taskwass(tid)
    get("/workspaces/#{workspace_id}/tasks/#{tid}?include=checklist_items,comments,documents,links,note")
  end

  def down_file(tid, docid, fname, mydir)
    resp = get("/workspaces/#{workspace_id}/tasks/#{tid}/documents/#{docid}/download")
      open("#{mydir}/#{fname}", "wb") do |file|
        file.write(resp.body)
      end
    puts "Done."
  end

  def testnest(parent, child, hashname)
    if child['type'] == "Task"
      retid = child['id']
      retname = child['name']
      hashname[retid] = retname
    end

    child.each  do |key, value|
      if key == "children"
        value.each do |nest|
          testnest(child['name'],nest,hashname)
        end
      end
    end
  end
end


email = "chad.campbell@cpcc.edu"
password = "NOTAPASSWORD"
lp = LiquidPlanner.new(email, password)

workspaces = lp.workspaces

ws = workspaces.first
lp.workspace_id = ws['id']
    
leafhash = Hash.new
rootleaf = lp.getleaves
topleaves = rootleaf['children']
topleaves.each do |leaf|

  leafname =  leaf['name']
  leafid = leaf['id']
  leafhash[leafid] = leafname
end
selectedpkg = "7158998"
pkgtree = lp.walktree(selectedpkg)
nesthash = Hash.new
lp.testnest(nil, pkgtree, nesthash)

selectedpkg = "7158998"
pkgtree = lp.walktree(selectedpkg)
nesthash = Hash.new
lp.testnest(nil, pkgtree, nesthash)


fulltask = Array.new
nesthash.each do |key, value|
  fulltask.push(key)
end
fulltask.each do |tid|
  pod_item = Hash.new

  puts "Waiting a sec"
  sleep(1)
  tasks = lp.taskwass(tid)
  indtask = tasks

  compchk_hash = Hash.new
  inchk_hash = Hash.new
  checks = tasks['checklist_items']
  unless checks.nil?
    checks.each do |check|
      owner = check['owner_id']
      owner = owner.to_s
      owner = lp.usermap(owner)
      status = check['completed']
      desc = check['name']
      checkid = check['id']


      if check['completed']
        chkcomp = pod_item["check_items"]

        chkcomp["#{checkid}"] = {
            "description" => desc,
             "assignee"    => owner,
             "status"      => "complete"}
            
       else
        chkinc = pod_item["check_items"]
        chkinc["#{checkid}"] = {
             "description" => desc,
              "assignee"    => owner,
              "status"      => "incomplete"}
       end
     end
   end

  owner_id = indtask['owner_id']
  owner_id = owner_id.to_s
  pod_item["owner"] = lp.usermap(owner_id)

##
##
  if indtask['has_note'] == true
    pod_item["note"] = tasks["note"]
  end

  i = 1
  comm = tasks["comments"]
  comm_arr = Array.new
  comm.each do |things|
    temp_hash = Hash.new
    ptxt = things["plain_text"]
    comment_from = things["person_id"]
    comment_from = comment_from.to_s
    poo = lp.usermap(comment_from)
    index = "comment#{i}"
    temp_hash[index] = {
      "commenter" => poo,
      "text"      => ptxt
      }
     comm_arr.push(temp_hash)
     i+=1
  end

  unless comm_arr.empty?
    pod_item["comments"] = comm_arr
  end
## Check for documents and include
##
##     
      doc_hash = Hash.new

      docs = tasks["documents"]
      docs.each do |stuff|
        docid = stuff["id"]
        fname = stuff["file_name"]

        doc_hash = {
          docid.to_s => fname.to_s
        }
     end


    pod_item["status"] = indtask['is_done']
 #   if isdone == true
    pid = tasks['project_id']
    projectname = ""

    pmap = lp.projmap

    if pmap[pid].nil?
      pod_item["projectname"] = "No Project Defined"

    else
      pod_item["projectname"] = pmap[pid]
    end

=begin
    comarr = Array.new

    comment_hash.each do |index, comments|
      person = comments['commenter']
      output = comments['text']
#      comments.each do |comment| 
#        person = comment['commenter']
#        output = comment['text']
      comarr.push("#{person} said: #{output}")
#      end
    end



    tdesc = tasks['description']
=end
    pod_item["name"] = tasks['name']
    pod_item["packid"] = tasks['package_crumbs']
    parent = tasks['parent_ids']



=begin
    lpcontainer = ""
=end   
    parent.each do |rent|
      parhash = leafhash[rent]
        unless parhash.nil?
           pod_item["lpcontainer"] = parhash
         end
    end


=begin
    puts tasks
=end
I18n.enforce_available_locales = false
Podio.setup(:api_key => 'lp-archive', :api_secret => 'ZyjarWIYqqGH7R9E8bFqKUZXomvRrLJ6Gt6padgmXkgSauBcP1gAwHWhryUH7hxN')
Podio.client.authenticate_with_credentials(email, password)
pi = MyPodio.new
podtid = pi.poditemcreate(pod_item)

    lpcontainer = pod_item["lpcontainer"].gsub(%r{/}, '-')
    pname = pod_item["projectname"].gsub(%r{/}, '-')
    lastpath = pod_item["name"].gsub(%r{/}, '-')
    mydir = "./#{lpcontainer}/#{pname}/#{tid}-#{lastpath}"
    doc_hash.each do |id, name|
      unless Dir.exists?("#{mydir}")
        FileUtils.mkdir_p("#{mydir}")
      end

      lp.down_file("#{tid}", "#{id}", "#{name}", "#{mydir}")

      pi.podupload("#{name}", podtid, "#{mydir}")
    end


end

=begin

    pt = MyPodio.new

    newpodtask = pt.podcreate(tname, tid, int_note)
    podtid = newpodtask['task_id']

    pt.podassign(podtid, taskowner)

    unless comarr.nil?
      comarr.each do |comment|
        pt.podcomment(podtid, comment)
      end
    end
    lpcontainer = lpcontainer.gsub(%r{/}, '-')
    projectname = projectname.gsub(%r{/}, '-')
    tname = tname.gsub(%r{/}, '-')

    mydir = "./#{lpcontainer}/#{projectname}/#{tid}-#{tname}"
    puts mydir

    doc_hash.each do |id, name|
      lp.down_file("#{tid}", "#{id}", "#{name}")

      pt.podupload("#{name}", podtid, "#{mydir}")


    end


    unless compchk_hash.empty?
      CSV.open("#{tid}-completed_checklist.csv", "wb") do |csv|
        csv << ["assignee", "description", "status"]
        compchk_hash.each do |index, comphash|
          compass = comphash['assignee']
          compdesc = comphash['description']
          compstat = comphash['status']
          csv << [compass, compdesc, compstat]
        end
      end

      pt.podupload("#{tid}-completed_checklist.csv", podtid, "#{mydir}")
    end


    unless inchk_hash.empty?
      CSV.open("#{tid}-incomplete_checklist.csv", "wb") do |csv|
        csv << ["assignee", "description", "status"]
        inchk_hash.each do |index, comphash|
          compass = comphash['assignee']
          compdesc = comphash['description']
          compstat = comphash['status']
          csv << [compass, compdesc, compstat]
        end
      end

      pt.podupload("#{tid}-incomplete_checklist.csv", podtid, "#{mydir}")
    end


    if isdone == true
      pt.podcomplete(podtid)
    end
   end
















=end
