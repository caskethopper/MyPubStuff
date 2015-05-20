#!/usr/bin/env ruby
#Quick script to search folder for a friend

print "Enter the path to scan:"
mypath = gets.chomp

print "Enter name of file to hold output:"
outfile = gets.chomp

list = Dir.entries(mypath).sort

open(outfile, 'w') do |f|
  i = 0
  l = 0
  d = 0
  list.each do |payload|
    next if payload == '.' or payload == '..'
    i += 1
    if File.file?(payload) == true
      otype = "(file)"
      l += 1
    else
      otype = "(directory)"
      d += 1
    end
    f.puts "#{i}" + " " + payload + " " + otype 
  end
  f.puts "You have #{i} objects in " + mypath
  f.puts "Files:  #{l}"
  f.puts "Directories: #{d}"
  f.puts "poop a poo"
end
