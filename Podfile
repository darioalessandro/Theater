# pod trunk push Theater.podspec --allow-warnings

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.0'
use_frameworks!

target 'Theater' do
    pod 'Starscream', '~> 4.0.4'

    target 'TheaterTests' do
        inherit! :search_paths
        pod 'Quick', '~> 1.3.2'
        pod 'Nimble', '8.1.2'
    end
end
