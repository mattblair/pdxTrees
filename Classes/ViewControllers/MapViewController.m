//
//  MapViewController.m
//  pdxTrees
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

#import "MapViewController.h"
#import "Tree.h"
#import "TreeMapAnnotation.h"
#import "TreeDetailViewController.h"
#import "WebViewController.h"

// related to zooming on no trees found
#define kLatitudeDeltaThreshold 0.03
#define kWidenMapViewIncrement 1.2


// region for default view
#define kDefaultRegionLatitude 45.521203;
#define kDefaultRegionLongitude -122.681665

#define kDefaultRegionLatitudeDelta 0.025017
#define kDefaultRegionLongitudeDelta 0.027466


@implementation MapViewController

@synthesize treeMapView, infoButton, locationManager;

// used to synthesize fetchedResultsController=fetchedResultsController_
@synthesize managedObjectContext=managedObjectContext_;


#pragma mark -
#pragma mark User-initiated actions

- (IBAction)showAboutPage:(id)sender {
	
	WebViewController *webVC = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
	
	webVC.aboutMode = YES;  // i.e. not Wikipedia mobile pages
	
	[self.navigationController pushViewController:webVC animated:YES];
	
	[webVC release];

}

#pragma mark -
#pragma mark Map-related

- (void)adjustMapRegion {
	
	
	// Tests for a truly valid current location. 
	// If available, sets newRegion to center on the current location. If not, sets newRegion to default.
	// After moving map to newRegion, requests a re-population of the tree placemarks.
	
	/*
	 
	 From the metadata posted along with the tree file, the scope of the current data is:
	 
	 West bounding coordinate      -123.47121656
	 East bounding coordinate      -121.65053671
	 North bounding coordinate      45.82618832
	 South bounding coordinate      44.85462409 
	 
	 That yields a center of:
	 
	 Latitude: 45.340406
	 Longitude: -122.56087
	 
	 which doesn't make sense, because it's way down in Oregon City.
	 
	 Instead, I'm using a point around 
	 Latitude:  45.530675
	 Longitude: -122.626691
	 
	 And a radius of 14 km to determine if the user is within the data.
	 
	 */
	
	
	MKCoordinateRegion newRegion;
	
	// set defaults for the current location criteria
	BOOL locationTurnedOn = [CLLocationManager locationServicesEnabled];  // not reliable in iOS 4.1? check locationReallyEnabled
	BOOL locationAccurateEnough = NO;
	BOOL locationInDataRadius = NO;
	
	if (locationTurnedOn) {
		
		
		// NSLog(@"Location services on...");
		
		// test and test the other two criteria
		
		// [[[self treeMapView] userLocation] location] won't work -- doesn't have timestamp or accuracy
		CLLocation *currentLocation = [[self locationManager] location];
		
		NSDate *newLocationDate = currentLocation.timestamp;
		NSTimeInterval timeDiff = [newLocationDate timeIntervalSinceNow];
		
		
		// NSLog(@"Current location has an accuracy radius of %f meters.", currentLocation.horizontalAccuracy);
		
		// horizontal accuracy is a radius in meters. Is 100 too much? 
		// a negative value indicates an invalid coordinate
		
		// changed this to >= 2.0 because it is returning 0.0 on failure in iOS 4.1, not a negative number
		if ((abs(timeDiff) < 15.0) && (currentLocation.horizontalAccuracy < 101.0) && (currentLocation.horizontalAccuracy >= 2.0)) {
			
			locationAccurateEnough = YES;
			// NSLog(@"Current location is accurate enough.");
			
		}
		
		
		// use CLLocation method: - (CLLocationDistance)distanceFromLocation:(const CLLocation *)location
		// returns a CLLocationDistance, which is meters as a double
		
		// TESTING ONLY -- since I can't go there, I'm testing with a center location well south of here
		//CLLocation *pdxCenterLocation = [[CLLocation alloc] initWithLatitude:40.530675 longitude:-122.626691];
		
		// production
		CLLocation *pdxCenterLocation = [[CLLocation alloc] initWithLatitude:45.530675 longitude:-122.626691];
		
		
		CLLocationDistance locationDiff = [currentLocation distanceFromLocation:pdxCenterLocation];
		
		// NSLog(@"Location difference is %f meters", locationDiff);
		
		if (locationDiff < 14000.0) {
			
			// they are less than 14k from rough center of Portland data
			locationInDataRadius = YES;
			
			// NSLog(@"Location is within 14km of data set's center.");
			
		}
		
		[pdxCenterLocation release];
		
   		// added because of CL behavior in 4.1
        // Series of crude bounds tests for far-away locations that return 0.0 from distanceFromLocation method
		// These should also be future-proof for when CL returns expected values
		
		CLLocationCoordinate2D currentCoordinate = [currentLocation coordinate];
		
		if (currentCoordinate.latitude < 45.0 ) {  //i.e. if it is zero...
			locationInDataRadius = NO;
			// NSLog(@"Latitude was less than 45 degrees!");
		}
		
		if (currentCoordinate.latitude > 46.0 ) {  
			locationInDataRadius = NO;
			// NSLog(@"Latitude was more than 46 degrees!");
		}
		
		if (currentCoordinate.longitude < -123.0 ) {  
			locationInDataRadius = NO;
			// NSLog(@"Longitude was less than -123 degrees!");
		}
		
		if (currentCoordinate.longitude > -122.0 ) {  //i.e. if it is zero...
			locationInDataRadius = NO;
			// NSLog(@"Longitude was greater than -122 degrees!");
		}
		
	}
		

		
	if (locationTurnedOn && locationReallyEnabled && locationAccurateEnough && locationInDataRadius) {
		
		// define region based on user location
		// NSLog(@"All criteria met to base region on User Location");
		
		newRegion.center = [[[self locationManager] location] coordinate]; // handles lat/long

		newRegion.span.latitudeDelta = 0.011;  // too close? if so, match to below

		newRegion.span.longitudeDelta = 0.014; // too close? if so...
		
	}
	
	else {
		
		// default region
		// NSLog(@"No acceptable/local location found. Using default region.");

		newRegion.center.latitude = kDefaultRegionLatitude;
		
		newRegion.center.longitude = kDefaultRegionLongitude;
		
		newRegion.span.latitudeDelta = kDefaultRegionLatitudeDelta;
		
		newRegion.span.longitudeDelta = kDefaultRegionLongitudeDelta;
		
	}
	
	
	// now process the new region
	// NSLog(@"Moving to new region");
	
	// correct the aspect ratio
	MKCoordinateRegion fitRegion = [self.treeMapView regionThatFits:newRegion];
	
    [self.treeMapView setRegion:fitRegion animated:YES];
	
	
	// Reload the trees on the map
	[self refreshTreesOnMap];
	
	// This should be turned off by the previous method call, but it seems like that is happening at the same time
	// the region is changing, and the button is ending up enabled. Force the issue...
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	
}


#pragma mark -
#pragma mark MapView Delegate

- (void)mapView:(MKMapView *)map regionDidChangeAnimated:(BOOL)animated {
	
	// let the user refresh on demand after moving map
	
	self.navigationItem.rightBarButtonItem.enabled = YES;
	
	// uncomment this to see every region change in the console
	
	/*
	NSLog(@"Map view changed to new region...");
	NSLog(@"This region's latitude is: %f", map.region.center.latitude);
	NSLog(@"This region's longitude is: %f", map.region.center.longitude);
	NSLog(@"This region's latitude delta is: %f", map.region.span.latitudeDelta);
	NSLog(@"This region's longitude delta is: %f", map.region.span.longitudeDelta);
	*/
	
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
	
	// NSLog(@"Creating a pin for a tree...");
	
	// Try to dequeue an existing pin view first.
	MKPinAnnotationView* pinView = (MKPinAnnotationView*)[mapView
															 dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
	
	if (!pinView)
	{
		// If an existing pin view was not available, create one.
		pinView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation
												   reuseIdentifier:@"CustomPinAnnotationView"] 
				   autorelease];
		pinView.pinColor = MKPinAnnotationColorGreen;
		pinView.animatesDrop = YES;
		pinView.canShowCallout = YES;
		
		UIButton* rightButton = [UIButton buttonWithType:
								 UIButtonTypeDetailDisclosure];
		
		pinView.rightCalloutAccessoryView = rightButton;
	}
	
	return pinView;

}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	
	//get access to the original annotation
	
	TreeMapAnnotation *selectedTree = view.annotation;
	
	// NSLog(@"The ID of the selected Tree is: %@", [selectedTree treeID]);

	
	TreeDetailViewController *tdvc = [[TreeDetailViewController alloc] initWithNibName:@"TreeDetailViewController" bundle:nil];
	
	// hand over the tree object	
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Tree" inManagedObjectContext:self.managedObjectContext]];
	
	// search predicate based on box ID
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"treeID=%@", [selectedTree treeID]];
    [fetchRequest setPredicate:predicate];
	
	// don't want faults
	[fetchRequest setReturnsObjectsAsFaults:NO];
	
	NSError *error = nil;
    NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedItems == nil)
    {
        // an error occurred
        NSLog(@"Fetch request returned nil. Error: %@, %@", error, [error userInfo]);
    }
    else  {
		
		tdvc.tree = [fetchedItems objectAtIndex:0];
        
        // add UISwitch somewhere for field testing?
        tdvc.usePhotoDownloadController = YES;
			
		[self.navigationController pushViewController:tdvc animated:YES];
			
	}
	
	[fetchRequest release];
		
	[tdvc release];
	
	
}

#pragma mark -
#pragma mark Location Manager Delegate


// based on Photo Locations sample code and Location Awareness PG

/**
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
	
    if (locationManager != nil) {
		return locationManager;
	}
	
	locationManager = [[CLLocationManager alloc] init];
	[locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters]; // or kCLLocationAccuracyNearestTenMeters?
	[locationManager setDelegate:self];
	
	return locationManager;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
	// check how recent the location is
	
	NSDate *newLocationDate = newLocation.timestamp;
	NSTimeInterval timeDiff = [newLocationDate timeIntervalSinceNow];
	
	// For Troubleshooting
	// NSLog(@"Coordinate received with accuracy radius of %f meters.", newLocation.horizontalAccuracy);

	// horizontal accuracy is a radius in meters. Is 100 too much? 
	// a negative value indicates an invalid coordinate

	// changed to greater than 2 because of behavior in 4.1
	
	if ((abs(timeDiff) < 15.0) && (newLocation.horizontalAccuracy < 100.0) && (newLocation.horizontalAccuracy >= 2.0))
	{
		
		
		// turn this on as needed for troubleshooting
		//NSLog(@"Recent and accurate location received...");
		//NSLog(@"The new location's latitude is: %f", newLocation.coordinate.latitude);
		//NSLog(@"The new location's longitude is: %f", newLocation.coordinate.longitude);
		
		
		locationReallyEnabled = YES;  // to handle CL behavior in iOS 4.1
		
		
	}	
	
	
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
	// handle location failure -- with user notification? Or silently?
	
	/*
	NSLog(@"Location Failure.");
	NSLog(@"Error: %@", [error localizedDescription]);
	NSLog(@"Error code %d in domain: %@", [error code], [error domain]);
	*/
	
	
	// because locationServicesEnabled class method is erratic in 4.1, need to handle this here
	
	
	// set a bool on the VC that tells it location has failed.
	
	if (([error code] == 1) && ([[error domain] isEqualToString:@"kCLErrorDomain"])) {
		locationReallyEnabled = NO;  // to handle CL behavior in iOS 4.1
		
		// does it stop updating automatically?
		
		[[self locationManager] stopUpdatingLocation];
		
	}

}




#pragma mark -
#pragma mark Fetching and Drawing Trees

- (NSArray *)treeListForMapRegion:(MKCoordinateRegion)region maximumCount:(NSInteger)maxCount {
	
	// fetch a list of trees for the region
	
    NSMutableArray *treeList = [NSMutableArray array];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Tree" inManagedObjectContext:self.managedObjectContext]];
    
    NSNumber *latitudeStart = [NSNumber numberWithDouble:region.center.latitude - region.span.latitudeDelta/2.0];
    NSNumber *latitudeStop = [NSNumber numberWithDouble:region.center.latitude + region.span.latitudeDelta/2.0];
    NSNumber *longitudeStart = [NSNumber numberWithDouble:region.center.longitude - region.span.longitudeDelta/2.0];
    NSNumber *longitudeStop = [NSNumber numberWithDouble:region.center.longitude + region.span.longitudeDelta/2.0];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"latitude>%@ AND latitude<%@ AND longitude>%@ AND longitude<%@", latitudeStart, latitudeStop, longitudeStart, longitudeStop];
    [fetchRequest setPredicate:predicate];
    NSMutableArray *sortDescriptors = [NSMutableArray array];
    [sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"latitude" ascending:YES] autorelease]];
    [sortDescriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"longitude" ascending:YES] autorelease]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"latitude", @"longitude", @"commonName", @"scientificName", @"treeID", nil]];
    NSError *error = nil;
    NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedItems == nil)
    {
        // an error occurred
		[treeList removeAllObjects]; //return an empty array
        NSLog(@"fetch request resulted in an error %@, %@", error, [error userInfo]);
    }
    else
    {
		// add all fetched items to tree list 
		// NSLog(@"Count of items fetched: %d", [fetchedItems count]);

		/*
		// re-impliment to thin out pins in a dense area, or a wide view?
		// Need a better filter. 1/x would leave too many in dense areas and leave sparse areas empty.
		
		NSInteger countOfFetchedItems = [fetchedItems count];
		if (countOfFetchedItems > maxCount) {
			float index = 0, stride = (float)(countOfFetchedItems - 1)/ (float)maxCount;
			NSInteger countOfItemsToReturn = 0;
			while (countOfItemsToReturn < maxCount) {
				[treeList addObject:[fetchedItems objectAtIndex:(NSInteger)index]];
				index += stride;
				countOfItemsToReturn++;
			}
			
		}
		*/
		
		[treeList addObjectsFromArray:[self buildTreeMapAnnotationArray:fetchedItems]];
		 
	}	
    [fetchRequest release];

	
    return treeList;	
	
}


- (NSArray *)buildTreeMapAnnotationArray:(NSArray *)managedObjectArray {
	
	// make an array of annotations for the returned set of trees
	
	NSMutableArray *treeAnnotationList = [NSMutableArray array];
	
	if ([managedObjectArray count] > 0) {
		
		TreeMapAnnotation *tma = nil;
		
		for (Tree *theTree in managedObjectArray) {
			
			tma = [[TreeMapAnnotation alloc] init];
			
			[tma setTitle:[theTree commonName]];
			[tma setSubtitle:[theTree scientificName]]; // capital T in v1.0 caused this to fail
			[tma setLatitude:[theTree latitude]];
			[tma setLongitude:[theTree longitude]];	
			//NSLog(@"Making annotation for Tree ID %@", [theTree treeID]);
			[tma setTreeID:[theTree treeID]];
			
			[treeAnnotationList addObject:tma];
			
			[tma release];
			
		}
		
	}
	else {
		// return an empty array
		NSLog(@"No trees found in Managed Objects Array.");
		[treeAnnotationList removeAllObjects];
	}
	
	
	return treeAnnotationList;
	
}

- (void)refreshTreesOnMap {

	// reload the annotations for the current region
	
	// turn the button off to prevent multiple refreshes
	self.navigationItem.rightBarButtonItem.enabled = NO;
	
	NSArray *treeList = [self treeListForMapRegion:treeMapView.region maximumCount:12];  //maximumCount is not in use
	
	if ([treeList count] > 0) {
		
		//NSLog(@"%d trees found...", [treeList count]);
		NSArray *oldAnnotations = treeMapView.annotations;
		
		// want to wipe out all the trees but keep the user's location, because it can take a while to come back
		NSPredicate *userLocationPredicate = [NSPredicate predicateWithFormat:@"!(self isKindOfClass: %@)", [MKUserLocation class]];
		
		NSArray *annotationsToRemove = [oldAnnotations filteredArrayUsingPredicate:userLocationPredicate];
		[treeMapView removeAnnotations:annotationsToRemove];
		
		[treeMapView addAnnotations:treeList];
		
	}
	else {
		
		// NSLog(@"No trees found. Need to let user know...");
		
		// test span values here, and it they are too big, offer to move them closer to the city instead?
		
		double currentLatitudeDelta = self.treeMapView.region.span.latitudeDelta;
		
		if (currentLatitudeDelta > kLatitudeDeltaThreshold) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Trees Found" 
															message:@"There don't seem to be any Heritage Trees nearby, and you're already looking at a wide view. Would you like to go to the default view?" 
														   delegate:self 
												  cancelButtonTitle:@"No" 
												  otherButtonTitles:@"Yes", nil];
			[alert show];
			
			[alert release];
		}
		
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Trees Found" 
															message:@"There don't seem to be any Heritage Trees nearby. Would you like to widen the search of this area?" 
														   delegate:self 
												  cancelButtonTitle:@"No" 
												  otherButtonTitles:@"Yes", nil];
			[alert show];
			
			[alert release];
		}
		

	}
	
}



#pragma mark -
#pragma mark - Widen Search aka UIAlertView Delegate

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	// widen search if requested...
	
	if (buttonIndex == 1) {  // if they tapped yes

		// get the current region to alter it
		
		MKCoordinateRegion newRegion = self.treeMapView.region;
		
		double oldLatitudeDelta = newRegion.span.latitudeDelta;
		double oldLongitudeDelta = newRegion.span.longitudeDelta;
		
        // Even though it seems like they have a choice, they'll go to default if 
        // they are too far out anyway.
        
		if (oldLatitudeDelta > kLatitudeDeltaThreshold) {
			
			// go to default view
			
			newRegion.center.latitude = kDefaultRegionLatitude;
			newRegion.center.longitude = kDefaultRegionLongitude;
			
			newRegion.span.latitudeDelta = kDefaultRegionLatitudeDelta;
			newRegion.span.longitudeDelta = kDefaultRegionLongitudeDelta;
			
			
		}
		else {
			double newLatitudeDelta = oldLatitudeDelta * kWidenMapViewIncrement; 
			double newLongitudeDelta = oldLongitudeDelta * kWidenMapViewIncrement; 
			
			newRegion.span.latitudeDelta = newLatitudeDelta;
			newRegion.span.longitudeDelta = newLongitudeDelta;
		}

		
		
		MKCoordinateRegion fitRegion = [self.treeMapView regionThatFits:newRegion];
		
		[[self treeMapView] setRegion:fitRegion animated:YES];
		
		[self refreshTreesOnMap];
		
		// make sure Refresh is really turned off.
		self.navigationItem.rightBarButtonItem.enabled = NO;
		
		
	}
	
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.title = @"Heritage Trees";
	
	//setup the navigation bar buttons
	
	UIImage *locationImage = [UIImage imageNamed:@"74-location-invert"]; // don't need png in iOS 4 
	
    UIBarButtonItem *clButton = [[UIBarButtonItem alloc] initWithImage:locationImage 
																 style:UIBarButtonItemStylePlain 
																target:self 
																action:@selector(adjustMapRegion)];  
	self.navigationItem.leftBarButtonItem = clButton;
    [clButton release];
	
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																				   target:self 
																				   action:@selector(refreshTreesOnMap)];
	
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];
	
	
	
	
	// Start the location manager and put the user on the map
	
	if ([CLLocationManager locationServicesEnabled]) {
		// NSLog(@"About to turn Location on...");
		[[self locationManager] startUpdatingLocation];  		
		treeMapView.showsUserLocation = YES;
		locationReallyEnabled = YES;  // to handle CL behavior in iOS 4.1
	}
	else {
		// NSLog(@"Location not available, turning it off for the map.");
		treeMapView.showsUserLocation = NO;
		locationReallyEnabled = NO;  // to handle CL behavior in iOS 4.1
		
		// add alert here encouraging them to turn location on?
		
	}
	
	
	// And zoom to Portland
	[self adjustMapRegion];  // was goToDefaultLocation
	
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
    
    // Release any cached data, images, etc that aren't in use.
	
	// NSLog(@"MapViewController received a memory warning...");
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.treeMapView = nil;
    self.infoButton = nil;
}


- (void)dealloc {
	
	[treeMapView release];
	[infoButton release];
	
	[locationManager release];
	
    [super dealloc];
}


@end
