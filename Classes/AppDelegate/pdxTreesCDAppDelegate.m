//
//  pdxTreesCDAppDelegate.m
//  pdxTrees
//
//  Created by Matt Blair on 9/17/10.
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

#import "pdxTreesCDAppDelegate.h"
#import "MapViewController.h"
#import "JSON.h"
#import "Tree.h"


@implementation pdxTreesCDAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)awakeFromNib {    
    
	
	MapViewController *mapViewController = (MapViewController *)[navigationController topViewController];
    mapViewController.managedObjectContext = self.managedObjectContext;
	
	// When replacing a Root VC, go into the MainWindow.xib's Navigation Controller, and change the class indentity and NIB Name there.
	
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
	
	
	// fetch data here during development
	//NSLog(@"Preparing to import tree list...");
	
	//[self importTreeDetails];
	
	

    // Add the navigation controller's view to the window and display.
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    [self saveContext];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}


- (void)saveContext {
    
    NSError *error = nil;
    if (managedObjectContext_ != nil) {
        if ([managedObjectContext_ hasChanges] && ![managedObjectContext_ save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}    


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"pdxTreesCD" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
	// Verify existence of database, copy default database if needed
	
	NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"pdxTreesCD.sqlite"];    
    
	NSLog(@"The storePath is: %@", [storePath description]);
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		
		NSLog(@"No database found in app's documents directory...");
		
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"pdxTreesCD-100917" ofType:@"sqlite"];
		
		NSLog(@"The defaultStorePath is: %@", [defaultStorePath description]);
		
		if (defaultStorePath) {  //if there is a database at that location
			
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
			
			NSLog(@"Installed default database in app's documents directory...");
		}
	}
	
	
	// connect to database
	
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"pdxTreesCD.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}

#pragma mark -
#pragma mark Importing PDXAPI Tree List (Dev only)

- (NSArray *)readTreeDetailsFromJSONFile {

	// load a file with a partial set of trees and return an array of tree dicitonary objects
	
	
	NSString *filepath = [[NSBundle mainBundle] pathForResource:@"tree_details_5" ofType:@"json"];
	
	NSError *fileLoadError;
	
	NSString *treeDetails = [NSString stringWithContentsOfFile:filepath 
													  encoding:NSUTF8StringEncoding 
														 error:&fileLoadError];
	
	return [treeDetails JSONValue];

}

- (void)importTreeDetails {
	
	// get the array
	
	NSArray *treeDetailArray = [self readTreeDetailsFromJSONFile];
	
	for (NSDictionary *treeDict in treeDetailArray) {

		// create a new tree record
		
		Tree *newTree = nil;
		
		newTree = (Tree *)[NSEntityDescription insertNewObjectForEntityForName:@"Tree" 
														inManagedObjectContext:[self managedObjectContext]];
		
		// set required values
		
		
		// NSNumber *treeID;
		
		[newTree setTreeID:[NSNumber numberWithInt:[[treeDict valueForKey:@"treeid"] intValue]]];
		
		NSLog(@"Processing Tree number: %@", newTree.treeID);
		
		// Reach in for the latitude and longitude
		NSDictionary *geometryDict = [treeDict valueForKey:@"geometry"];
		
		NSArray *coordArray = [geometryDict valueForKey:@"coordinates"];
		
		// NSNumber *latitude;
		[newTree setLatitude:[NSNumber numberWithDouble:[[coordArray objectAtIndex:1] doubleValue]]];
		
		// NSNumber *longitude;
		[newTree setLongitude:[NSNumber numberWithDouble:[[coordArray objectAtIndex:0] doubleValue]]];
		
		// NSDate *lastEditDate;
		[newTree setLastEditDate:[NSDate date]];
		
		
		
		
		
		// set optional values
		
		// NSString *address;
		if (![[treeDict valueForKey:@"address"] isKindOfClass:[NSNull class]]) {
			[newTree setAddress:[treeDict valueForKey:@"address"]];
		}
		
		// NSNumber *circumference;
		[newTree setCircumference:[NSNumber numberWithDouble:[[treeDict valueForKey:@"circumfere"] doubleValue]]];
		
		// NSString *commonName;
		[newTree setCommonName:[treeDict valueForKey:@"common_nam"]];
		
		// NSString *couchID;
		[newTree setCouchID:[treeDict valueForKey:@"_id"]];
		
		// NSNumber *diameter;
		[newTree setDiameter:[NSNumber numberWithDouble:[[treeDict valueForKey:@"diameter"] doubleValue]]];
		
		// NSNumber *height;
		[newTree setHeight:[NSNumber numberWithDouble:[[treeDict valueForKey:@"height"] doubleValue]]];
		
		// NSNumber *spread;
		[newTree setSpread:[NSNumber numberWithDouble:[[treeDict valueForKey:@"spread"] doubleValue]]];
		
		// NSString *notes;
		
		if (![[treeDict valueForKey:@"notes"] isKindOfClass:[NSNull class]]) {   // if it's not null
			[newTree setNotes:[treeDict valueForKey:@"notes"]];  //it'd be nice to cap this here...
		}
		
		// NSString *ownerName;
		if (![[treeDict valueForKey:@"owner"] isKindOfClass:[NSNull class]]) {   // if it's not null
			[newTree setOwnerName:[treeDict valueForKey:@"owner"]];
		}
		
		// NSString *scientificName;
		[newTree setScientificName:[treeDict valueForKey:@"scientific"]];
		
		// NSString *stateID;
		if (![[treeDict valueForKey:@"stateid"] isKindOfClass:[NSNull class]]) {   // if it's not null
			[newTree setStateID:[treeDict valueForKey:@"stateid"]];
		}
		
		// NSNumber *yearDesignated;
		[newTree setYearDesignated:[NSNumber numberWithInt:[[treeDict valueForKey:@"year"] intValue]]];
		
		
		// save it
		
		NSError *error;
		if (![[self managedObjectContext] save:&error]) {
			NSLog(@"Error adding tree - error:%@",error);
			break;
		}
		
		
		
	}
	
	NSLog(@"Trees imported...");
	
}
				  

#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
    [navigationController release];
    [window release];
    [super dealloc];
}


@end

