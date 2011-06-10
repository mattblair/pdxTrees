//
//  TreePhoto.m
//  pdxTrees
//
//  Created by Matt Blair on 6/8/11.
//  Copyright 2011 Elsewise LLC. All rights reserved.
//

#import "TreePhoto.h"


@implementation TreePhoto

@synthesize thumbnailURL, photoURL, caption,credit;
@synthesize thumbnailData, photoData;
@synthesize thumbnailRequestCompleted, photoRequestCompleted;
@synthesize thumbnailRequestSucceeded, photoRequestSucceeded;

- (id)init {
    
    self = [super init];
    if (self) {

        // or status typedef
        
        thumbnailRequestCompleted = NO;
        photoRequestCompleted = NO;
        
        thumbnailRequestSucceeded = NO;
        photoRequestSucceeded = NO;
        
    }
    
    return self;
    
}

@end
