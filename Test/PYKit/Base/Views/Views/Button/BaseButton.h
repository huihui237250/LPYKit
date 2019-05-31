//
//  BaseButton.h
//  PYKit
//
//  Created by 李鹏跃 on 2018/9/11.
//  Copyright © 2018年 13lipengyue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseButtonHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface BaseButton : UIButton
@property (nonatomic,assign) BOOL isShowHighlighted;
- (void) setupHandler: (void(^)(BaseButtonHandler *handler))block;
@end

NS_ASSUME_NONNULL_END
