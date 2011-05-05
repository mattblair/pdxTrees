//
//  TreeDetailViewController.m
//  pdxTreesCD
//
//  Created by Matt Blair on 9/18/10.
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

#import "TreeDetailViewController.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "PhotoViewController.h"
#import "ImageSubmitViewController.h"
#import "WebViewController.h"
#import "Reachability.h"
#import "NSString+SBJSON.h"
#import "RESTConstants.h"  // for access to URLs


@implementation TreeDetailViewController

@synthesize tree, treeImageList, treeThumbnails, treePhotos, treePhotosReceived;
@synthesize scientificNameLabel, diameterLabel, spreadLabel, yearLabel, addPhotoButton;
@synthesize image1Button, image2Button, image3Button, image4Button;
@synthesize fetchingLabel, fetchingSpinner, imageListRequest, imageRequestQueue, selectedPhotoPath;
@synthesize commonNameLabel, locationNameLabel, notesLabel, heightLabel, circumferenceLabel;


#pragma mark -
#pragma mark User-Initiated Actions
- (IBAction)shareTree:(id)sender {

	// Future: ask them if they want to text/email/tweet/fb or cancel
	
	if ([MFMailComposeViewController canSendMail]) {  //verify that mail is configured on the device
		
		//present the mail window with boilerplate
		
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		
		mailVC.mailComposeDelegate = self;
		
				
		NSMutableString *treeDetails = [NSMutableString stringWithString:@"\n"];
		
		// conditionally insert address
		
		if ([[tree address] length] > 0 ) {

			[treeDetails appendFormat:@"\nLocation: %@", [tree address]];

		}
		
		// conditionally insert notes
		if ([[tree notes] length] > 0) {
			
			
			NSString *notesText = [[tree notes] stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
																	withString:[[[tree notes] substringToIndex:1] uppercaseString]];
			[treeDetails appendFormat:@"\n%@", notesText];
		}
		
		// define footer
		NSString *pdxTreesFooter = @"\n\n\n-----\nTo learn more about Portland's Heritage Trees, visit: http://pdxtrees.org";
		
		NSString *messageBody = [NSString stringWithFormat:@"Have you heard about Portland's Heritage Trees? I thought you might like this %@.  %@  %@", 
								 [[tree commonName] capitalizedString], treeDetails, pdxTreesFooter];
		
		[mailVC setSubject:[NSString stringWithFormat:@"Heritage Tree: %@", [[tree commonName] capitalizedString]]];
		[mailVC setMessageBody:messageBody isHTML:NO];
		
		[self presentModalViewController:mailVC animated:YES];
		
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Not Available" 
														message:@"Please configure your phone to send email and try again." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
	
	/*
	// log the results during testing
	
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


- (IBAction)addPhoto:(id)sender {
	
	// show action sheet to determine image source
		
	// open a dialog with Take Picture, Choose Picture, Cancel
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add a photo..."
															 delegate:self cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:nil otherButtonTitles:@"With Camera", @"Choose From Gallery", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showInView:self.view];	
	
	[actionSheet release];
	
	
}


- (IBAction)viewPhotos:(id)sender {
	
	
	// create the photo VC
	
	PhotoViewController *photoVC = [[PhotoViewController alloc] initWithNibName:@"PhotoViewController" bundle:nil];
	
	// pass the array treeImageList and treeThumbnails arrays to the PhotoViewController
	
	photoVC.treeImageList = self.treeImageList;
	
	// pass in array of treePhotos
	
	photoVC.photoArray = self.treePhotos;
	
	// pass in array of Bools (stored as NSNumbers) so the Photo VC knows which still need to be fetched
	photoVC.treePhotosReceived = self.treePhotosReceived;
	
	// pass the tree id to the Photo VC

	photoVC.treeID = [[self tree] treeID];    // or is this not needed since we already have the photo URLs?
	
	photoVC.treeName = [[self tree] commonName];
	
	// Future: set page number based on which image is tapped
	
	// push it onto the nav stack
	
	[self.navigationController pushViewController:photoVC animated:YES];
	
	[photoVC release];
	
}


- (IBAction)showWikipedia:(id)sender {
	
	// Check Reachability first
	
	// delete after testing
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
	
	// log results during testing
	
	/*
	if (status == ReachableViaWiFi) {
        // wifi connection
		NSLog(@"Before Web VC for Wiki: Wi-Fi is available.");
	}
	if (status == ReachableViaWWAN) {
		// wwan connection (could be GPRS, 2G or 3G)
		NSLog(@"Before Web VC for Wiki: Only network available is 2G or 3G");	
	}
	*/
	
	if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
	
		// will load the web view controller with wikipedia entry for that particular scientific name
		
		WebViewController *webVC = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
		
		webVC.aboutMode = NO;
		
		webVC.sciNameToSearch = [tree scientificName];
		
		[self.navigationController pushViewController:webVC animated:YES];
		
		[webVC release];
	}
	else {

		// no network

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Network Connection" 
														message:@"Sorry, Wikipedia is not accessible. Please try again when you have an internet connection." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
	}

	
}


#pragma mark -
#pragma mark - Photo Method Selection aka UIActionSheet Delegate 

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
		
	//handle a cancel from the Action Sheet....
	if (buttonIndex == 2) {
		return;
	}
	
	//Based on code in the device features programming guide, may not be iOS 4.x optimized
	
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = YES;  //for cropping
	
	// Shouldn't need to set mediaTypes because it defaults to still camera
	
	if ((buttonIndex == 0) && ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])) {
		
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		
	}
	else {
		
		picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		
	}
	
	[self presentModalViewController:picker animated:YES];
		
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate protocol


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	// get rid of the modal view
	[self dismissModalViewControllerAnimated:YES];
	[picker release];
	
	/*
	 keys of info dictionary:
	 
	 NSString *const UIImagePickerControllerMediaType;
	 NSString *const UIImagePickerControllerOriginalImage;   // UIImage
	 NSString *const UIImagePickerControllerEditedImage;     // UIImage
	 NSString *const UIImagePickerControllerCropRect;
	 NSString *const UIImagePickerControllerMediaURL; 
	 
	 // new in 4.1
	 NSString *const UIImagePickerControllerReferenceURL;   // NSURL
	 NSString *const UIImagePickerControllerMediaMetadata;  // NSDictionary

	 
	 */ 
	
	
	// NSLog(@"Processing the image from didFinishPicking...");
	
	// once a photo has been created:

	// new in OS 4.1:
	//NSLog(@"The metadata for the image is: %@", [info objectForKey:UIImagePickerControllerMediaMetadata]);
	
	
	UIImage *selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
	
	// testing original image to see if it is bigger and better. It was 4mb @ 2592px × 1936px on an iPhone 4. Too big!
	//UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	// get the documents directory path
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	NSString *userDocumentsPath = [paths objectAtIndex:0];
	
	// make a photo name based on self.addBoxDateStamp	
	
	
	// generate datestamp string
	
	NSDateFormatter *filenameDateFormatter = [[NSDateFormatter alloc] init];
	
	[filenameDateFormatter setDateFormat:@"yyyy-MM-dd-HHmmss"];
	
	NSString *datestampString = [filenameDateFormatter stringFromDate:[NSDate date]];
	
	[filenameDateFormatter release];
	
	
	
	// create the file name and path
	
	NSString *imageFilename =  [NSString stringWithFormat:@"tree-%@-%@.jpg", [[tree treeID] stringValue], datestampString];
	
	NSString *saveJPEGPath = [userDocumentsPath stringByAppendingPathComponent:imageFilename];
	
	NSData *imageData = UIImageJPEGRepresentation(selectedImage, 1.0);
	
	
	// Saving the image to docs dir
	
	[imageData writeToFile:saveJPEGPath atomically:YES];
	
	
	
	// test code to verify the presence of the files:
	
	/*
	// Create file manager
	NSError *error;
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	
	
	// Write out the contents of home directory to console
	NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:userDocumentsPath error:&error]);
	*/

	
	// indicate that Image Submit should be next:
	
	showImageSubmitNext = YES;
	self.selectedPhotoPath = saveJPEGPath;
	
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	
	//decided not to add a photo, apparently
		
	[self dismissModalViewControllerAnimated:YES];	
	[picker release];

	
	showImageSubmitNext = NO;
	self.selectedPhotoPath = @"";
}


#pragma mark -
#pragma mark Image Submit Delegate

- (void)imageSubmitViewControllerDidFinish:(ImageSubmitViewController *)controller withSubmission:(BOOL)photoSubmitted {
	
	
	// prevent re-display of the image submit screen
	
	showImageSubmitNext = NO;
	self.selectedPhotoPath = @"";
	
	// dimiss the controller, thank the user if needed
	
	if (photoSubmitted) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank You" 
														message:@"We've received your photo and will add it to Portland's collection of Heritage Tree images." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert setDelegate:self];
		[alert show];
		[alert release];
	}
	
	
	[self dismissModalViewControllerAnimated:YES];	

	
}


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



- (void)viewDidLoad {
    [super viewDidLoad];
	
	// add the share button
	UIBarButtonItem *shareButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																				  target:self
																				  action:@selector(shareTree:)] autorelease];
	
	self.navigationItem.rightBarButtonItem = shareButton;
	
	// set UI elements
	
	commonNameLabel.text = [tree commonName];
	scientificNameLabel.text = [tree scientificName];
	
	// if present, word cap it
	if ([[tree address] length] > 0) {	
		
		// don't word cap it until you have special handling for NW, NE, SW, SE and ordinal numbers -- see ticket 95
		//locationNameLabel.text = [[tree address] capitalizedString]; // word cap it
		
		locationNameLabel.text = [tree address]; // WARNING: UGLY ALL CAPS IN ORIGINAL DATA
	}
	
	else {
		
		locationNameLabel.text = @"";
		
	}

	
	// if present, then cap the first letter
	if ([[tree notes] length] > 0) {
		
		
		notesLabel.text = [[tree notes] stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
																withString:[[[tree notes] substringToIndex:1] uppercaseString]];
	}
	
	else {
		
		notesLabel.text = @"";
		
	}


	// Show stats, where available
	
	if ([[tree height] doubleValue] > 0.0) {
		heightLabel.text = [NSString stringWithFormat:@"Height: %1.0f feet", [[tree height] doubleValue]];
	}
	else {
		heightLabel.text = @"Height: Not specified";
	}
	
	if ([[tree circumference] doubleValue] > 0.0) {
		circumferenceLabel.text = [NSString stringWithFormat:@"Circumference: %1.1f feet", [[tree circumference] doubleValue]];
	}
	else {
		circumferenceLabel.text = @"Circumference: Not specified";
	}

	if ([[tree diameter] doubleValue] > 0.0) {
		diameterLabel.text = [NSString stringWithFormat:@"Diameter: %1.1f inches", [[tree diameter] doubleValue]];
	}
	else {
		diameterLabel.text = @"Diameter: Not specified";
	}

	
	if ([[tree spread] doubleValue] > 0.0) {
		spreadLabel.text = [NSString stringWithFormat:@"Spread: %1.0f feet", [[tree spread] doubleValue]];
	}
	else {
		spreadLabel.text = @"Spread: Not specified";
	}

	
	yearLabel.text = [NSString stringWithFormat:@"Designated in %d", [[tree yearDesignated] intValue]];  //check format
	
	
	
	// photo management
	
	showImageSubmitNext = NO;
	self.selectedPhotoPath = @"";
	
	// hide image placeholders:
	
	image1Button.hidden = YES;
	image2Button.hidden = YES;
	image3Button.hidden = YES;
	image4Button.hidden = YES;
	

	fetchingLabel.hidden = NO;
	fetchingSpinner.hidesWhenStopped = YES;
	
	
	
	// initiate the request for photos
	
	// Check Reachability first
	
	// delete with host call after testing
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
		
	
		// NSLog(@"Preparing request for tree photos...");
		
		// show a text label that says fetching images...	
		fetchingLabel.text = @"Fetching Images...";
		
		// and start the activity spinner
		[fetchingSpinner startAnimating];
		
		//v1.1: build the URL from RESTConstants.h values
		//NSString *urlString = [NSString stringWithFormat:@"recreate URL", [[tree treeID] integerValue]];
		
		NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@%d/iphonescreen/", kAPIUsername,kAPIPassword,kAPIHostAndPath, [[tree treeID] integerValue]];
		
		// confirmation code:
		
		NSLog(@"Generated Photo Request URL is: %@", urlString);
		
		NSURL *url = [NSURL URLWithString:urlString];

		// made this an ivar so it can be cancelled easily
		// [self imageListRequest]
		
		//ASIHTTPRequest *listRequest = [ASIHTTPRequest requestWithURL:url];
		self.imageListRequest = [ASIHTTPRequest requestWithURL:url];

		[[self imageListRequest] setDelegate:self];
		[[self imageListRequest] startAsynchronous];
		
	}
	else {
		// no connection
		// NSLog(@"Image List Request won't be made: no connection.");
		fetchingLabel.text = @"Images not available. (Offline)";
		[fetchingSpinner stopAnimating];
	}

	
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (showImageSubmitNext && [[self selectedPhotoPath] length] > 0) {   // added photo && showImageSubmitNext
		
		// create the Image Submit VC
		 
		ImageSubmitViewController *imageSubmitVC = [[ImageSubmitViewController alloc] initWithNibName:@"ImageSubmitViewController" bundle:nil];
		
		
		// configure it
		 
		imageSubmitVC.tree = self.tree;
		 
		 
		imageSubmitVC.localPhotoPath = self.selectedPhotoPath;
		 
		imageSubmitVC.delegate = self;
		 
		// show it modally
		 
		[self presentModalViewController:imageSubmitVC animated:YES];
		 
		[imageSubmitVC release];
		
	}
	
	
}


-(void)viewWillDisappear:(BOOL)animated {
	
	// determine any active requests and cancel them
	
	
	
	// stop the image list request
	
	if ([[self imageListRequest] inProgress]) {
		// cancel it
		[[self imageListRequest] cancel];
	}
	
	// stop the queue
	
	// NSLog(@"Tree Detail VC: About to cancel all network operations because view is disappearing.");
	
	[self killQueue];  
}


#pragma mark -
#pragma mark Managing API Request for Image List Data

- (void)requestFinished:(ASIHTTPRequest *)request {
	
	// hide the text label that says fetching images...
	fetchingLabel.hidden = YES;
	
	// stop and hide the activity spinner
	[fetchingSpinner stopAnimating];
	
	// handle the response
	
	NSString *responseString = [request responseString];
	
	// NSLog(@"The Image List Request HTTP Status code was: %d", [request responseStatusCode]);
	// NSLog(@"The response for the Image List Request was: %@", responseString);
	
	// determine if it is JSON or images
	
	if ([[responseString JSONValue] isKindOfClass:[NSArray class]]) {

		NSMutableArray *tempImageList = [[NSMutableArray alloc] init];
		
		[tempImageList addObjectsFromArray:[responseString JSONValue]];
		
		// NSLog(@"Number of objects: %d", [tempImageList count]);
		
		if ([tempImageList count] > 0 ) {
			if ([[tempImageList objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {

				// process the array of dictionaries
				
				// for looking at the format of the dictionary returned
				// NSLog(@"first dictionary item in temp: %@", [tempImageList objectAtIndex:0]);
				
				self.treeImageList = tempImageList;
				
				NSUInteger imageCount = [[self treeImageList] count];
				
				// NSLog(@"For verification: count of items in ivar: %d", imageCount);
				
				
				// setup thumbnail array
				
				
				// based on the way Page Control SC handles this.
				// instead of adding nulls, should I just do initWithCapacity? What's the advantage of doing it the Page Control SC way?
				// Decided to init with thumbnail images, which solves problems with bad http requests and scaling nulls later.
				
				// insert a locally-loaded place holder icon from the missing image
				NSString *nullThumbnailPath = [[NSBundle mainBundle] pathForResource:@"null-placeholder50.jpg" ofType:nil];
				
				 
				NSMutableArray *tempThumbnailList = [[NSMutableArray alloc] init];  
				for (unsigned i = 0; i < imageCount; i++) {
					//[tempThumbnailList addObject:[NSNull null]];
					[tempThumbnailList addObject:[UIImage imageWithContentsOfFile:nullThumbnailPath]];
				}
				

				self.treeThumbnails = tempThumbnailList;

				[tempThumbnailList release];
				
				// NSLog(@"Created an array of %d nulls to hold thumbnails.", [[self treeThumbnails] count]);
				
				
	
				// initialize the treePhoto array here, with full-size placeholders
				
				// NSLog(@"Filling self.treePhotos with placeholder images at 320 pixels.");
				
				NSString *nullPhotoPath = [[NSBundle mainBundle] pathForResource:@"na-placeholder-320.jpg" ofType:nil];
				
				NSNumber *notReceived = [NSNumber numberWithBool:NO];
				
				NSMutableArray *tempTreePhotos = [[NSMutableArray alloc] init];  
				NSMutableArray *tempTreePhotoReceivedBOOLs = [[NSMutableArray alloc] init];
				
				for (unsigned i = 0; i < imageCount; i++) {
					[tempTreePhotos addObject:[UIImage imageWithContentsOfFile:nullPhotoPath]];
					//[self.treePhotosReceived addObject:notReceived];
					[tempTreePhotoReceivedBOOLs addObject:notReceived];
				}
				

				self.treePhotos = tempTreePhotos;
				self.treePhotosReceived = tempTreePhotoReceivedBOOLs;
				
				[tempTreePhotos release];
				[tempTreePhotoReceivedBOOLs release];
				
				// consolidate the above loops once photos one tests out...
				
				
								
				
				
				// create request queue if it doesn't exist yet
				
				if (![self imageRequestQueue]) {
					[self setImageRequestQueue:[[[ASINetworkQueue alloc] init] autorelease]];
				}
				
				self.imageRequestQueue.delegate = self;
				
				
				// create requests for iphonescreen images first, to give them a head start
				// in the future, with larger photos, maybe request the first two screen size images, then thumbnails, then remainder of larger
				
				
				NSUInteger treeIndex = 0;
				
				for (NSDictionary *treeImage in treeImageList) {
					
					NSURL *url = nil;
					ASIHTTPRequest *request = nil;
					
					url = [NSURL URLWithString:[treeImage valueForKey:@"image"]];
					//NSLog(@"Requesting: %@", url);
					request = [ASIHTTPRequest requestWithURL:url];
					[request setDelegate:self];
					request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"iphonescreen", @"requestType", [NSNumber numberWithInt:treeIndex], @"index", nil];
					[request setDidFinishSelector:@selector(photoRequestFinished:)];
					[request setDidFailSelector:@selector(photoRequestFailed:)];
					[[self imageRequestQueue] addOperation:request];
					
					treeIndex++;
					
					// Use this to throttle the number of requests made within this VC
					// For example, if this is 2, this VC will only request first two images, and leave it up to Photo VC to fetch the rest, when needed.
					if (treeIndex >= 3) {
						break;
					}
				}
				
				
			
				
				// start requests for thumbnails
				
				NSUInteger index = 0;
				
				for (NSDictionary *treeImage in treeImageList) {
					
					NSURL *url = nil;
					ASIHTTPRequest *request = nil;
					
					url = [NSURL URLWithString:[treeImage valueForKey:@"thumbnail_url"]];
					//NSLog(@"Requesting: %@", url);
					request = [ASIHTTPRequest requestWithURL:url];
					[request setDelegate:self];
					request.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"thumbnail", @"requestType", [NSNumber numberWithInt:index], @"index", nil];
					[request setDidFinishSelector:@selector(thumbnailRequestFinished:)];
					[request setDidFailSelector:@selector(thumbnailRequestFailed:)];
					[[self imageRequestQueue] addOperation:request];
					
					index++;
					
					// don't break at button limit -- request all images up to 6? what's the limit in v 1.0?
					if (index >= 6) {
						break;
					}
				}
				
				
				
				// start the queue
				// NSLog(@"Starting queue");				
				[[self imageRequestQueue] go];
				
				
			}
		}
		
		else {
			
			self.treeImageList = nil;
			self.treeThumbnails = nil;
			
			fetchingLabel.text = @"No photos yet. (Hint, Hint...)";
			fetchingLabel.hidden = NO;
		}
		
		[tempImageList release];

	}
	
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	
	// handle the failure in the UI
	
	fetchingLabel.text = @"Images not available.";
	
	// stop and hide the activity spinner
	[fetchingSpinner stopAnimating];
	
	// Log it
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Cancellation initiated by killQueue method on viewWillDisappear.");
		
	}
	else {
	
		NSLog(@"Image List Request HTTP Status code was: %d", [request responseStatusCode]);
		NSLog(@"Image List Request Error: %@", [error description]);			
		NSLog(@"Image List Request: Failure of request to: %@", [request url]);
	}
	
}

#pragma mark -
#pragma mark ASINetworkQueue Delegate Methods

-(void)thumbnailRequestFinished:(ASIHTTPRequest *)request {
	
	//process the success  

	// NSLog(@"Thumbnail request finished...");					
	// NSLog(@"User info was: %@", [request userInfo]);
	
	NSData *responseData = [request responseData];
	
	if ([request responseStatusCode] == 200) {  //response okay
		
		NSUInteger thumbIndex = [[[request userInfo] objectForKey:@"index"] intValue];
		
		[treeThumbnails replaceObjectAtIndex:thumbIndex withObject:[UIImage imageWithData:responseData]];
		
		switch (thumbIndex) {
			case 0:
				// first thumbnail
				
				[image1Button setImage:[treeThumbnails objectAtIndex:thumbIndex] forState:UIControlStateNormal];
				
				fetchingLabel.hidden = YES;
				
				image1Button.hidden = NO;
				
				break;
				
			case 1:
				// second thumbnail
				
				[image2Button setImage:[treeThumbnails objectAtIndex:thumbIndex] forState:UIControlStateNormal];
				
				image2Button.hidden = NO;
				
				break;
				
			case 2:
				// third thumbnail
				
				[image3Button setImage:[treeThumbnails objectAtIndex:thumbIndex] forState:UIControlStateNormal];
				
				image3Button.hidden = NO;
				
				break;	
				
			case 3:
				// fourth thumbnail
				
				// add conditional to set button text if there are more than four images
				
				// Future: show either the fourth image, or a count of how many more are available...
				// [image4Button setTitle:@"+ 3" forState:UIControlStateNormal];
				
				[image4Button setImage:[treeThumbnails objectAtIndex:thumbIndex] forState:UIControlStateNormal];
				
				image4Button.hidden = NO;
				
				break;		
				
			default:
				// additional thumbnails
				
				break;
		}
		
		
	}  // end of response okay
	else {  //bad response
		
		NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);
		
		NSLog(@"The data returned was %d bytes and looks like: %@", [responseData length], responseData);
		
	}

	

}
							  
-(void)thumbnailRequestFailed:(ASIHTTPRequest *)request {

	// update UI
	[fetchingSpinner stopAnimating];
	
	// no need for any other updates, because thumbnail buttons are only un-hidden on success
	
	// log the failure
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Cancellation initiated by killQueue method on viewWillDisappear, etc.");
		
	}
	else {
	
		NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);
		NSLog(@"Description of error: %@", [error description]);	
		NSLog(@"User info was: %@", [request userInfo]);
		
		NSLog(@"Failure of request to: %@", [request url]);
	}
		
}

-(void)photoRequestFinished:(ASIHTTPRequest *)request {
	
	// process the image
	

	// NSLog(@"Photo request finished...");					
	// NSLog(@"User info was: %@", [request userInfo]);
	
	NSData *responseData = [request responseData];
	
	if ([request responseStatusCode] == 200) {  //response okay
		
		
		// store it
		
		NSUInteger photoIndex = [[[request userInfo] objectForKey:@"index"] intValue];
		
		[[self treePhotos] replaceObjectAtIndex:photoIndex withObject:[UIImage imageWithData:responseData]];
	

		// flip the received bool for that index:
		
		NSNumber *photoReceived = [NSNumber numberWithBool:YES];
		
		[[self treePhotosReceived] replaceObjectAtIndex:photoIndex withObject:photoReceived];
		
		// temp nslog to verify the array of BOOLs is working properly
		// BOOL newValue = [[[self	treePhotosReceived] objectAtIndex:photoIndex] boolValue];
		
		// NSLog(@"Photo Request Finished: NSNumber is %@ ", [[self treePhotosReceived] objectAtIndex:photoIndex]);

		
		
	}
	else {
		// process the failure...
		
		NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);
		
		NSLog(@"The data returned was %d bytes and looks like: %@", [responseData length], responseData);
		
		
		// no further action needed, since this array location already has a null image

		
	}

}

-(void)photoRequestFailed:(ASIHTTPRequest *)request {
	
	//process the failure
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Cancellation initiated by killQueue method on viewWillDisappear, etc.");
				
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
	// You could release the queue here if you wanted
	if ([[self imageRequestQueue] requestsCount] == 0) {
		[self setImageRequestQueue:nil];
	}
	
	//NSLog(@"Queue finished");
	
	[fetchingSpinner stopAnimating];
}


- (void)killQueue {
	
	// to be called on loss of network availability or if leaving this VC
	
	// Does it cause any problems to call cancel on an inactive queue?
	// If so, you could check to see if requestsCount > 0 
	
	[[self imageRequestQueue] cancelAllOperations];
	
	
	// so that the rest of the requests don't keep calling the failed methods
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
	

	// NSLog(@"TDVC: Setting arrays to nil");
	
	self.imageRequestQueue = nil; 
	
	self.treeThumbnails = nil;
	
	self.treePhotos = nil;
	
	// NSLog(@"End of viewDidUnload");
	
}


- (void)dealloc {
	
	
	[scientificNameLabel release];
	[commonNameLabel release];
	[locationNameLabel release];
	[notesLabel release];
	[heightLabel release];
	[circumferenceLabel release];
	[diameterLabel release];
	[spreadLabel release];
	[yearLabel release];
	
	[addPhotoButton release];
	[image1Button release];
	[image2Button release];
	[image3Button release];
	[image4Button release];
	
	[fetchingLabel release];
	[fetchingSpinner release];
	
	[tree release];
	[treeImageList release];
	[treeThumbnails release];
	[treePhotos release];
	[treePhotosReceived release];
	
	[imageListRequest release];
	[imageRequestQueue release];
	
	
    [super dealloc];
}


@end