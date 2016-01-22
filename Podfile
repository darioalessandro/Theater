# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'
# pod trunk push Theater.podspec --allow-warnings 

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

def gallery
    pod 'BFGallery' , :git => "https://github.com/darioalessandro/BlackFireGallery.git", :tag => "0.1.2"
end

def testing_pods
    pod 'Quick', '~> 0.8.0'
    pod 'Nimble', '3.0.0'
end

target 'Actors' do
    gallery
    pod 'Starscream', '~> 1.0.0'
end

target 'RemoteCam' do
    gallery    
    pod 'Starscream', '~> 1.0.0'
end

target 'ActorsTests' do
    testing_pods
    gallery    
end

target 'Theater' do
    pod 'Starscream', '~> 1.0.0'
end

target 'TheaterTests' do
    testing_pods
end

