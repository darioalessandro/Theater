# pod trunk push Theater.podspec --allow-warnings

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'Theater' do
    pod 'Starscream', '~> 3.0.6'

    target 'TheaterTests' do
        inherit! :search_paths
        pod 'Quick', '~> 1.3.2'
        pod 'Nimble', '8.1.2'
    end
end

#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#            config.build_settings['SWIFT_VERSION'] = '4.0'
#        end
#    end
#end
