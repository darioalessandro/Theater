# Uncomment this line to define a global platform for your project
# pod trunk push Theater.podspec --allow-warnings 

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def testing_pods
    pod 'Quick', '~> 2.2.1'
    pod 'Nimble', '9.0.0-rc.3'
end

target 'Theater' do
    pod 'Starscream', '~> 4.0.4'
end

target 'TheaterTests' do
    pod 'Starscream', '~> 4.0.4'
    testing_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
        end
    end
end
