//
//  TreeDetailViewController.h
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

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>  // for email sharing
#import "Tree.h"
#import "ImageSubmitViewController.h"

@class ASIHTTPRequest;
@class ASINetworkQueue;

// added UINavigationControllerDelegate protocol to surpress warning from UIImagePicker
@interface TreeDetailViewController : UIViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, ImageSubmitDelegate, UINavigationControllerDelegate> { 

	// Data
	Tree *tree;
	
	NSMutableArray *treeImageList;
	NSMutableArray *treeThumbnails;
	NSMutableArray *treePhotos;	
	NSMutableArray *treePhotosReceived;
	
	// Detail Display UI
	UILabel *commonNameLabel;
	UILabel *scientificNameLabel;
	UILabel *locationNameLabel;
	UILabel *notesLabel;
	UILabel *heightLabel;
	UILabel *circumferenceLabel;
	UILabel *diameterLabel;
	UILabel *spreadLabel;
	UILabel *yearLabel;
	
	// Photo Display UI
	UIButton *image1Button;
	UIButton *image2Button;
	UIButton *image3Button;
	UIButton *image4Button;	
	UIButton *addPhotoButton;

	// Show Activity
	UILabel *fetchingLabel;
	UIActivityIndicatorView *fetchingSpinner;
	
	// Manage Requests
	ASIHTTPRequest *imageListRequest;
	ASINetworkQueue *imageRequestQueue;
    BOOL usePhotoDownloadController;  // temporary -- for field testing only
	
	BOOL showImageSubmitNext; // to manage the display of ImageSubmit VC after an image is selected
	NSString *selectedPhotoPath;
}

// Data

@property (nonatomic, retain) Tree *tree;
@property (nonatomic, retain) NSMutableArray *treeImageList;
@property (nonatomic, retain) NSMutableArray *treeThumbnails;
@property (nonatomic, retain) NSMutableArray *treePhotos;	
@property (nonatomic, retain) NSMutableArray *treePhotosReceived;
@property (nonatomic, retain) NSString *selectedPhotoPath;

// Detail Display UI

@property (nonatomic, retain) IBOutlet UILabel *commonNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *scientificNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *locationNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *notesLabel;
@property (nonatomic, retain) IBOutlet UILabel *heightLabel;
@property (nonatomic, retain) IBOutlet UILabel *circumferenceLabel;
@property (nonatomic, retain) IBOutlet UILabel *diameterLabel;
@property (nonatomic, retain) IBOutlet UILabel *spreadLabel;
@property (nonatomic, retain) IBOutlet UILabel *yearLabel;

// Photo Display UI

@property (nonatomic, retain) IBOutlet UIButton *image1Button;
@property (nonatomic, retain) IBOutlet UIButton *image2Button;
@property (nonatomic, retain) IBOutlet UIButton *image3Button;
@property (nonatomic, retain) IBOutlet UIButton *image4Button;	
@property (nonatomic, retain) IBOutlet UIButton *addPhotoButton;

@property(nonatomic, retain) IBOutlet UILabel *fetchingLabel;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *fetchingSpinner;


@property(retain) ASIHTTPRequest *imageListRequest;
@property(retain) ASINetworkQueue *imageRequestQueue;

@property(nonatomic) BOOL usePhotoDownloadController; // temporary -- for field testing only


// fetching Photos
- (void)initPhotoRequests;
- (void)killQueue;


// user-initiated actions
- (IBAction)shareTree:(id)sender;
- (IBAction)addPhoto:(id)sender;
- (IBAction)viewPhotos:(id)sender;
- (IBAction)showWikipedia:(id)sender;

// mail delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;

// ImageSubmitDelegate
- (void)imageSubmitViewControllerDidFinish:(ImageSubmitViewController *)controller withSubmission:(BOOL)photoSubmitted;


@end
