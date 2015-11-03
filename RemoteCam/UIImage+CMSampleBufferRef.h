//
//  UIImage+CMSampleBufferRef.h
//  remotecamera
//
//  Created by Dario Lencina on 4/13/13.
//  Copyright (c) 2013 Dario Lencina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <CoreMedia/CoreMedia.h>

@interface UIImage (CMSampleBufferRef)
+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;
@end
