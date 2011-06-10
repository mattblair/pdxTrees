//
//  TreePhoto.h
//  pdxTrees
//
//  Created by Matt Blair on 6/8/11.
//  Copyright 2011 Elsewise LLC. All rights reserved.
//

typedef enum EWAPhotoDownloadStatusType { 
    EWAPhotoDownloadUnrequested = 0,
    EWAPhotoDownloadFetching,
    EWAPhotoDownloadRequestSucceeded,
    EWAPhotoDownloadRequestFailed
} EWAPhotoDownloadStatusType;

#import <Foundation/Foundation.h>
#import "Tree.h"

@interface TreePhoto : NSObject {
    
    //Tree *theTree; // does each one need a tree reference?
    
    NSString *thumbnailURL;
    NSString *photoURL;

    NSString *caption;
    NSString *credit; //pending API update
    
    NSData *thumbnailData;
    NSData *photoData;
    
    // or instead of two BOOLs, use a type def that can handle the whole workflow?
    // Unrequested - > Fetching -> RequestSucceeded | RequestFailed 
    
    BOOL thumbnailRequestCompleted; 
    BOOL photoRequestCompleted;
    
    BOOL thumbnailRequestSucceeded; 
    BOOL photoRequestSucceeded;
        
}

//@property(nonatomic, retain) Tree *theTree;

@property(nonatomic, copy) NSString *thumbnailURL;
@property(nonatomic, copy) NSString *photoURL;

@property(nonatomic, copy) NSString *caption;
@property(nonatomic, copy) NSString *credit; //pending API update

@property(nonatomic, retain) NSData *thumbnailData;
@property(nonatomic, retain) NSData *photoData;

@property(nonatomic) BOOL thumbnailRequestCompleted;
@property(nonatomic) BOOL photoRequestCompleted;

@property(nonatomic) BOOL thumbnailRequestSucceeded; 
@property(nonatomic) BOOL photoRequestSucceeded;

@end
