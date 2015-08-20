//
//  DYNAMICpopup.h
//  DYNAMICpopup
//
//  Created by mobinex on 20/08/15.
//  Copyright (c) 2015 Mobinex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DYNAMICpopup : UIView <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIDynamicAnimator *animator;

-(id)init:(UIView *)contentView;
-(void)show:(CGPoint)viewPoint;

@end
