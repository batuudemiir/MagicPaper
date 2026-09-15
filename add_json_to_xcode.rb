require 'xcodeproj'

project_path = 'MagicPaper.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'MagicPaper' }

# Find the group
offline_group = project.main_group.find_subpath(File.join('MagicPaper', 'templates', 'offline'), false)

if offline_group.nil?
  puts "Could not find offline group!"
  exit 1
end

new_files = [
  'space_discovery_001.json',
  'fantasy_magic_001.json',
  'hero_courage_001.json',
  'underwater_friendship_001.json'
]

new_files.each do |filename|
  # Add file reference to group if it doesn't exist
  file_ref = offline_group.files.find { |f| f.path == filename }
  if file_ref.nil?
    puts "Adding file ref for #{filename}"
    file_ref = offline_group.new_reference(filename)
  end
  
  # Add to Copy Bundle Resources phase
  resources_build_phase = target.resources_build_phase
  unless resources_build_phase.files_references.include?(file_ref)
    puts "Adding #{filename} to Copy Bundle Resources"
    resources_build_phase.add_file_reference(file_ref, true)
  end
end

project.save
puts "Successfully added files to Xcode project."
