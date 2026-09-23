require 'xcodeproj'

project_path = 'MagicPaper.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'MagicPaper' }

# Group path: MagicPaper/Screens/StoryReader/PageTurn
story_reader_group = project.main_group.find_subpath(File.join('MagicPaper', 'Screens', 'StoryReader'), false)

if story_reader_group.nil?
  puts "Could not find StoryReader group!"
  exit 1
end

page_turn_group = story_reader_group.find_subpath('PageTurn', false)
if page_turn_group.nil?
    puts "Creating PageTurn group"
    page_turn_group = story_reader_group.new_group('PageTurn', 'PageTurn')
end

new_files = [
  'MagicPaperPageTurnConfiguration.swift',
  'MagicPaperPageTurnState.swift',
  'MagicPaperPageTurnGesture.swift',
  'MagicPaperPageTurnRenderer.swift',
  'MagicPaperPageTurnContainer.swift'
]

new_files.each do |filename|
  # Add file reference to group if it doesn't exist
  file_ref = page_turn_group.files.find { |f| f.path == filename }
  if file_ref.nil?
    puts "Adding file ref for #{filename}"
    file_ref = page_turn_group.new_reference(filename)
  end
  
  # Add to Compile Sources phase
  sources_build_phase = target.source_build_phase
  unless sources_build_phase.files_references.include?(file_ref)
    puts "Adding #{filename} to Compile Sources"
    sources_build_phase.add_file_reference(file_ref, true)
  end
end

project.save
puts "Successfully added files to Xcode project."
