//: Playground - noun: a place where people can play

import Cocoa

protocol Base {

}

struct Child: Base {
    let b: Int
    let c: Int

    func sayHi() -> Void {
        print("hi")
    }
}

struct Child2: Base {
}

let c = Child(b: 5, c: 4)

switch c {
//    case let b as Base :
//        print("Base \(b)")
case let b as Child:
    print("child \(b)")
    b.sayHi()


}