require 'xcodeproj'

project_path = 'wcsfm.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Group for the files
group = project.main_group.find_subpath('wcsfm', false)

# Files to add
files_to_add = [
  'ClipboardItem.swift',
  'ClipboardMonitor.swift',
  'SettingsView.swift',
  'HistoryView.swift',
  'HistoryWindowManager.swift',
  'WindowEffectView.swift'
]

files_to_add.each do |file_name|
  unless group.files.any? { |f| f.path == file_name }
    file_ref = group.new_file(file_name)
    target.add_file_references([file_ref])
  end
end

project.save
puts "Successfully updated project files."
