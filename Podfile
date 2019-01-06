# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'
# pod trunk push Theater.podspec --allow-warnings 

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

def testing_pods
    pod 'Quick', '~> 1.3.2'
    pod 'Nimble', '7.3.1'
end

target 'Theater' do
    pod 'Starscream', '~> 3.0.6'
end

target 'TheaterTests' do
    pod 'Starscream', '~> 3.0.6'
    testing_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
