Pod::Spec.new do |s|
 
  s.name         = "Theater"
  s.version      = "0.1"
  s.summary      = "Swift framework to help write async, resilient and responsive applications."
 
  s.description  = <<-DESC
                   Writing async, resilient and responsive applications is too hard. 

In the case of iOS, is because we've been using the wrong abstraction level: NSOperationQueues, dispatch_semaphore_create, dispatch_semaphore_wait and other low level GCD functions and structures.

Using the Actor Model, we raise the abstraction level and provide a better platform to build correct concurrent and scalable applications.

Theater is Open Source and available under the Apache 2 License.

Theater is inspired by Akka.
                   DESC
 
  s.homepage     = "https://github.com/darioalessandro/Theater"
  # s.screenshots  = "https://raw.githubusercontent.com/darioalessandro/Theater/master/theaterlogo.jpg"
  s.license      = { :type => "Apache2", :file => "License.txt" }
  s.author             = { "Dario Lencina" => "darioalessandrolencina@gmail.com" }
  s.social_media_url   = "https://twitter.com/theaterfwk"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/darioalessandro/Theater.git", :tag => s.version }
  s.source_files  = "Classes/*.swift"
  s.dependency  'Starscream', '~> 1.0.0'
 
end