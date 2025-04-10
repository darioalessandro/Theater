# pod trunk push Theater.podspec --allow-warnings

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.0'
use_frameworks!

target 'Theater' do
    pod 'Starscream', '~> 4.0.8'

    target 'TheaterTests' do
        inherit! :search_paths
        pod 'Quick', '~> 5.0.1'
        pod 'Nimble', '~> 9.2.1'
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Enable Mac Catalyst support for all pods
      config.build_settings['SUPPORTS_MACCATALYST'] = 'YES'
      config.build_settings['SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD'] = 'YES'
      
      # Configure Nimble with proper XCTest framework linking
      if target.name == 'Nimble'
        config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -framework XCTest'
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = '$(inherited) $(PLATFORM_DIR)/Developer/Library/Frameworks'
        config.build_settings['OTHER_LDFLAGS'] = config.build_settings['OTHER_LDFLAGS'].gsub('-lswiftXCTest', '')
      end
    end
  end
end
