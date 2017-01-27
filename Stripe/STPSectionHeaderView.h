//
//  STPSectionHeaderView.h
//  Stripe
//
//  Created by Ben Guo on 1/3/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPTheme.h"

@interface STPSectionHeaderView : UIView

@property(nonatomic, nonnull)STPTheme *theme;
@property(nonatomic, nullable)NSString *title;
@property(nonatomic, nullable, weak)UIButton *button;

@end
