require File.expand_path('../../config/environment', __FILE__)

if defined?(Redmine::Acts::Attachable::InstanceMethods)
  puts "Attachable module methods:"
  puts Redmine::Acts::Attachable::InstanceMethods.instance_methods(false).inspect
  puts "\nLocation of save_attachments:"
  puts Redmine::Acts::Attachable::InstanceMethods.instance_method(:save_attachments).source_location.inspect
else
  puts "Acts::Attachable not found."
end
