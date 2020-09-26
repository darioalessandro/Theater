# pod trunk push Theater.podspec --allow-warnings

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'Theater' do
    pod 'Starscream', '~> 4.0.4'

    target 'TheaterTests' do
        inherit! :search_paths
        pod 'Quick', '~> 2.2.1'
        pod 'Nimble', '9.0.0-rc.3'
    end
end

#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#            config.build_settings['SWIFT_VERSION'] = '4.0'
#        end
#    end
#end
