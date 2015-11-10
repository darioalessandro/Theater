//
//  DumpClassInfo.m
//  Actors
//
//  Created by Dario Lencina on 11/9/15.
//  Copyright © 2015 dario. All rights reserved.
//
#import "NSObject+DumpClassInfo.h"
#import <objc/runtime.h>

static void dumpClassInfo(Class c, int inheritanceDepth)
{
    Class superClass = class_getSuperclass(c);
    if (superClass != Nil)
    {
        dumpClassInfo(superClass, (inheritanceDepth + 1));
    }
    
    int i = 0;
    unsigned int mc = 0;
    
    const char* className = class_getName(c);
    
    Method* mlist = class_copyMethodList(c, &mc);
    for (i = 0; i < mc; i++)
    {
        Method method = mlist[i];
        SEL methodSelector = method_getName(method);
        const char* methodName = sel_getName(methodSelector);
        
        const char *typeEncodings = method_getTypeEncoding(method);
        
        char returnType[80];
        method_getReturnType(method, returnType, 80);
        
        NSLog(@"%2.2d %s ==> %s (%s)", inheritanceDepth, className, methodName, (typeEncodings == Nil) ? "" : typeEncodings);
        
        int ac = method_getNumberOfArguments(method);
        int a = 0;
        for (a = 0; a < ac; a++) {
            char argumentType[80];
            method_getArgumentType(method, a, argumentType, 80);
            NSLog(@"   Argument no #%d: %s", a, argumentType);
        }
    }
}

@implementation NSObject (DumpClassInfo)

- (void)dumpClassInfo
{
    Class c =  object_getClass(self);
    dumpClassInfo(c, 0);
}

@end