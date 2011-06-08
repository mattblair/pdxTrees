//
//  PhotoViewController.h
//  pdxTrees
//
//  Created by Matt Blair on 10/2/10.
// 
//  Copyright (c) 2010 Elsewise LLC
// 
//  Source available under: 
// 
//  The MIT License
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// 
//  For more information: http://pdxtrees.org
//

#import <UIKit/UIKit.h>

@class ASIHTTPRequest;
@class ASINetworkQueue;
@class CaptionedImageView;


@interface PhotoViewController : UIViewController <UIScrollViewDelegate, MFMailComposeViewControllerDelegate> {

	// data
	NSMutableArray *treeImageList;	
	NSMutableArray *treeThumbnails;
	NSMutableArray *photoArray;
	NSMutableArray *treePhotosReceived;
	
	NSNumber *treeID;
	NSString *treeName;
    
    NSMutableSet *recycledPhotos;
    NSMutableSet *visiblePhotos;
	
	// UI
	
	UIScrollView *scrollView;
	UIPageControl *pageControl;
	
	// Control
	
	// To be used when changes originate from the UIPageControl
    BOOL pageControlUsed;
	
	NSInteger photoRequestedIndex; // for landing on a particular page
	
	// the request objects
	ASIHTTPRequest *flagRequest;
	ASINetworkQueue *imageRequestQueue;

}

// data

@property (nonatomic, retain) NSMutableArray *treeImageList;	
@property (nonatomic, retain) NSMutableArray *treeThumbnails;
@property (nonatomic, retain) NSMutableArray *photoArray;
@property (nonatomic, retain) NSMutableArray *treePhotosReceived;
@property (nonatomic, retain) NSNumber *treeID;
@property (nonatomic, copy) NSString *treeName;

@property (nonatomic) NSInteger photoRequestedIndex;

// UI
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;

@property(retain) ASIHTTPRequest *flagRequest;
@property(retain) ASINetworkQueue *imageRequestQueue;

- (IBAction)changePage:(id)sender;

- (void)updatePhotosForScrollViewPosition;
- (CaptionedImageView *)dequeueRecycledPhoto;
- (BOOL)isDisplayingPhotoForIndex:(NSUInteger)index;


- (void)flagPhotoByEmail;

- (void)killQueue;

@end
