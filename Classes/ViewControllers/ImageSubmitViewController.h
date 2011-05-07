//
//  ImageSubmitViewController.h
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

#import <UIKit/UIKit.h>
#import "Tree.h"

@class ASIFormDataRequest;
@class Reachability;

@protocol ImageSubmitDelegate;

@interface ImageSubmitViewController : UIViewController <UITextFieldDelegate, MFMailComposeViewControllerDelegate> {
	
	// data
	
	Tree *tree;
	NSString *localPhotoPath;
	
	// UI
	
	UITextField *captionTextField;
	UITextField *nameTextField;
	UITextField *emailTextField;
	//UITextField	*urlTextField;
	
	UITextField	*currentTextField;   // for keyboard management
	
	UILabel *ccExplainerLabel;
	
	UIImageView *theImageView;
	
	UIBarButtonItem *cancelButton;
	UIBarButtonItem *saveButton;
	
	BOOL userTappedCancel;
	
	UIActivityIndicatorView *submittingSpinner;
	
	// modal display management
	id <ImageSubmitDelegate> delegate;
	
	// directly manage the request
	ASIFormDataRequest *imageSubmitRequest;
	
    // migrating to Couch
    BOOL sentToCouch;
    
	// managing Reachability
    Reachability* internetReach;
	
}

// data

@property (nonatomic, retain) Tree *tree;
@property (nonatomic, retain) NSString *localPhotoPath;

// UI

@property(nonatomic, retain) IBOutlet UITextField *captionTextField;
@property(nonatomic, retain) IBOutlet UITextField *nameTextField;
@property(nonatomic, retain) IBOutlet UITextField *emailTextField;

@property(nonatomic, retain) IBOutlet UITextField *currentTextField;  // for keyboard management 

@property(nonatomic, retain) IBOutlet UILabel *ccExplainerLabel;

@property(nonatomic, retain) IBOutlet UIImageView *theImageView;


@property(nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem *saveButton;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *submittingSpinner;

@property(nonatomic, retain) id <ImageSubmitDelegate> delegate;

@property(retain) ASIFormDataRequest *imageSubmitRequest;

// migrating to Couch
@property (nonatomic) BOOL sentToCouch;

-(IBAction)cancelPhoto:(id)sender;
-(IBAction)submitPhoto:(id)sender;
-(void)killRequest;

// migrating to Couch

- (IBAction)submitPhotoMetadataToCouch:(id)sender;

@end

@protocol ImageSubmitDelegate

	// handle return from this VC
	- (void)imageSubmitViewControllerDidFinish:(ImageSubmitViewController *)controller withSubmission:(BOOL)photoSubmitted;

@end