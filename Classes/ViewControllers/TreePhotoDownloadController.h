//
//  TreePhotoDownloadController.h
//  pdxTrees
//
//  Created by Matt Blair on 6/8/11.
//  Copyright 2011 Elsewise LLC. All rights reserved.
//


// NOTE: I'm in the process of moving all the photo download details
// out of Tree Detail View Controller and Photo View Controller into this class, which will
// act as an image provider to those VCs and any others that might want to access image data.
// For now, it will be owned and managed by the TreeDetailViewController
//
// Among the reasons for the move:
// 1. Those View Controllers should focus on presentation not managing the 
// network requests, API specifics and image arrivals.
// 2. Consolidating the details in a single class makes it easer to adapt to API changes in the future.
// 3. Clearer separation of image fetching from presentation is also better for alternative 
//    presentations, e.g. an iPad layout in a Universal version in the future.
// 4. Storing arrived images as data until they are displayed should reduce the memory footprint.
// 5. This class could read from a local cache at some point, too.
//
// This class simply fetches, holds and hands out chunks of data the should represent photos.
// It makes no promises about the validity of the image. The presenting view should check image validity.
//
 
#import <Foundation/Foundation.h>
#import "Tree.h"
#import "TreePhoto.h"
#import "RESTConstants.h"

@class ASIHTTPRequest;
@class ASINetworkQueue;

// Notification Constants
extern NSString * const kPDCDidLoseInternetConnectionNotification;
extern NSString * const kPDCDidUpdatePhotoCountNotification;  // or change to specific DidQuitWithNoImages?
extern NSString * const kPDCDidReceiveThumbnailNotification;

// possible, but might not be needed:
extern NSString * const kPDCDidReceivePhotoNotification;
extern NSString * const kPDCDidRequestListNotification; //so TDVC could update UI?
 


@interface TreePhotoDownloadController : NSObject {
    
    Tree *theTree;
    
    NSUInteger thumbnailPrefetchCount;
    NSUInteger photoPrefetchCount;
    
    NSString *nullThumbnailPath;
    NSString *nullPhotoPath;
    
    NSMutableArray *treePhotoArray;
    
    // delete if you don't implement these...
    BOOL prefetching;
    BOOL fetching;
    
    ASIHTTPRequest *photoListRequest;
	ASINetworkQueue *photoRequestQueue;
    
}

@property(nonatomic, retain) Tree *theTree;

@property(nonatomic) BOOL imagesAvailable; // probably ditch

@property(nonatomic, getter = isPrefetching) BOOL prefetching;
@property(nonatomic, getter = isFetching) BOOL fetching;

@property(nonatomic) NSUInteger thumbnailPrefetchCount;
@property(nonatomic) NSUInteger photoPrefetchCount;

@property(retain) ASIHTTPRequest *photoListRequest;
@property(retain) ASINetworkQueue *photoRequestQueue;

@property(nonatomic, retain) NSMutableArray *treePhotoArray;

- (id)initWithTree:(Tree *)tree;

- (NSUInteger)count;

- (void)prefetch; // or have outsiders call requestPhoto List directly?

- (void)fetchRemainingPhotos;

- (void)reset; // rename to something else? Is this even necessary, or just do it all in dealloc?

- (NSData *)thumbnailDataForIndex:(NSUInteger)index;

- (TreePhoto *)treePhotoForIndex:(NSUInteger)index;

// should be in m file:

- (void)requestPhotoList;


@end
