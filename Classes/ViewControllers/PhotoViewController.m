//
//  PhotoViewController.m
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

#import <MessageUI/MessageUI.h>  // for email
#import "PhotoViewController.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "Reachability.h"
#import "TreeDetailViewController.h"
#import "RESTConstants.h"  // for access to URLs
#import "CaptionedImageView.h"

@interface PhotoViewController (PrivateMethods)

- (void)loadScrollViewWithPage:(int)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;

@end

@implementation PhotoViewController

@synthesize scrollView, pageControl, flagRequest, imageRequestQueue;
@synthesize treeImageList, treeThumbnails, photoArray, treePhotosReceived, treeID, treeName;
@synthesize photoRequestedIndex;


#pragma mark -
#pragma mark View Lifecycle
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	

	// start requests for images here, based on treeImageList

	// create request queue if it doesn't exist yet
	
	if (![self imageRequestQueue]) {
		[self setImageRequestQueue:[[[ASINetworkQueue alloc] init] autorelease]];
	}
	
	self.imageRequestQueue.delegate = self;
	
	NSUInteger photoIndex = 0;
	
	for (NSDictionary *treeImage in treeImageList) {
		
		// check treePhotosReceived
		
		BOOL photoReceived = [[[self treePhotosReceived] objectAtIndex:photoIndex] boolValue];
		
		/*
		if (photoReceived) {
			NSLog(@"Already have photo for index %d", photoIndex);
		}
		else {
			NSLog(@"Need to fetch photo for index %d", photoIndex);
		}
		*/

		
		if (!photoReceived) {  // request only those not received yet
			NSURL *url = nil;
			ASIHTTPRequest *request = nil;
			
			url = [NSURL URLWithString:[treeImage valueForKey:@"image"]];
			// NSLog(@"Requesting: %@", url);
			request = [ASIHTTPRequest requestWithURL:url];
			[request setDelegate:self];
			request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"iphonescreen", @"requestType", [NSNumber numberWithInt:photoIndex], @"index", nil];
			[request setDidFinishSelector:@selector(photoRequestFinished:)];
			[request setDidFailSelector:@selector(photoRequestFailed:)];
			[[self imageRequestQueue] addOperation:request];
		}
		

		
		photoIndex++;
		
		// Open this up in future versions, pending more intensive memory testing.
		if (photoIndex >= 6) {
			break;
		}
	}
	
	
	// only start the queue if there are actually images to fetch.
	if ([[self imageRequestQueue] requestsCount] > 0) {
		// start the queue
		// NSLog(@"Starting queue");				
		[[self imageRequestQueue] go];
	}
	

	
	
	
	// get count of photos
	NSUInteger pageCount = [[self photoArray] count];
    
    // sets to hold the views
    recycledPhotos = [[NSMutableSet alloc] init];
    visiblePhotos  = [[NSMutableSet alloc] init];

    
	// Configuring the scrollView
	
	// a page is the width of the scroll view
    scrollView.pagingEnabled = YES;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * pageCount, scrollView.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
    scrollView.delegate = self;
	
	pageControl.numberOfPages = pageCount;
    
    
    // pre-fetch images before and after requested photo
	
	/*
     // Load first two pages of scroll view
     
     [self loadScrollViewWithPage:0];
     [self loadScrollViewWithPage:1];
     */
    
    // if 0, function will return immediately on -1
    //[self updateScrollViewAtPage:self.photoRequestedIndex];
    
    self.pageControl.currentPage = self.photoRequestedIndex;
	
    // need to load images and scroll to the currentPage
    
    [self changePage:self];
     
	// add flag button and connect to its selector

	UIBarButtonItem *flagButton = [[UIBarButtonItem alloc] initWithTitle:@"Flag"  
																	style:UIBarButtonItemStyleBordered 
																   target:self
																   action:@selector(flagPhoto:)];
	
	self.navigationItem.rightBarButtonItem = flagButton;

    [flagButton release];
    
	self.navigationItem.title = [self treeName];
	
}


-(void)viewWillDisappear:(BOOL)animated {
	
    // 110505: this should go away once image load is handed off, right?
    
	// this gets called just after viewDidLoad, when the Captioned Image VC takes over, and again when the user taps back to return to TDVC
	// Only kill the queue when headed back to the TDVC

	NSLog(@"Photo VC viewWillDisappear: class of top view controller is %@", [[[self navigationController] topViewController] class]);
	
    /*
    
	if ([[[self navigationController] topViewController] isKindOfClass:[TreeDetailViewController class]]) {

		// check on the flag request
		
		if ([[self flagRequest] inProgress]) {
			
			[[self flagRequest] cancel];
		}
		
		// kill the queue
		
		// unintentional iambic pentameter log message needs a rhyming partner...
		// NSLog(@"About to make the call to kill the queue"); 
		[self killQueue];
		
	}
	*/
}

#pragma mark -
#pragma mark ScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // To prevent "feedback loop" between the UIPageControl and the scroll delegate
	
    if (pageControlUsed) {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    
    // these next two lines cause multiple events
    //int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    //self.pageControl.currentPage = page;
	
    // this borrows from PoEd Browse Controller to only call for update on actual change
    int newPage = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if ((newPage >= 0) && !(newPage == self.pageControl.currentPage)) {
        self.pageControl.currentPage = newPage;
        
        NSLog(@"scrolling triggering an update");
        [self updatePhotosForScrollViewPosition];
        
    }    
    
    /*
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
     
    */

}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

#pragma mark - Managing photos in Scroll View

// formerly known as - (void)loadScrollViewWithPage:(int)page
- (void)configurePhoto:(CaptionedImageView *)capView forIndex:(int)page { 
    
    // bounds check -- get rid of this and check elsewhere?
    if (page < 0) return;
    if (page >= [[self photoArray] count]) return;
    
    
    NSString *pageCaption = [[treeImageList objectAtIndex:page] objectForKey:@"caption"];
    
    capView.index = page;
    
    // page = index -- rename the argument in the method to make it clearer?
    [capView displayImage:[photoArray objectAtIndex:page] withCaption:pageCaption andCredit:@"TBD"];
    
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    capView.frame = frame;
        
}

- (void)updatePhotosForScrollViewPosition {  // this is like the tilePages method of PhotoScroller
    
    NSInteger page = self.pageControl.currentPage;
    

    int firstPhotoNeeded = page - 1;
    int lastPhotoNeeded = page + 1;
    
    // bounds handling from tilePages
    firstPhotoNeeded = MAX(firstPhotoNeeded, 0); // i.e. filter out negative
    lastPhotoNeeded  = MIN(lastPhotoNeeded, [[self photoArray] count] - 1);
    
    
    NSLog(@"Current views needed are indexes: %d %d %d", firstPhotoNeeded, page, lastPhotoNeeded);
    
    // loop through visible pages set: if index is < page -1 or > page + 1
    // add to recycled and remove from superview
    
    for (CaptionedImageView *capView in visiblePhotos) {
        
        
        
        if (capView.index < firstPhotoNeeded || capView.index > lastPhotoNeeded) {
            NSLog(@"capView index %d will be recycled", capView.index);
            [recycledPhotos addObject:capView];
            [capView removeFromSuperview];
        }
        else {
            NSLog(@"capView index %d WILL NOT BE recycled", capView.index);
        }
    }
    
    [visiblePhotos minusSet:recycledPhotos];
    
    NSLog(@"Visible v. Recycle Photo #'s: %d to %d", [visiblePhotos count], [recycledPhotos count]);
    
    for (int index = firstPhotoNeeded; index <= lastPhotoNeeded; index++) {
        if (![self isDisplayingPhotoForIndex:index]) {
            CaptionedImageView *capView = [self dequeueRecycledPhoto];
            if (capView == nil) {
                capView = [[[CaptionedImageView alloc] init] autorelease];
            }
            //[self configurePage:page forIndex:index];
            [self configurePhoto:capView forIndex:page];
            [self.scrollView addSubview:capView];
            [visiblePhotos addObject:capView];
        }
    } 
    
    // this was working, but it never recycles, it just keeps drawing:
    /*
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    */
}

- (CaptionedImageView *)dequeueRecycledPhoto {
    CaptionedImageView *capView = [recycledPhotos anyObject];
    if (capView) {
        [[capView retain] autorelease];
        [recycledPhotos removeObject:capView];
        
    }
    return capView;
}

- (BOOL)isDisplayingPhotoForIndex:(NSUInteger)index {
    BOOL foundPhoto = NO;
    for (CaptionedImageView *capView in visiblePhotos) {
        if (capView.index == index) {
            NSLog(@"found photo for index %d", capView.index);
            foundPhoto = YES;
            break;
        }
        else {
            NSLog(@"No photo for index %d", capView.index);
        }
    }
    return foundPhoto;
}

#pragma mark -
#pragma mark User-initated Actions


- (IBAction)changePage:(id)sender {
   
    NSLog(@"changePage triggering an update");
    
    [self updatePhotosForScrollViewPosition];
    
	// update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * self.pageControl.currentPage;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}


- (IBAction)flagPhoto:(id)sender {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Flag This Photo" 
													message:@"Do you want to flag this photo as inappropriate?" 
												   delegate:self 
										  cancelButtonTitle:@"Cancel" 
										  otherButtonTitles:@"Yes", nil];
	[alert show];
	[alert release];
	
}


- (void)flagPhotoByEmail {

	if ([MFMailComposeViewController canSendMail]) {  //verify that mail is configured on the device
		
		//present the mail window with boilerplate
		
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		
		mailVC.mailComposeDelegate = self;
					
		NSString *messageBody = @"I have a concern about this photo/caption:";
		
		NSNumber *photoID = [[[self treeImageList] objectAtIndex:pageControl.currentPage] objectForKey:@"id"];
		
		[mailVC setSubject:[NSString stringWithFormat:@"Flag Request for Tree Photo (id %d)", [photoID integerValue]]];
		[mailVC setToRecipients:[NSArray arrayWithObject:@"admin@pdxtrees.org"]];
		[mailVC setMessageBody:messageBody isHTML:NO];
		
		[self presentModalViewController:mailVC animated:YES];
		
	}
	else {
		
		// no network or email
		
		// NSLog(@"Flag Request: Network not available & Email not configured.");
		
		// give option to email
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could Not Flag" 
														message:@"No network connection or email available. Please visit pdxtrees.org to share your concern." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
	}
	
}



#pragma mark -
#pragma mark MFMailComposeViewController Delegate


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
	
	// test for each outcome
	

	/*
	switch (result)
	{
		case MFMailComposeResultCancelled:
			NSLog(@"Email result: canceled");
			break;
		case MFMailComposeResultSaved:
			NSLog(@"Email result: saved");
			break;
		case MFMailComposeResultSent:
			NSLog(@"Email result: sent");
			break;
		case MFMailComposeResultFailed:
			NSLog(@"Email result: failed");
			break;
		default:
			NSLog(@"Email result: not sent");
			break;
	}
	*/
	
	// dismiss the controller
	
	[self dismissModalViewControllerAnimated:YES];
} 

#pragma mark -
#pragma mark Making Flag Request (aka UIAlertView Delegate)

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {  // they clicked Yes
		
		// Place this code in a putFlagToServer method instead?
		
		
		// Check Reachability first
		
		// delete after testing.
		//NetworkStatus status = [[Reachability reachabilityWithHostName:@"pdxtrees.org"] currentReachabilityStatus];
		NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
		
		/*
		 enum {
		 
		 // Apple NetworkStatus Constant Names.
		 NotReachable     = kNotReachable,
		 ReachableViaWiFi = kReachableViaWiFi,
		 ReachableViaWWAN = kReachableViaWWAN
		 
		 };
		 */
		
		/*
		if (status == ReachableViaWiFi) {
			// wifi connection
			NSLog(@"Flag Request: Wi-Fi is available.");
		}
		if (status == ReachableViaWWAN) {
			// wwan connection (could be GPRS, 2G or 3G)
			NSLog(@"Flag Request: Only network available is 2G or 3G");	
		}
		*/
		 
		if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
		
		
			// use pageControl.currentPage to find the current index, fetch the photo id from dict at that index
			
			NSNumber *photoID = [[[self treeImageList] objectAtIndex:pageControl.currentPage] objectForKey:@"id"];
			
			// v1.1: recreate the url with values from RESTConstants.h
			//NSString *urlString = [NSString stringWithFormat:@"recreate", [photoID intValue]];
			
			NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@/photo/%d/flag/", kAPIUsername,kAPIPassword,kAPIHostAndPath, [photoID intValue]];
			
			// confirmation code:
			
			NSLog(@"Generated Flag Submit Request URL is: %@", urlString);
			
			
			// NSLog(@"Request URL is: %@", urlString);
			
			NSURL *url = [NSURL URLWithString:urlString];
						
			self.flagRequest = [ASIHTTPRequest requestWithURL:url];
			[[self flagRequest] setDelegate:self];
			[[self flagRequest] startAsynchronous];
		}
		
		else {
			
			// NSLog(@"Flag Request: Network not available.");
			
			// give option to email
			
			[self flagPhotoByEmail];
			
		}
		
	}
}


#pragma mark -
#pragma mark Handling Flag Request Response


- (void)requestFinished:(ASIHTTPRequest *)request {
	
	// log the success
	
	/*
	NSString *responseString = [request responseString];
	NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);
	NSLog(@"The HTML returned: %@", responseString);
	*/
	
	// Notify user here? Or assume they don't want to look at the photo anymore, and more them to another photo or back to TDVC?
	
	
}


- (void)requestFailed:(ASIHTTPRequest *)request {
	
	// handle the failure
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Flag Request: Cancellation initiated by killQueue method on viewWillDisappear.");
		
	}
	else {
	
		NSLog(@"Flag Request: The HTTP Status code was: %d", [request responseStatusCode]);
		NSLog(@"Flag request error: %@", [error description]);	
		NSLog(@"Failure of request to: %@", [request url]);
	}
	
}


#pragma mark -
#pragma mark Handling Photo Request Responses


- (void)photoRequestFinished:(ASIHTTPRequest *)request {
	
	// handle the arrival of a photo
	
	// NSLog(@"Photo VC: Photo request finished...");					
	// NSLog(@"User info was: %@", [request userInfo]);
	
	NSData *responseData = [request responseData];
	
	// replace the photo in the array
	
	if ([request responseStatusCode] == 200) {  //response okay
	
		NSUInteger photoIndex = [[[request userInfo] objectForKey:@"index"] intValue];
		
		[photoArray replaceObjectAtIndex:photoIndex withObject:[UIImage imageWithData:responseData]];
		
		// update the vc directly?
		
	}
	else {
		
		// bad photo result
		
		NSLog(@"Photo VC Photo Request: The HTTP Status code was: %d", [request responseStatusCode]);
		
		NSLog(@"Photo VC Photo Request: The data returned was %d bytes and looks like: %@", [responseData length], responseData);
		
		// load the placeholder photo in this location in the photo Array
		
		NSString *nullPhotoPath = [[NSBundle mainBundle] pathForResource:@"na-placeholder-320.jpg" ofType:nil];
		
		NSUInteger photoIndex = [[[request userInfo] objectForKey:@"index"] intValue];
		
		[photoArray replaceObjectAtIndex:photoIndex withObject:[UIImage imageWithContentsOfFile:nullPhotoPath]];
		
	}
	
	
	// need a way to run something like loadScrollViewWithPage to swap out image in photo array with thumbnail

	
}

- (void)photoRequestFailed:(ASIHTTPRequest *)request {
	
	// log failed photo request, and load a placeholder if it wasn't a return to tree detail
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Photo VC: Photo request canceled by killQueue method on viewWillDisappear.");
		
	}
	else {
		
		
		NSLog(@"Photo VC Photo Request HTTP Status code was: %d", [request responseStatusCode]);
		NSLog(@"Photo VC Photo Request Error: %@", [error description]);	
		NSLog(@"Photo VC Photo Request user info was: %@", [request userInfo]);
		NSLog(@"Photo VC Photo Request Failure of request to: %@", [request url]);
		
		
		// load the placeholder photo in this location in the photo Array
		
		NSString *nullPhotoPath = [[NSBundle mainBundle] pathForResource:@"na-placeholder-320.jpg" ofType:nil];
		
		NSUInteger photoIndex = [[[request userInfo] objectForKey:@"index"] intValue];
		
		[photoArray replaceObjectAtIndex:photoIndex withObject:[UIImage imageWithContentsOfFile:nullPhotoPath]];
		
	}
	
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
	// You could release the queue here if you wanted
	if ([[self imageRequestQueue] requestsCount] == 0) {
		[self setImageRequestQueue:nil];
	}
	// NSLog(@"Queue finished");
	
}

- (void)killQueue {
	
	// to be called on loss of network availability
	
	[[self imageRequestQueue] cancelAllOperations];
	
	// set nil so other requests don't keep calling failure methods while the VC is disappearing
	self.imageRequestQueue = nil;
	
}


#pragma mark -
#pragma mark Memory Management

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.scrollView = nil;
    self.pageControl = nil;
    
}


- (void)dealloc {
	
    [scrollView release];
    [pageControl release];
	
	[treeImageList release];
	[treeThumbnails release];
	[photoArray release];
	[treePhotosReceived release];
	
	[treeID	release];
	[treeName release];
	
	[flagRequest release];
	[imageRequestQueue release];
	
    [super dealloc];
}


@end
