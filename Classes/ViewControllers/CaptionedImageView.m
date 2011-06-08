//
//  CaptionedImageView.m
//  pdxTrees
//
//  Created by Matt Blair on 5/5/11.
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

#import "CaptionedImageView.h"


@implementation CaptionedImageView

// Data
//@synthesize thePhoto, captionString;

@synthesize index;

// UI
@synthesize captionLabel, imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

// this assumes you are setting it up for the first time -- just make this init instead of init with Frame?

- (void)displayImage:(UIImage *)image withCaption:(NSString *)caption andCredit:(NSString *)credit {
    
    self.backgroundColor = [UIColor blackColor];
    
    // clear the previous imageView -- but there wouldn't be one, since not loading from nib?
   /*
    [thumbnail removeFromSuperview];
    [thumbnail release];
    thumbnail = nil;
    */
    

    if (imageView) {
        [imageView removeFromSuperview];
        [imageView release];
        imageView = nil;
    }
    
    if (captionLabel) {
        [captionLabel removeFromSuperview];
        [captionLabel release];
        captionLabel = nil;
    }
    
    
    // you have a total of 380.0 points of height to play with
    // change these to constant values
    
    self.imageView = [[UIImageView alloc] initWithImage:image];
        
    self.imageView.frame = CGRectMake(0.0, 0.0, 320.0, 320.0);
    [self addSubview:self.imageView];
    
    // draw caption using NSString? what about accessibility?
    //[caption drawInRect:<#(CGRect)#> withFont:<#(UIFont *)#> lineBreakMode:<#(UILineBreakMode)#>];

    self.captionLabel = [[UILabel alloc] init];
    
    self.captionLabel.text = caption;
    
    self.captionLabel.textColor = [UIColor whiteColor];
    
    self.captionLabel.opaque = YES; // for performance
    
    self.captionLabel.numberOfLines = 3;
    
    self.captionLabel.font = [UIFont systemFontOfSize:12.0];
    
    self.captionLabel.backgroundColor = [UIColor blueColor]; //obviously for testing only, change to black?
    
    self.captionLabel.accessibilityLabel = @"Caption";
    
    self.captionLabel.accessibilityValue = caption;
    
    self.captionLabel.frame = CGRectMake(10.0, 322.0, 300.0, 58.0); // was 10,320,280,42
    
    [self addSubview:self.captionLabel];
    
    //NSLog(@"This should show credit for: %@ too!!!", credit);
    
}

- (void)dealloc
{
    [captionLabel release];
    [imageView release];
    
    [super dealloc];
}

@end
