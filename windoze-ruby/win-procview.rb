require 'win32ole'
     ps = WIN32OLE.connect("winmgmts:\\\\.")
     ps.InstancesOf("win32_process").each do |p|
     puts "Process: #{p.name}"
     puts "\tID: #{p.processid}"
     puts "\tPATH:#{p.executablepath}"
     puts "\tTHREADS: #{p.threadcount}"
     puts "\tPRIORITY: #{p.priority}"
     puts "\tCMD_ARGS: #{p.commandline}"
   end