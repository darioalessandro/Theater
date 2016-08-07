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
    pod 'Quick', '~> 0.9.3'
    pod 'Nimble', '4.1.0'
end

target 'ActorsDemo' do
    pod 'Starscream', '~> 1.1.3'
    gallery
end

target 'RemoteCam' do
    gallery    
    pod 'Starscream', '~> 1.1.3'
end

target 'ActorsTests' do
    pod 'Starscream', '~> 1.1.3'
    testing_pods
    gallery    
end

target 'Theater' do
    pod 'Starscream', '~> 1.1.3'
end

target 'TheaterTests' do
    pod 'Starscream', '~> 1.1.3'
    testing_pods
end

