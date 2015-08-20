//
//  DYNAMICpopup.m
//  DYNAMICpopup
//
//  Created by mobinex on 20/08/15.
//  Copyright (c) 2015 Mobinex. All rights reserved.
//

#import "DYNAMICpopup.h"

@implementation DYNAMICpopup{
    UIView *_contentView;
    UIImageView *_backgroundView;
}

-(id)init:(UIView *)contentView{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [panGesture setDelegate:self];
        [panGesture setMaximumNumberOfTouches:1];
        
       
        
        _animator = [[UIDynamicAnimator alloc]
                     initWithReferenceView:self];
        
        _backgroundView = [[UIImageView alloc] initWithFrame:self.frame];
        [self addSubview:_backgroundView];
        
        _contentView = contentView;
        [_contentView addGestureRecognizer:panGesture];
        [self addSubview:_contentView];
        
        self.alpha = 0;
    }
    return self;
}

-(UIImage *)getBlur{
    
    UIGraphicsBeginImageContext([[[UIApplication sharedApplication] delegate] window].bounds.size);
    [[[[UIApplication sharedApplication] delegate] window].layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Blur the image
    CIImage *blurImg = [CIImage imageWithCGImage:viewImg.CGImage];
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:blurImg forKey:@"inputImage"];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:clampFilter.outputImage forKey: @"inputImage"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat:10.0f] forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImg = [context createCGImage:gaussianBlurFilter.outputImage fromRect:[blurImg extent]];
    UIImage *outputImg = [UIImage imageWithCGImage:cgImg];
    
    //Add UIImageView to current view.
    return outputImg;
}
-(void)show:(CGPoint)viewPoint{
    _backgroundView.image = [self getBlur];
    
    _contentView.center = CGPointMake(self.frame.size.width/2, -_contentView.frame.size.height);
    [_contentView setUserInteractionEnabled:YES];
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        [_animator removeAllBehaviors];
        
        UISnapBehavior *snap =
        [[UISnapBehavior alloc]initWithItem:_contentView snapToPoint:viewPoint];
        
        snap.damping = 0.5;
        [_animator addBehavior:snap];
    }];
}

- (void)handlePan:(UIPanGestureRecognizer*)gesture {
    static UIAttachmentBehavior *attachment;
    static CGPoint               startCenter;
    
    // variables for calculating angular velocity
    
    static CFAbsoluteTime        lastTime;
    static CGFloat               lastAngle;
    static CGFloat               angularVelocity;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.animator removeAllBehaviors];
        
        startCenter = gesture.view.center;
        
        // calculate the center offset and anchor point
        
        CGPoint pointWithinAnimatedView = [gesture locationInView:gesture.view];
        
        UIOffset offset = UIOffsetMake(pointWithinAnimatedView.x - gesture.view.bounds.size.width / 2.0,
                                       pointWithinAnimatedView.y - gesture.view.bounds.size.height / 2.0);
        
        CGPoint anchor = [gesture locationInView:gesture.view.superview];
        
        // create attachment behavior
        
        attachment = [[UIAttachmentBehavior alloc] initWithItem:gesture.view
                                               offsetFromCenter:offset
                                               attachedToAnchor:anchor];
        
        // code to calculate angular velocity (seems curious that I have to calculate this myself, but I can if I have to)
        
        lastTime = CFAbsoluteTimeGetCurrent();
        lastAngle = [self angleOfView:gesture.view];
        
        typeof(self) __weak weakSelf = self;
        
        attachment.action = ^{
            CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
            CGFloat angle = [weakSelf angleOfView:gesture.view];
            if (time > lastTime) {
                angularVelocity = (angle - lastAngle) / (time - lastTime);
                lastTime = time;
                lastAngle = angle;
            }
        };
        
        // add attachment behavior
        
        [self.animator addBehavior:attachment];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        // as user makes gesture, update attachment behavior's anchor point, achieving drag 'n' rotate
        
        CGPoint anchor = [gesture locationInView:gesture.view.superview];
        attachment.anchorPoint = anchor;

    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self.animator removeAllBehaviors];
        
        CGPoint velocity = [gesture velocityInView:gesture.view.superview];
        CGPoint pointt = [gesture translationInView:gesture.view];
    
        // if we aren't dragging it down, just snap it back and quit
        if (sqrt(fabs(pointt.x) *fabs(pointt.x) + fabs(pointt.y)* fabs(pointt.y)) < self.frame.size.width/5){
            UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:gesture.view snapToPoint:startCenter];
            [self.animator addBehavior:snap];
            
            return;
        }
        // otherwise, create UIDynamicItemBehavior that carries on animation from where the gesture left off (notably linear and angular velocity)
        
        UIDynamicItemBehavior *dynamic = [[UIDynamicItemBehavior alloc] initWithItems:@[gesture.view]];
        [dynamic addLinearVelocity:velocity forItem:gesture.view];
        [dynamic addAngularVelocity:angularVelocity forItem:gesture.view];
        [dynamic setAngularResistance:1.25];
        
        // when the view no longer intersects with its superview, go ahead and remove it
        
        
        typeof(self) __weak weakSelf = self;
        dynamic.action = ^{
            if (!CGRectIntersectsRect(gesture.view.superview.bounds, gesture.view.frame)) {
                [weakSelf.animator removeAllBehaviors];
                [UIView animateWithDuration:0.5 animations:^{
                    self.alpha =0;
                } completion:^(BOOL finished) {
                    
                }];
                //[[[UIAlertView alloc] initWithTitle:nil message:@"View is gone!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        };
        [self.animator addBehavior:dynamic];
       
        // add a little gravity so it accelerates off the screen (in case user gesture was slow)
        
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[gesture.view]];
        gravity.magnitude = 0.7;
        [self.animator addBehavior:gravity];
        [gesture.view setUserInteractionEnabled:NO];
    }
}

- (CGFloat)angleOfView:(UIView *)view
{
    return atan2(view.transform.b, view.transform.a);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
