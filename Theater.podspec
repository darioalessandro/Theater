Pod::Spec.new do |s|
 
  s.name         = "Theater"
  s.version      = "0.1.4"
  s.summary      = "Swift framework to help write async, resilient and responsive applications."
 
  s.description  = <<-DESC
Writing async, resilient and responsive applications is too hard. 

In the case of iOS, is because we've been using the wrong abstraction level: NSOperationQueues, dispatch_semaphore_create, dispatch_semaphore_wait and other low level GCD functions and structures.

Using the Actor Model, we raise the abstraction level and provide a better platform to build correct concurrent and scalable applications.

Theater is Open Source and available under the Apache 2 License.

Theater is inspired by Akka.

Twitter = [@TheaterFwk](https://twitter.com/TheaterFwk)

### How to get started

- install via [CocoaPods](http://cocoapods.org)

```ruby
pod 'Theater'
```

Actors should subclass the Actor class:

```swift
  public class Dude : Actor {
```
In order to "listen" for messages, actors have to override the receive method:
```swift
  override public func receive(msg : Message) -> Void {

  }
```

In order to unwrap the message, you can use switch 

```swift
override public func receive(msg : Message) -> Void {
  switch (msg) {
    case let m as Hi:
      m.sender! ! Hello(sender: self.this)
    case is Hello:
      print("got Hello")
    default:
      print("what?")
  }
}
```

All messages must subclass Message:
```swift

public class Hi : Message {}
 
public class Hello : Message {}

```

Actors live inside an actor system, theater provides a default system

```swift
  let system : ActorSystem = AppActorSystem.shared
```

Putting in all together:

```swift
import Theater
 
public class Hi : Message {}
 
public class Hello : Message {}
 
public class Dude : Actor {
    override public func receive(msg : Message) -> Void {
        switch (msg) {
            case let m as Hi:
                m.sender! ! Hello(sender: self.this)
            case is Hello:
                print("got Hello")
            default:
                print("what?")
        }
    }
}

.
.
.
(inside the app delegate)

func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let system : ActorSystem = AppActorSystem.shared
        
        let dude1 = system.actorOf(Dude.self, name: "dude1")
        let dude2 = system.actorOf(Dude.self, name: "dude2")
        
        dude2 ! Hi(sender : dude1)
```

The output will be:
```swift
Tell = Optional("dude1") <Actors.Hi: 0x7bf951a0> dude2 
Tell = Optional("dude2") <Actors.Hello: 0x7be4bc00> dude1 
got Hello
```
                   DESC
 
  s.homepage     = "https://github.com/darioalessandro/Theater"
  s.screenshots  = "https://raw.githubusercontent.com/darioalessandro/Theater/master/theaterlogo.jpg"
  s.license      = { :type => "Apache2", :file => "License.txt" }
  s.author             = { "Dario Lencina" => "darioalessandrolencina@gmail.com" }
  s.social_media_url   = "https://twitter.com/theaterfwk"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/darioalessandro/Theater.git", :tag => s.version }
  s.source_files  = "Classes/*.swift"
  s.dependency  'Starscream', '~> 1.0.0'
 
end
