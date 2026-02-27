require 'active_record'
require 'redmine'
require_relative 'app/models/testcase'

begin
  m = Testcase.instance_method(:save_attachments)
  puts "Method found!"
  puts "Location: #{m.source_location}"
  
  if m.source_location
    file_path = m.source_location[0]
    line_num = m.source_location[1]
    
    puts "\n--- Source Code ---"
    lines = File.readlines(file_path)
    start_idx = [0, line_num - 5].max
    end_idx = [lines.length - 1, line_num + 25].min
    puts lines[start_idx..end_idx].join
  end
rescue => e
  puts "Error: #{e.message}"
end
