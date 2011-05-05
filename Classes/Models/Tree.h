//
//  Tree.h
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

#import <CoreData/CoreData.h>


@interface Tree :  NSManagedObject  
{
	//required 
	
	NSNumber *treeID;
	NSNumber *latitude;
	NSNumber *longitude;
	NSDate *lastEditDate;
	
	// optional
	
	NSString *address;
	NSNumber *circumference;
	NSString *commonName;
	NSString *couchID;
	NSNumber *diameter;
	NSNumber *height;
	NSNumber *spread;
	NSString *notes;
	NSString *ownerName;
	NSString *scientificName;
	NSString *stateID;
	NSNumber *yearDesignated;
	
}

// required
@property (nonatomic, retain) NSNumber *treeID;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSDate *lastEditDate;

// optional
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSNumber *circumference;
@property (nonatomic, retain) NSString *commonName;
@property (nonatomic, retain) NSString *couchID;
@property (nonatomic, retain) NSNumber *diameter;
@property (nonatomic, retain) NSNumber *height;
@property (nonatomic, retain) NSNumber *spread;
@property (nonatomic, retain) NSString *notes;
@property (nonatomic, retain) NSString *ownerName;
@property (nonatomic, retain) NSString *scientificName;
@property (nonatomic, retain) NSString *stateID;
@property (nonatomic, retain) NSNumber *yearDesignated;

@end



