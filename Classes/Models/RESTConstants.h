//
//  RESTConstants.h
//  pdxTrees
//
//  Created by Matt Blair on 2/4/11.
//  Copyright 2011 Elsewise LLC. 
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

extern NSString * const kAPIUsername;
extern NSString * const kAPIPassword;
extern NSString * const kURLForPhotoSubmission;
extern NSString * const kAPIHostAndPath;

extern NSString * const kSubmissionEmailAddress;
extern NSString * const kEmailFooter;


// migrating to CouchDB submissions

extern NSString * const kCouchURLForPhotoSubmission;
extern NSString * const kCouchUsername;
extern NSString * const kCouchPassword;

// couch photo submission keys

extern NSString * const kPhotoRelatedTreeIDKey;
extern NSString * const kPhotoRelatedCouchIDKey;
extern NSString * const kPhotoDateSubmittedKey;
extern NSString * const kPhotoReviewStatusKey;
extern NSString * const kPhotoCaptionKey;
extern NSString * const kPhotoSubmitterNameKey;
extern NSString * const kPhotoSubmitterEmailKey;
extern NSString * const kPhotoUserAgentKey;

// couch photo submission default values

extern NSString * const kPhotoReviewStatusDefault;

/*

To build and run the app, you need to create a file 
 called RESTConstants.m and add it to your target.
 
It should look like this, with values customized to your situation:

// 
//  RESTConstants.m
//  pdxTrees
 
#import "RESTConstants.h"
 
 
NSString * const kAPIUsername = @"username";
NSString * const kAPIPassword = @"password";
 
 
NSString * const kURLForPhotoSubmission = @"http://pdxtrees.org/api/v1/treeimages/";  
 
NSString * const kAPIHostAndPath = @"pdxtrees.org/api/v1/treeimages/"; 
 
// email submissions
NSString * const kSubmissionEmailAddress = @"admin@pdxtrees.org";
NSString * const kEmailFooter = @"\n\n\n-----\nSent via the PDX Trees app\nFor more info, visit: http://pdxtrees.org";
 
 
//migrating to Couch
 
//insecure
NSString * const kCouchURLForPhotoSubmission = @"http://elsewise.iriscouch.com/pdx_trees_photo_submissions";  // insecure


NSString * const kCouchUsername = @"TBD";
NSString * const kCouchPassword = @"TBD";

// couch photo submission keys

NSString * const kPhotoRelatedTreeIDKey = @"relatedTreeID";
NSString * const kPhotoRelatedCouchIDKey = @"relatedCouchID";
NSString * const kPhotoDateSubmittedKey = @"dateSubmitted";
NSString * const kPhotoReviewStatusKey = @"reviewStatus";
NSString * const kPhotoCaptionKey = @"caption";
NSString * const kPhotoSubmitterNameKey = @"submitterName";
NSString * const kPhotoSubmitterEmailKey = @"submitterEmail";
NSString * const kPhotoUserAgentKey = @"userAgent";

// couch photo submission default values

NSString * const kPhotoReviewStatusDefault = @"pending"; 
 
*/