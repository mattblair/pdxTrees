//
//  TreePhotoDownloadController.m
//  pdxTrees
//
//  Created by Matt Blair on 6/8/11.
//  Copyright 2011 Elsewise LLC. All rights reserved.
//

#import "TreePhotoDownloadController.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "Reachability.h"
#import "NSString+SBJSON.h"
#import "RESTConstants.h"



NSString * const kPDCDidLoseInternetConnectionNotification = @"PDCDidLoseInternetConnection";
NSString * const kPDCDidUpdatePhotoCountNotification = @"PDCDidUpdatePhotoCountNotification";
NSString * const kPDCDidReceiveThumbnailNotification = @"PDCDidReceiveThumbnailNotification";

// might not use these
NSString * const kPDCDidReceivePhotoNotification = @"PDCDidReceivePhotoNotification";
NSString * const kPDCDidRequestListNotification = @"PDCDidRequestListNotification";



@implementation TreePhotoDownloadController

@synthesize theTree;
@synthesize thumbnailPrefetchCount, photoPrefetchCount;
@synthesize prefetching, fetching;
@synthesize photoListRequest, photoRequestQueue;
@synthesize treePhotoArray;

#pragma mark - Object Lifecycle

- (id)initWithTree:(Tree *)tree {
    self = [super init];
    if (self) {
        
        theTree = tree;
        
        // Set defaults
        thumbnailPrefetchCount = 4;
        photoPrefetchCount = 2;
        
        prefetching = NO;
        fetching = NO;
        
        // determine locations of these one time? Does this make sense?
        
        nullThumbnailPath = [[NSBundle mainBundle] pathForResource:kNullThumbnailFilename ofType:@"jpg"];
        
        nullPhotoPath = [[NSBundle mainBundle] pathForResource:kNullPhotoFilename ofType:@"jpg"];
        
    }
    
    return self;
    
}

- (void)reset {
    
    // prepare for release, if needed
    // I think you can do everything in dealloc, though you might want to call killQueue here?
    
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // call killQueue here?
    
    [theTree release];
    
    [nullThumbnailPath release];
    [nullPhotoPath release];
    
    [photoListRequest release];
    [photoRequestQueue release];
    
    [treePhotoArray release];
        
    [super dealloc];
}

#pragma mark - Fetching the Images

- (void)prefetch { 
    
    // If you don't need to do anything else here, 
    // just have other objects call requestPhotoList directly
    [self requestPhotoList];
    
}

- (void)fetchRemainingPhotos {
    
    // check to see if there are more photos
    if ([self count] > photoPrefetchCount) {
    
        // wasteful to cancel? But what if last one arrives and queue closes while we're preparing more requests?
        //[self.photoRequestQueue cancelAllOperations];
    
        // shouldn't need this, because I'm not setting it to nil until dealloc
        /*
        if (!self.photoRequestQueue) {
            // re-init it
        }
        */
        
        NSUInteger treeIndex = 0;
        
        for (TreePhoto *theTreePhoto in self.treePhotoArray) {
            
            // skip over the ones that already have requests
            if (treeIndex >= photoPrefetchCount) {
                
                // should check for photoRequestSucceeded = NO before creating
                
                NSURL *url = nil;
                ASIHTTPRequest *request = nil;
                
                url = [NSURL URLWithString:[theTreePhoto photoURL]];
                //NSLog(@"Requesting: %@", url);
                request = [ASIHTTPRequest requestWithURL:url];
                [request setDelegate:self];
                request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"iphonescreen", @"requestType", 
                                    [NSNumber numberWithInt:treeIndex], @"index", 
                                    nil];
                [request setDidFinishSelector:@selector(photoRequestFinished:)];
                [request setDidFailSelector:@selector(photoRequestFailed:)];
                [self.photoRequestQueue addOperation:request];
                
            }
            
            treeIndex++;
            
        }
        
        // docs say you don't need to call go again, but what if it has finished?
        // is there a way to check whether queue is active? It works in sim
        
        self.fetching = YES;
    }
    
    else {
        
        NSLog(@"All available photos requested during prefetch phase");
        
        self.fetching = NO;
        
    }
    
    
}

#pragma mark - Accessors

- (NSUInteger)count {
    
    if (treePhotoArray) {
        return [treePhotoArray count];
    }
    else {
        return 0;
    }
    
}

- (NSData *)thumbnailDataForIndex:(NSUInteger)index {
    
    if (index < self.treePhotoArray.count) {
        
        // check to see if it has arrived yet
        TreePhoto *theTreePhoto = [self.treePhotoArray objectAtIndex:index];
        
        if (theTreePhoto.thumbnailRequestSucceeded) {
            return theTreePhoto.thumbnailData;
        }
        else {
            
            NSData *thumbData = [NSData dataWithContentsOfFile:nullThumbnailPath];
            return thumbData;
            
        }
    }
    else {
        
        return nil;
        
    }
    
    
}

- (TreePhoto *)treePhotoForIndex:(NSUInteger)index {
    
    if (index < self.treePhotoArray.count) {
        
        TreePhoto *requestedTreePhoto = [self.treePhotoArray objectAtIndex:index];
        
        // should inject placeholder data if images aren't here yet
        
        if (!requestedTreePhoto.photoRequestSucceeded) {
            requestedTreePhoto.photoData = [NSData dataWithContentsOfFile:nullPhotoPath];
        }
        
        if (!requestedTreePhoto.thumbnailRequestSucceeded) {
            requestedTreePhoto.thumbnailData = [NSData dataWithContentsOfFile:nullThumbnailPath];
        }
        
        return requestedTreePhoto;
        
    }
    else {
        
        return nil;
        
    }
    
}


#pragma mark - Network Requests and Callbacks

- (void)requestPhotoList {
    
    // Check Reachability first
    
    NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    /*
     enum {
     
     // Apple NetworkStatus Constant Names.
     NotReachable     = kNotReachable,
     ReachableViaWiFi = kReachableViaWiFi,
     ReachableViaWWAN = kReachableViaWWAN
     
     };
     */
    
    // log connectivity during testing
    /*
     if (status == ReachableViaWiFi) {
     // wifi connection
     NSLog(@"Image List Request: Wi-Fi is available.");
     }
     if (status == ReachableViaWWAN) {
     // wwan connection (could be GPRS, 2G or 3G)
     NSLog(@"Image List Request: Only network available is 2G or 3G");	
     }
     */
    
    if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
        
        self.prefetching = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(reachabilityChanged:) 
                                                     name:kReachabilityChangedNotification 
                                                   object:nil];
        
        NSLog(@"PDC: Internet Reachable. Preparing request for tree photos...");
        
        // send notification that request is starting so TDVC can upate UI?
        
        NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@%d/iphonescreen/", 
                               kAPIUsername,kAPIPassword,kAPIHostAndPath, 
                               [self.theTree.treeID integerValue]];
        
        NSLog(@"PDC: Generated Photo Request URL is: %@", urlString);
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        self.photoListRequest = [ASIHTTPRequest requestWithURL:url];
        
        [self.photoListRequest setDelegate:self];
        
        [self.photoListRequest setDidFinishSelector:@selector(photoListRequestFinished:)];
        
        [self.photoListRequest setDidFailSelector:@selector(photoListRequestFailed:)];
        
        [self.photoListRequest startAsynchronous];
        
    }
    else {
        // no connection
        NSLog(@"PDC: Image List Request won't be made because internet is not available.");
        
        // send notification for UI updates
        [[NSNotificationCenter defaultCenter] postNotificationName:kPDCDidLoseInternetConnectionNotification 
                                                            object:self];
    }
    
}

- (void)photoListRequestFinished:(ASIHTTPRequest *)request {
    
    NSString *responseString = [request responseString];
    
    // TESTING ONLY
    NSLog(@"The Image List Request HTTP Status code was: %d", [request responseStatusCode]);
	NSLog(@"The response for the Image List Request was: %@", responseString);
	
	if ([[responseString JSONValue] isKindOfClass:[NSArray class]]) {
        
		NSMutableArray *tempImageList = [[NSMutableArray alloc] init];
		
		[tempImageList addObjectsFromArray:[responseString JSONValue]];
		
		NSLog(@"Number of objects: %d", [tempImageList count]);
		
		if ([tempImageList count] > 0 ) { // does it send empty arrays?
			if ([[tempImageList objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
				
				NSLog(@"first dictionary item in temp tree image list: %@", [tempImageList objectAtIndex:0]);
				
                // With Django API, each image dictionary will look like:
                
                /*
                
                {
                    "related_tree_couch_id": "df5d405a5afaba4b77b89cfd7eebf305", 
                    "image": "http://pdxtrees.org/media/photologue/photos/cache/tree-20-2011-02-06-172906_iphonescreen.jpg", 
                    "date_submitted": "2011-02-06 17:22:52", 
                    "caption": "", 
                    "thumbnail_url": "http://pdxtrees.org/media/photologue/photos/cache/tree-20-2011-02-06-172906_iphonethumbnail.jpg", 
                    "related_tree_id": "20", 
                    "id": 177
                }

                */
				
                // send notification of photo count
                NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[tempImageList count]] 
                                                                     forKey:@"count"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kPDCDidUpdatePhotoCountNotification 
                                                                    object:self
                                                                  userInfo:infoDict];
                
				
                
                self.treePhotoArray = [[NSMutableArray alloc] initWithCapacity:[tempImageList count]];
                
                for (NSDictionary *imageDict in tempImageList) {
                    
                    // init a TreePhoto for each
                    
                    TreePhoto *newTreePhoto = nil;
                    
                    newTreePhoto = [[TreePhoto alloc] init];
                    
                    newTreePhoto.thumbnailURL = [imageDict valueForKey:@"thumbnail_url"];
                    newTreePhoto.photoURL = [imageDict valueForKey:@"image"];
                    newTreePhoto.caption = [imageDict valueForKey:@"caption"];
                    
                    // pending API availability
                    //newTreePhoto.credit = [imageDict valueForKey:@"credit"];
                    
                    [self.treePhotoArray addObject:newTreePhoto];
                                        
                    [newTreePhoto release];
                    
                }
				
                
				// init and populate the queue
                
                self.photoRequestQueue = [[ASINetworkQueue alloc] init];
                
				self.photoRequestQueue.delegate = self;
                
                [self.photoRequestQueue setQueueDidFinishSelector:@selector(queueFinished:)];
                
                // could consolidate this loop with enumeration above, 
                // but it seems logically cleaner to me to init TreePhoto objects, 
                // then create request queue -- and they are short loops.
				
                NSUInteger index = 0;
                
				for (TreePhoto *theTreePhoto in self.treePhotoArray) {
					
                    // conditionally create requests up to prefetch limits:
                    
                    if (index < self.photoPrefetchCount) {
                        
                        NSURL *url = nil;
                        ASIHTTPRequest *request = nil;
                        
                        url = [NSURL URLWithString:[theTreePhoto photoURL]];
                        //NSLog(@"Requesting: %@", url);
                        request = [ASIHTTPRequest requestWithURL:url];
                        [request setDelegate:self];
                        request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"iphonescreen", @"requestType", 
                                            [NSNumber numberWithInt:index], @"index", 
                                            nil];
                        [request setDidFinishSelector:@selector(photoRequestFinished:)];
                        [request setDidFailSelector:@selector(photoRequestFailed:)];
                        [self.photoRequestQueue addOperation:request];
                        
                    }
                    
                    if (index < self.thumbnailPrefetchCount) {
                        
                        NSURL *url = nil;
                        ASIHTTPRequest *request = nil;
                        
                        url = [NSURL URLWithString:[theTreePhoto thumbnailURL]];
                        //NSLog(@"Requesting: %@", url);
                        request = [ASIHTTPRequest requestWithURL:url];
                        [request setDelegate:self];
                        request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"thumbnail", @"requestType", 
                                            [NSNumber numberWithInt:index], @"index", 
                                            nil];
                        [request setDidFinishSelector:@selector(thumbnailRequestFinished:)];
                        [request setDidFailSelector:@selector(thumbnailRequestFailed:)];
                        [self.photoRequestQueue addOperation:request];
                    }
					
					index++;
					
                    // quit enumerating if we're above the max of the prefetch limits
					if (index > MAX(photoPrefetchCount, thumbnailPrefetchCount)) {
						break;
					}
				}
				
				NSLog(@"PDC: Starting photo queue");				
				[self.photoRequestQueue go];
				
			}
            else { // object 0 != dictionary
                
                NSLog(@"Object 0 is not a dictionary...should never happen...");
                
            }
		}
        
		else { // no images
            
            self.prefetching = NO;
            
            NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"count"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kPDCDidUpdatePhotoCountNotification 
                                                                object:self
                                                              userInfo:infoDict];
		}
		
		[tempImageList release];
        
	}

    self.photoListRequest = nil;
    
}


- (void)photoListRequestFailed:(ASIHTTPRequest *)request {
    
    // testing:
    NSError *error = [request error];
    NSLog(@"Image List Request HTTP Status code was: %d", [request responseStatusCode]);
    NSLog(@"Image List Request Error: %@", [error description]);			
    NSLog(@"Image List Request: Failure of request to: %@", [request url]);
    
    
    // reset self, including setting count to 0
    
    self.prefetching = NO;
    
    // notify that there will be no images    
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"count"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPDCDidUpdatePhotoCountNotification 
                                                        object:self
                                                      userInfo:infoDict];
    
    self.photoListRequest = nil;
    
}

-(void)thumbnailRequestFinished:(ASIHTTPRequest *)request {
    
	NSLog(@"PDC: Thumbnail request finished...");					
	NSLog(@"PDC Thumbnail request user info was: %@", [request userInfo]);
	
    NSUInteger thumbIndex = [[[request userInfo] objectForKey:@"index"] intValue];
    
    TreePhoto *relatedTreePhoto = [self.treePhotoArray objectAtIndex:thumbIndex];
    
    [relatedTreePhoto setThumbnailRequestCompleted:YES];
    
	//NSData *responseData = [request responseData];
	
	if ([request responseStatusCode] == 200) {  //response okay
		
        // add data to TreePhoto object
        [relatedTreePhoto setThumbnailData:[request responseData]];
        
        [relatedTreePhoto setThumbnailRequestSucceeded:YES];
		
		// send notification
        // include index, but not data. Let receivers request data if they actually want it.
        
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:thumbIndex] 
                                                             forKey:@"thumbnailIndex"];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:kPDCDidReceiveThumbnailNotification 
                                                            object:self
                                                          userInfo:infoDict];
		
	}
	else {  //bad response
		
		NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);
		
		NSLog(@"The data returned was %d bytes and looks like: %@", 
              [[request responseData] length], [request responseData]);
        
        // need to send notification? Or not needed?
		
	}
    
}

-(void)thumbnailRequestFailed:(ASIHTTPRequest *)request {
    
    NSLog(@"PDC: Thumbnail request failed...");					
	NSLog(@"PDC Thumbnail request user info was: %@", [request userInfo]);
	
    NSUInteger thumbIndex = [[[request userInfo] objectForKey:@"index"] intValue];
    
    TreePhoto *relatedTreePhoto = [self.treePhotoArray objectAtIndex:thumbIndex];
    
    [relatedTreePhoto setThumbnailRequestCompleted:YES];
    
}
  
-(void)photoRequestFinished:(ASIHTTPRequest *)request {
    
    // TESTING ONLY
    NSLog(@"PDC's queue has %d remaining requests.", [self.photoRequestQueue requestsCount]);
    
    NSUInteger photoIndex = [[[request userInfo] objectForKey:@"index"] intValue];
    
    TreePhoto *relatedTreePhoto = [self.treePhotoArray objectAtIndex:photoIndex];
    
    [relatedTreePhoto setPhotoRequestCompleted:YES];
    
    // set data property
    
    if ([request responseStatusCode] == 200) {  //response okay
		
        // add data to TreePhoto object
        [relatedTreePhoto setPhotoData:[request responseData]];
        [relatedTreePhoto setPhotoRequestSucceeded:YES];
		
        NSLog(@"PDC received photo #%d", photoIndex);
        
		// send notification?
		
	}
	else {  //bad response
		
		NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);
		
		NSLog(@"The data returned was %d bytes and looks like: %@", 
              [[request responseData] length], [request responseData]);
        
        // need to send notification? Or no?
        // if you use typedef to indicate current status, set that here
		
	}

    
}

-(void)photoRequestFailed:(ASIHTTPRequest *)request {
	
	NSError *error = [request error];

    NSUInteger photoIndex = [[[request userInfo] objectForKey:@"index"] intValue];
    
    TreePhoto *relatedTreePhoto = [self.treePhotoArray objectAtIndex:photoIndex];
    
    [relatedTreePhoto setPhotoRequestCompleted:YES];
    
    // if you use typedef to indicate current status, set that here
    
    // not an error, just an artifact of the way ASI handles cancellations
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {
		NSLog(@"PDC photoRequestFailed: Cancellation initiated by killQueue method");
        
	}
	else {
        
		NSLog(@"The Photo Request HTTP Status code was: %d", [request responseStatusCode]);
		NSLog(@"Photo request error: %@", [error description]);	
		NSLog(@"Photo request user info was: %@", [request userInfo]);
		NSLog(@"Failure of request to: %@", [request url]);

	}
	
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
	
    NSLog(@"Queue finished");
    
    // only set it to nil if the fetching phase is somplete
    /*
	if ([[self photoRequestQueue] requestsCount] == 0) {
		self.photoRequestQueue = nil;
	}
	*/
    self.prefetching = NO;
    self.fetching = NO;
    
	// notification to update UI?
	
}


- (void)killQueue {
	
	// to be called on loss of network availability or if owning object shuts it down
	
	if ([self.photoRequestQueue requestsCount] > 0 ) {
        [self.photoRequestQueue reset]; // was cancelAllOperations, but reset is more comprehensive
    }
	
	// so that the rest of the requests don't keep calling the failed methods
	self.photoRequestQueue = nil;
	
}

#pragma mark -
#pragma mark Reachability Handling

-(void)reachabilityChanged:(NSNotification* )note {
	
	Reachability *currentReach = [note object];
	
	NetworkStatus status = [currentReach currentReachabilityStatus];
	
	if (status == NotReachable) {  
		[self killQueue];
        
		// send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kPDCDidLoseInternetConnectionNotification 
                                                            object:self];
		
	}
	
}

@end
