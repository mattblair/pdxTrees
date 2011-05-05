//
//  CaptionedImageViewController.h
//  pdxTreesCD
//
//  Created by Matt Blair on 10/2/10.
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


@interface CaptionedImageViewController : UIViewController {
	
	// Data
	
	UIImage *thePhoto;
	NSString *captionString;
	
	
	// UI
	UILabel *captionLabel;
	UIImageView *imageView;

}

@property(nonatomic,retain) UIImage *thePhoto;
@property(nonatomic,retain) NSString *captionString;

@property(nonatomic,retain) IBOutlet UILabel *captionLabel;
@property(nonatomic,retain) IBOutlet UIImageView *imageView;

- (id)initWithImage:(UIImage *)image caption:(NSString *)caption;

@end