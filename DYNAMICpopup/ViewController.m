//
//  ViewController.m
//  DYNAMICpopup
//
//  Created by mobinex on 20/08/15.
//  Copyright (c) 2015 Mobinex. All rights reserved.
//

#import "ViewController.h"
#import "DYNAMICpopup.h"

@interface ViewController ()
{
    DYNAMICpopup *naber;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    contentView.backgroundColor = [UIColor greenColor];
    
    naber = [[DYNAMICpopup alloc] init:contentView];
    [[[[UIApplication sharedApplication] delegate] window] addSubview:naber];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showPopUp:(id)sender {
    [naber show:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2)];
}
@end
