//
//  PBRMaterial.h
//  third_ar_custom
//
//  Created by yunfenghan Ling on 2017/10/13.
//  Copyright © 2017年 lingyfh. All rights reserved.
//

#import <Foundation/Foundation.h>
@import SceneKit;

@interface PBRMaterial : NSObject
+ (SCNMaterial *)materialNamed:(NSString *)name;
@end
