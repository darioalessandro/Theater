Pod::Spec.new do |s|

  s.name          = "Theater"
  s.version       = "1.0"
  s.swift_version = "5"
  s.summary       = "A powerful Swift framework for building concurrent, resilient, and responsive applications using the Actor Model."
  s.description   = <<-DESC
Theater is a modern Swift framework that simplifies the development of concurrent, resilient, and responsive applications by leveraging the Actor Model pattern.

Traditional iOS development often relies on low-level concurrency primitives like OperationQueues, dispatch semaphores, and GCD functions, which can lead to complex and error-prone code. Theater elevates the abstraction level by implementing the Actor Model, providing a more intuitive and robust platform for building scalable concurrent applications.

Key Features:
- Actor-based concurrency model
- Message-passing communication
- Built-in actor system
- Simple and intuitive API
- Inspired by Akka's design patterns

Theater is open source and available under the Apache 2 License.

Connect with us:
- Email: [dario@securityunion.dev](mailto:dario@securityunion.dev)
- GitHub: [darioalessandro/Theater](https://github.com/darioalessandro/Theater)

### Quick Start

Install via CocoaPods:
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
  s.author             = { "Dario Lencina" => "dario@securityunion.dev" }
  s.social_media_url   = "https://twitter.com/theaterfwk"
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/darioalessandro/Theater.git", :tag => s.version }
  s.source_files  = "Classes/*.swift"
  s.dependency  'Starscream', '~> 4.0.8'
end
