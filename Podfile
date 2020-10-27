ios_deployment_target = '10.0'

platform :ios, ios_deployment_target

target 'Store' do
	use_frameworks!
	
  pod 'SwiftyVK'
	pod 'R.swift.Library'
	pod 'R.swift'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      current = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      if current != nil && current.to_f < ios_deployment_target.to_f
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = ios_deployment_target
      end
    end
  end
  
  # This removes the warning about swift conversion, hopefuly forever!
  # discussion: https://github.com/CocoaPods/CocoaPods/issues/8674
  installer.pods_project.root_object.attributes['LastSwiftMigration'] = 99999
  installer.pods_project.root_object.attributes['LastSwiftUpdateCheck'] = 99999
  installer.pods_project.root_object.attributes['LastUpgradeCheck'] = 99999
  
  shared_data_dir = Xcodeproj::XCScheme.user_data_dir(installer.pods_project.path)
  Dir["#{shared_data_dir}/*.xcscheme"].each do |scheme_path|
    scheme = Xcodeproj::XCScheme.new scheme_path
    scheme.doc.root.attributes['LastUpgradeVersion'] = 99999
    scheme.save!
  end
end
