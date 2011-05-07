//
//  ImageSubmitViewController.m
//  pdxTrees
//
//  Created by Matt Blair on 9/20/10.
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
//


#import <MessageUI/MessageUI.h>  // for email fall-back when internet is not available
#import "ImageSubmitViewController.h"
#import "ASIFormDataRequest.h"
#import "Reachability.h"
#import "RESTConstants.h"  // for access to URLs

// added for Couch submissions
#import "ASIHTTPRequest.h" 
#import "NSObject+SBJSON.h"
#import "NSString+SBJSON.h"

@implementation ImageSubmitViewController

@synthesize captionTextField, nameTextField, emailTextField, currentTextField, theImageView, ccExplainerLabel; //urlTextField
@synthesize tree, localPhotoPath, cancelButton, saveButton, submittingSpinner, delegate, imageSubmitRequest;
@synthesize sentToCouch;


#pragma mark -
#pragma mark User-initiated Actions



-(IBAction)submitPhoto:(id)sender {
	
	
	// disable UI elements
	
	// disable save to prevent double-taps
	saveButton.enabled = NO; 
	
	self.captionTextField.enabled = NO;
	self.nameTextField.enabled = NO;
	self.emailTextField.enabled = NO;
	
	// hide the keyboard here, if shown
	if (currentTextField) {
		[currentTextField resignFirstResponder];
	}
	
	
	// store the values for name and email, if populated
	
	BOOL fieldsRemembered = NO;
	
	if ([[nameTextField text] length] > 0) {
	
		[[NSUserDefaults standardUserDefaults] setObject:nameTextField.text forKey:@"displayName"];
		
		fieldsRemembered = YES;
		
	}
	
	if ([[emailTextField text] length] > 0) {
		[[NSUserDefaults standardUserDefaults] setObject:emailTextField.text forKey:@"emailAddress"];

		fieldsRemembered = YES;
	
		
	}
	

	if (fieldsRemembered) {
		[[NSUserDefaults standardUserDefaults] synchronize];	
		NSLog(@"Newly stored name and email are: %@, %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"displayName"], [[NSUserDefaults standardUserDefaults] stringForKey:@"emailAddress"]);
	}
	/*
	else {
		NSLog(@"Fields not remembered.");  //else statement for testing only -- can delete
	}
	*/

	
	
	
	// Check Reachability first
	
	// don't use a host check on the main thread because of possible DNS delays...

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
		NSLog(@"Image Submit: Wi-Fi is available.");
	}
	if (status == ReachableViaWWAN) {
		// wwan connection (could be GPRS, 2G or 3G)
		NSLog(@"Image Submit: Only network available is 2G or 3G");	
	}
	*/
	
	if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
	

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
		
		internetReach = [[Reachability reachabilityForInternetConnection] retain];
		[internetReach startNotifier];
		

		// indicate the submission process is starting
		[submittingSpinner startAnimating];
		
		//configure url and request -- v1.1: build from RESTConstants.h values
		
		NSString *authPostURL = [NSString stringWithFormat:@"http://%@:%@@%@", kAPIUsername,kAPIPassword,kAPIHostAndPath];
		
		// a peek at the URL
		NSLog(@"Generated URL is: %@", authPostURL);
		
		NSURL *url = [NSURL URLWithString:authPostURL];	

		
		self.imageSubmitRequest = [ASIFormDataRequest requestWithURL:url];
		
		[[self imageSubmitRequest] setRequestMethod:@"POST"];
		
		// set required fields
		
		// image
		if ([[self localPhotoPath] length] > 0) {
			
			// In simulator, test with a photo included in the bundle, since simulator has no image library or camera:
			//NSString *nullPhotoPath = [[NSBundle mainBundle] pathForResource:@"null-placeholder320.jpg" ofType:nil];
			
			// device code:
			
			// need to slice up path and file name: 
			
			NSArray *photoPathArray = [localPhotoPath pathComponents];
			
			NSLog(@"The photoPathArray is: %@", photoPathArray);
			
			[[self imageSubmitRequest] setFile:localPhotoPath
				withFileName:[photoPathArray lastObject]  // last object in pathComponents is the filename
			  andContentType:@"image/jpeg" 
					  forKey:@"image"];
		}
		
		
		// related_tree_id
		[[self imageSubmitRequest] setPostValue:[tree treeID] forKey:@"related_tree_id"];
		
		// related_tree_couch_id
		[[self imageSubmitRequest] setPostValue:[tree couchID] forKey:@"related_tree_couch_id"];

		
		// The next three are hardcoded values the server will override in API v1:
		
		// date_submitted (YYYY-MM-DD)
		[[self imageSubmitRequest] setPostValue:@"2010-10-01" forKey:@"date_submitted"];
		
		// flag_count (0)
		[[self imageSubmitRequest] setPostValue:@"0" forKey:@"flag_count"];
		
		// review_status (pending)
		[[self imageSubmitRequest] setPostValue:@"pending" forKey:@"review_status"];

		
		
		// optional fields: server will validate. Just truncate to server field limits
		
		// caption (TextField -- can be long)
		if ([[captionTextField text] length] > 0) {
			
			[[self imageSubmitRequest] setPostValue:captionTextField.text forKey:@"caption"];

		}
		

		NSUInteger maxLength = 0;

		// submitter_name (100)
		
		if ([[nameTextField text] length] > 0) {
			
			if ([[nameTextField text] length] > 100) {
				maxLength = 100;
			}
			else {
				maxLength = [[nameTextField text] length];
			}

			[[self imageSubmitRequest] setPostValue:[[nameTextField text] substringToIndex:maxLength] forKey:@"submitter_name"];
			
		} 
		
		// submitter_email -- validated server-side (150)
		
		if ([[emailTextField text] length] > 0) {
			
			if ([[emailTextField text] length] > 150) {
				maxLength = 150;
			}
			else {
				maxLength = [[emailTextField text] length];
			}

			[[self imageSubmitRequest] setPostValue:[[emailTextField text] substringToIndex:maxLength] forKey:@"submitter_email"];
			
		}
		
		// submitter_url (not implemented yet)

		
		// start request

		// setup the progress indicator:
		//[request setUploadProgressDelegate:uploadProgress];
		
		[[self imageSubmitRequest] setDelegate:self];
		
		// commented to add it to the queue instead
		NSLog(@"Starting the async upload");
		[[self imageSubmitRequest] startAsynchronous];
		
	} //end of reachability = true
	
	else {  // no reachability
		
		// detecting offline mode
		// NSLog(@"Image Submit: No network access.");
		
		// add email submit here.
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Connection" 
														message:@"The internet is not available. Would you like to add the image to a draft email to send later?" 
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
											  otherButtonTitles:@"Yes", nil];
		[alert show];
		[alert release];
		
		
	}

}


-(IBAction)cancelPhoto:(id)sender {
	
	// close this screen and return to detail, triggering cleanup
	
	// NSLog(@"User cancelled the photo submission in the Image Submit VC.");
	
	[self killRequest];  // in case it is still running
	
	[delegate imageSubmitViewControllerDidFinish:self withSubmission:NO];
	
}


- (void)submitPhotoByEmail {
	
	if ([MFMailComposeViewController canSendMail]) {  //verify that mail is configured on the device
			
		
		// related_tree_id
		
		NSString *treeIDString = [NSString stringWithFormat:@"Related Tree ID: %d", [[tree treeID] integerValue]];
		
		// related_tree_couch_id
		NSString *treeCouchIDString = [NSString stringWithFormat:@"Related Tree Couch ID: %@", [tree couchID]];
		
		// optional fields: server will validate. just truncate to server field limits
		
		NSString *captionString;
		
		// caption (TextField -- can be long)
		if ([[captionTextField text] length] > 0) {
			
			captionString = [NSString stringWithFormat:@"Caption: %@", captionTextField.text];
		}
		else {
			captionString = @"Caption: none";
		}

			
		// submitter_name (100)
		
		NSString *nameString;
		
		if ([[nameTextField text] length] > 0) {
			
			nameString = [NSString stringWithFormat:@"Submitter name: %@", nameTextField.text];

		} 
		
		else {
			nameString = @"Submitter name: None";
		}

		// no need to add email since this will be sent by email...
        // ...or should it be added here if different from system? probably not worth the checking...
		 
		
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		
		mailVC.mailComposeDelegate = self;
		
		NSString *messageBody = [NSString stringWithFormat:@"About this Image:\n%@\n%@\n%@\n%@\n\n", treeIDString, treeCouchIDString, captionString, nameString];
		
		[mailVC setSubject:[NSString stringWithFormat:@"Image for Heritage Tree (id %d)", [[tree treeID] integerValue]]];
		[mailVC setToRecipients:[NSArray arrayWithObject:@"admin@pdxtrees.org"]];
		[mailVC setMessageBody:messageBody isHTML:NO];
		
		 
		if ([[self localPhotoPath] length] > 0) {
			 
			 
			// need to slice path and file name: 
			 
			NSArray *photoPathArray = [localPhotoPath pathComponents];
			 
			// NSLog(@"Adding photo from photoPathArray: %@", photoPathArray);
			 
			// the way it is added to the form request, for reference:
			//[request setFile:localPhotoPath
			//	 withFileName:[photoPathArray lastObject]  // last object in pathComponents is the filename
			//   andContentType:@"image/jpeg" 
			//		   forKey:@"image"];
			
			[mailVC addAttachmentData:[NSData dataWithContentsOfFile:[self localPhotoPath]] mimeType:@"image/jpeg" fileName:[photoPathArray lastObject]];
			
		}
		 
		 
		[self presentModalViewController:mailVC animated:YES];
		
	
	}
	
	else {
		
		// no network or email
		
		// NSLog(@"Image Submit: Network not available & Email not configured.");
		
		// give option to email
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could Not Submit" 
														message:@"No network connection or email available. Please visit pdxtrees.org to share your image." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
	}
	
}


#pragma mark -
#pragma mark Handling the response from image Post request


- (void)requestFinished:(ASIHTTPRequest *)request
{

	// NSString *responseString = [request responseString];
	// NSLog(@"The Image Submit HTTP Status code was: %d", [request responseStatusCode]);
	// NSLog(@"The Image Submit response was: %@", responseString);
	
	
	[submittingSpinner stopAnimating];
	
	if ([request responseStatusCode] == 200) {
		
		// return to detail view, which will display an alert view about success
		[delegate imageSubmitViewControllerDidFinish:self withSubmission:YES];
		
	}
	
	else {
		
        // handle the error by offering email:
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Problem" 
														message:@"Sorry, the server didn't respond as expected. We'll fix that as soon as we can. Would you like to send the image by email instead?" 
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		
	}
    
    self.imageSubmitRequest = nil;
	
}

- (void)requestFailed:(ASIHTTPRequest *)request
{

	// update UI
	
	[submittingSpinner stopAnimating];
	
	// log and handle the error
	
	NSError *error = [request error];
	
	if (([error code] == 4) && ([[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"])) {  // not an error
		NSLog(@"Cancellation initiated by Reachability notification or directly by user.");
		
		// Keep this here in case design changse. 
        // Cancel button has its own call to this, as does No to email Alert View
        
		// return to TDVC for notification (was at bottom of method)
		//[delegate imageSubmitViewControllerDidFinish:self withSubmission:NO];
		
	}
	else {
		NSLog(@"The HTTP Status code was: %d", [request responseStatusCode]);

		NSLog(@"Error submitting image: %@", [error description]);	
		
		NSLog(@"Image Submit POST request failed. Offering email as an alternative.");
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Problem" 
														message:@"Sorry, the server didn't respond as expected. We'll fix that as soon as we can. Would you like to send the image by email instead?" 
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
	}
	
    self.imageSubmitRequest = nil;
    
}


- (void)killRequest {
	
	if ([[self imageSubmitRequest] inProgress]) {

		// NSLog(@"Request is in progress, about to cancel.");		
		
		[[self imageSubmitRequest] cancel];  // does this always call requestFailed?

		// NSLog(@"Request cancelled.");
		
		[submittingSpinner stopAnimating];
        
        
        // not needed if the cancel calls requestFailed, nor if it has already succeeded failed, because it won't be in progress anymore? Confirm this.
        self.imageSubmitRequest = nil; 
		
	}
	
}

#pragma mark - Migrating to Couch

- (IBAction)submitPhotoMetadataToCouch:(id)sender {
    
    // testing basic functionality first, then will port over the real stuff later
    
    NSURL *theURL = [NSURL URLWithString:kCouchURLForPhotoSubmission];
    
    ASIHTTPRequest *photoSubmitRequest = [ASIHTTPRequest requestWithURL:theURL];
    
    [photoSubmitRequest setRequestMethod:@"POST"];
    
    [photoSubmitRequest addRequestHeader:@"Content-Type" value:@"application/json"];
    
    // put some crap in there for now
    
    NSDictionary *photoMetadataDict = [NSDictionary dictionaryWithObject:@"some crap" forKey:@"from-iOS"];
    
    NSString *jsonToSubmit = [photoMetadataDict JSONRepresentation];
    
    [photoSubmitRequest appendPostData:[jsonToSubmit dataUsingEncoding:NSUTF8StringEncoding]];
    
    [photoSubmitRequest setDelegate:self];
    
    [photoSubmitRequest setDidFinishSelector:@selector(couchMetadataPOSTRequestFinished:)];
    
    [photoSubmitRequest setDidFailSelector:@selector(couchMetadataPOSTRequestFailed:)];
                                                       
    [photoSubmitRequest startAsynchronous];
    
}

- (void)couchMetadataPOSTRequestFinished:(ASIHTTPRequest *)request {
    
    // NSString *responseString = [request responseString];
	NSLog(@"The Metadata POST HTTP Status code was: %d", [request responseStatusCode]);
	NSLog(@"The Metadata POST response was: %@", [request responseString]);
    
    // status should be 201 (Created) and responseString should be JSON
    
    // The Image Submit response was: 
    // {"ok":true,"id":"bc623d29a6a3694544afa0d84f00da43","rev":"1-5ee7119822cb7faec5dcafdf326e8378"}

    // parse id and rev to assembler url to submit photo
    
    NSDictionary *metadataResponse = [[request responseString] JSONValue];
    
    //  http://elsewise.iriscouch.com/mydb/<doc.id>/filename.jpg?rev=<doc.rev>
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@?rev=%@", 
                           kCouchURLForPhotoSubmission, 
                           [metadataResponse objectForKey:@"id"],
                           @"testfile.jpg", // see code above to actually get the name
                           [metadataResponse objectForKey:@"rev"]];
    
    NSLog(@"Assembled URL for submitting the photo is: %@", urlString);
    
    NSURL *imagePUTURL = [NSURL URLWithString:urlString];
    
    ASIHTTPRequest *imagePUTRequest = [ASIHTTPRequest requestWithURL:imagePUTURL];
    
    [imagePUTRequest setRequestMethod:@"PUT"];
    
    [imagePUTRequest addRequestHeader:@"Content-Type" value:@"image/jpeg"];
    
    // add image as data binary
    
    NSString *nullPhotoPath = [[NSBundle mainBundle] pathForResource:@"null-placeholder320.jpg" ofType:nil];
    
    //[imagePUTRequest appendPostDataFromFile:nullPhotoPath];
    
    [imagePUTRequest setPostBodyFilePath:nullPhotoPath];
    
    [imagePUTRequest setShouldStreamPostDataFromDisk:YES];
    
    [imagePUTRequest setDelegate:self];
    
    [imagePUTRequest setDidFinishSelector:@selector(couchImagePUTRequestFinished:)];
    
    [imagePUTRequest setDidFailSelector:@selector(couchImagePUTRequestFailed:)];
    
    [imagePUTRequest startAsynchronous];
    
}

- (void)couchMetadataPOSTRequestFailed:(ASIHTTPRequest *)request {
    
    NSLog(@"The Metadata POST HTTP Status code was: %d", [request responseStatusCode]);
	NSLog(@"The Metadata POST response was: %@", [request responseString]);
    
    // if you don't even get this far, offer email
    
    
}

- (void)couchImagePUTRequestFinished:(ASIHTTPRequest *)request {
    
    //
    NSLog(@"The Image Submit PUT HTTP Status code was: %d", [request responseStatusCode]);
	NSLog(@"The Image Submit PUT response was: %@", [request responseString]);
    
}


- (void)couchImagePUTRequestFailed:(ASIHTTPRequest *)request {
    
    //
    NSLog(@"The Image Submit PUT HTTP Status code was: %d", [request responseStatusCode]);
	NSLog(@"The Image Submit PUT response was: %@", [request responseString]);
    
}


#pragma mark -
#pragma mark Reachability Handling

-(void)reachabilityChanged: (NSNotification* )note {
	
	// respond to changes in reachability
	
	Reachability *currentReach = [note object];
	
	NetworkStatus status = [currentReach currentReachabilityStatus];
	
	if (status == NotReachable) {  
		[self killRequest];
		 
		// NSLog(@"Image Submit: Connection failed in the middle of the POST request.");
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Lost" 
														message:@"Unable to upload image information. Would you like to send it my email?" 
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		
		
	}
	
}

#pragma mark -
#pragma mark Handle UIAlertView Choice

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if ([[alertView title] isEqual:@"Thank You"]) {
		
		// dismiss the image submit VC, without confirmation from tdvc
		
		[delegate imageSubmitViewControllerDidFinish:self withSubmission:NO]; 
		
	}
	
	else {  // prompt to send by email
		
		if (buttonIndex == 1) {  // they clicked Yes
			
			// show the email option
			
			// NSLog(@"User chose to submit by email.");
			[self submitPhotoByEmail];
			
		}
		else {
			
			// request has already been cancelled, so just close this VC
			
			// NSLog(@"User chose cancel on send by email alert view.");
			[delegate imageSubmitViewControllerDidFinish:self withSubmission:NO];
		}
	}
	
}


#pragma mark -
#pragma mark MFMailComposeViewController Delegate


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	
	
	// what happened
	
	NSString *messageString;
	
	switch (result)
	{
		case MFMailComposeResultCancelled: {
			// NSLog(@"Email result: canceled");
			messageString = @"Email canceled. We hope you'll try to send more images soon.";
			break;
		}
		case MFMailComposeResultSaved: {
			// NSLog(@"Email result: saved");
			messageString = @"A draft of your email has been saved. We hope you'll send more images soon.";
			break;
		}
		case MFMailComposeResultSent: {
			// NSLog(@"Email result: sent");
			messageString = @"We'll add your photo to Portland's collection of Heritage Tree images.";
			break;
		}
		case MFMailComposeResultFailed: {
			// NSLog(@"Email result: failed");
			messageString = @"There seems to be a problem with email, too. We hope you'll try to send more images soon.";
			break;
		}
		default: {
			// NSLog(@"Email result: not sent");
			messageString = @"Thank you for contributing to Portland's collection of Heritage Tree images.";
			break;
		}
	}
	
	
	// dismiss the controller
	
	[self dismissModalViewControllerAnimated:YES];
	
	// show thank you here
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank You" 
													message:messageString
												   delegate:self 
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
} 


#pragma mark -
#pragma mark Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {	
	[textField resignFirstResponder];
	return YES;	
}


//---when a TextField view begins editing---
-(void) textFieldDidBeginEditing:(UITextField *)textFieldView {  
    currentTextField = textFieldView;
}  

//---when a TextField view is done editing---
-(void) textFieldDidEndEditing:(UITextField *) textFieldView {  
    currentTextField = nil;
}







#pragma mark -
#pragma mark View Lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
		
	// load image
	
	self.theImageView.image = [UIImage imageWithContentsOfFile:self.localPhotoPath];
	
	// re-populate the name and email fields
	
	NSString *storedName = [[NSUserDefaults standardUserDefaults] stringForKey:@"displayName"];
	
	NSString *storedEmail = [[NSUserDefaults standardUserDefaults] stringForKey:@"emailAddress"];
	
	if ([storedName length] > 0) {
		self.nameTextField.text = storedName;
	}
	
	if ([storedEmail length] > 0) {
		self.emailTextField.text = storedEmail;
	}
	
	
	// set creative commons description
	
	self.ccExplainerLabel.text = @"We use the Creative Commons Attribution-Share-Alike license for all submitted photos. You can learn more about it at creativecommons.org.";
    
    
    // testing couch
    [self submitPhotoMetadataToCouch:self];
    
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */



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
	
	self.captionTextField = nil;
    self.nameTextField = nil;
    self.emailTextField = nil;
    self.currentTextField = nil;
    
    self.ccExplainerLabel = nil;
    self.theImageView = nil;
    
    self.cancelButton = nil;
    self.saveButton = nil;
    self.submittingSpinner = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}


- (void)dealloc {
	
	
	[captionTextField release];
	[nameTextField release];
	[emailTextField release];
	[currentTextField release];
	
	[ccExplainerLabel release];
	[theImageView release];
	
	[localPhotoPath release];
	[tree release];
	
	[cancelButton release];
	[saveButton release];
	[submittingSpinner release];
	
	[imageSubmitRequest release];

	
    [super dealloc];
}


@end
