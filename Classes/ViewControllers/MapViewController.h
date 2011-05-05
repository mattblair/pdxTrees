//
//  MapViewController.h
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

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapViewController : UIViewController <MKMapViewDelegate, NSFetchedResultsControllerDelegate, CLLocationManagerDelegate> {

	MKMapView *treeMapView;
	UIButton *infoButton;
	
    CLLocationManager *locationManager;		
	
	BOOL locationReallyEnabled;  // to handle CL behavior in iOS 4.1
	
@private
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;	
	
}

@property (nonatomic, retain) IBOutlet MKMapView *treeMapView;
@property (nonatomic, retain) IBOutlet UIButton *infoButton;

@property (nonatomic, retain) CLLocationManager *locationManager;


@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

- (void)refreshTreesOnMap;

- (void)adjustMapRegion;

- (NSArray *)treeListForMapRegion:(MKCoordinateRegion)region maximumCount:(NSInteger)maxCount;
- (NSArray *)buildTreeMapAnnotationArray:(NSArray *)managedObjectArray;

// User-initiated actions
- (IBAction)showAboutPage:(id)sender;

@end
