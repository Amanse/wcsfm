require 'xcodeproj'

project_path = 'wcsfm.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Ensure the package reference is added to the project
package_url = 'https://github.com/sindresorhus/KeyboardShortcuts'

package_ref = project.root_object.package_references.find { |p| p.repositoryURL == package_url }
if package_ref.nil?
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = package_url
  package_ref.requirement = { "kind" => "upToNextMajorVersion", "minimumVersion" => "2.0.0" }
  project.root_object.package_references << package_ref
end

# Find the target
target = project.targets.first

# Add the package to the target's package product dependencies
product_name = 'KeyboardShortcuts'
dependency = target.package_product_dependencies.find { |d| d.product_name == product_name }
if dependency.nil?
  dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dependency.product_name = product_name
  dependency.package = package_ref
  target.package_product_dependencies << dependency
end

project.save
puts "Successfully added KeyboardShortcuts package dependency."
