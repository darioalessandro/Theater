# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'
# pod trunk push Theater.podspec --allow-warnings 

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'Starscream', '~> 1.0.0'

def testing_pods
    pod 'Quick', '~> 0.8.0'
    pod 'Nimble', '3.0.0'
end

target 'Actors' do

end

target 'ActorsTests' do
    testing_pods
end

target 'Theater' do

end

target 'TheaterTests' do
    testing_pods
end

