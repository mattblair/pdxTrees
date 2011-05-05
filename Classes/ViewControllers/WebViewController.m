//
//  WebViewController.m
//  pdxTreesCD
//
//  Created by Matt Blair on 9/28/10.
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

#import "WebViewController.h"
#import "Reachability.h"


@implementation WebViewController

@synthesize theWebView, sciNameToSearch, aboutMode;

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
	
	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	
	internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifier];
	
	
	if ([self aboutMode]) {
		
		// we want these kinds of pages to scale:
		
		theWebView.scalesPageToFit = YES;
		
		// setup the about request here
		
		self.navigationItem.title = @"About";
		
		NSString *localAboutHTML = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
		NSURL *url = [NSURL fileURLWithPath:localAboutHTML];
		
		// NSLog(@"About to request the URL: %@", localAboutHTML);
		
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		
		[theWebView loadRequest:request];
		
	}
	else {
		
		//handle the wiki request

		// set the title
		self.navigationItem.title = @"Wikipedia";
		
		//The test url
		//http://en.m.wikipedia.org/wiki?search=Pinus+rudis
		
		// replace spaces with + in string -- what about periods, quotes and other punctuation?
		NSString *searchString = [sciNameToSearch stringByReplacingOccurrencesOfString:@" " withString:@"+"];
		
		NSString *wikiPath = [NSString stringWithFormat:@"http://en.m.wikipedia.org/wiki?search=%@", searchString];
		
		// NSLog(@"About to request the URL: %@", wikiPath);
		
		NSURL *url = [NSURL URLWithString:wikiPath];
		
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		
		[theWebView loadRequest:request];
		
	}


	// add back and forward buttons (adapated from listing 3-2 of the VC PG)
	
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
											[NSArray arrayWithObjects:
											 [UIImage imageNamed:@"back-dingy"],
											 [UIImage imageNamed:@"fwd-dingy"],
											 //@"Back",
											 //@"Fwd",
											 nil]];
	
	[segmentedControl addTarget:self action:@selector(navigateWebView:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0, 0, 90, 30);  // was kCustomButtonHeight
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	//defaultTintColor = [segmentedControl.tintColor retain];    // keep track of this in the future?
	
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	[segmentedControl release];
	
	self.navigationItem.rightBarButtonItem = segmentBarItem;
	[segmentBarItem release];
	

}




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
	
	// Some of those wikipedia pages seem to be relatively fat
	NSLog(@"WebViewController received memory warning...");
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewWillAppear:(BOOL)animated
{
	self.theWebView.delegate = self; // set delegate so callbacks can manage button state
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.theWebView stopLoading];	// in case the web view is still loading its content
	self.theWebView.delegate = nil;	// disconnect the delegate as the webview is hidden
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)dealloc {
	
	[theWebView release];
	
	[sciNameToSearch release];
	
	
    [super dealloc];
}

#pragma mark -
#pragma mark Reachability Handling

-(void)reachabilityChanged: (NSNotification* )note {

	// respond to changes in reachability
	
	Reachability *currentReach = [note object];
	
	NetworkStatus status = [currentReach currentReachabilityStatus];
	
	if (status == NotReachable) {  
		[[self theWebView] stopLoading];
		
		// NSLog(@"WebView Request: Connection failed in the middle of the web request.");

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Lost" 
														message:@"Please try again when an internet connection is available." 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];

		
	}
	
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

	
	
	// check reachability here for everything except the locally loaded about page

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
		NSLog(@"WebView Request: Wi-Fi is available.");
	}
	if (status == ReachableViaWWAN) {
		// wwan connection (could be GPRS, 2G or 3G)
		NSLog(@"WebView Request: Only network available is 2G or 3G");	
	}
	*/
	
	
	if (status == kReachableViaWiFi || status == kReachableViaWWAN) { 
		return YES;
	}
	else {  // no internet connection
				
		if ([[request URL] isFileURL]) { 
			return YES;
		}
		
		else {
	
			// alert here? or is injecting into the web page enough?
			
			// NSLog(@"WebView Request: No connection for web request.");
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Connection" 
															message:@"Please try again when an internet connection is available." 
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			[alert show];
			[alert release];
			
			
			return NO;
		}
		
		
	}

}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[self updateNavButtons];
	
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString* errorString = [NSString stringWithFormat:
							 						 @"<html><center>Sorry, Wikipedia Mobile couldn't load that page. Please try again in a few moments.</center></html>"];
	[self.theWebView loadHTMLString:errorString baseURL:nil];
	
	NSLog(@"webView request failed with error: %@", [error localizedDescription]);
	
	[self updateNavButtons];
}

#pragma mark -
#pragma mark Handling Web Navigation

-(void)updateNavButtons {
	
	
	UISegmentedControl *segControl = (UISegmentedControl *)self.navigationItem.rightBarButtonItem.customView;

	// back
	
	if (theWebView.canGoBack) {
		[segControl setEnabled:YES forSegmentAtIndex:0];
	}
	else {
		[segControl setEnabled:NO forSegmentAtIndex:0];
	}
	
	
	// forward
	
	if (theWebView.canGoForward) {
		[segControl setEnabled:YES forSegmentAtIndex:1];
	}
	else {
		[segControl setEnabled:NO forSegmentAtIndex:1];
	}
	
}

-(IBAction)goBack {
	
	// go back
	
	[theWebView goBack];

}

-(IBAction)goForward {
	
	// go....forward....
	
	[theWebView goForward];
	
}

-(IBAction)navigateWebView:(id)sender {
	
	// depending on what the user did
	
	//cast and determine whether to go forward or back
	UISegmentedControl *segControl = (UISegmentedControl *)sender;
	
	// or use a switch?  could this be called with anything else but 0 or 1?
	
	if ([segControl selectedSegmentIndex] == 0) {
		// NSLog(@"Tapped Back");
		[theWebView goBack];
	}
	else {
		// NSLog(@"Tapped Forward");
		[theWebView goForward];
	}

	
}

@end
