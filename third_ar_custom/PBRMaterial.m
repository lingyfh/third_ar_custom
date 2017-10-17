//
//  PBRMaterial.m
//  third_ar_custom
//
//  Created by yunfenghan Ling on 2017/10/13.
//  Copyright © 2017年 lingyfh. All rights reserved.
//

#import "PBRMaterial.h"

static NSMutableDictionary *materials;

@implementation PBRMaterial

+ (void)init {
    materials = [NSMutableDictionary new];
}

+ (SCNMaterial *)materialNamed:(NSString *)name {
    SCNMaterial *mat =materials[name];
    if (mat) {
        return mat;
    }
    
    mat = [SCNMaterial new];
    mat.lightingModelName = SCNLightingModelPhysicallyBased;
    mat.diffuse.contents = [UIImage imageNamed:[NSString stringWithFormat:@"./Assets.scnassets/Materials/%@/%@-albedo.png", name, name]];
    mat.roughness.contents = [UIImage imageNamed:[NSString stringWithFormat:@"./Assets.scnassets/Materials/%@/%@-roughness.png", name, name]];
    mat.metalness.contents = [UIImage imageNamed:[NSString stringWithFormat:@"./Assets.scnassets/Materials/%@/%@-metal.png", name, name]];
    mat.normal.contents = [UIImage imageNamed:[NSString stringWithFormat:@"./Assets.scnassets/Materials/%@/%@-normal.png", name, name]];
    mat.diffuse.wrapS = SCNWrapModeRepeat;
    mat.diffuse.wrapT = SCNWrapModeRepeat;
    mat.roughness.wrapS = SCNWrapModeRepeat;
    mat.roughness.wrapT = SCNWrapModeRepeat;
    mat.metalness.wrapS = SCNWrapModeRepeat;
    mat.metalness.wrapT = SCNWrapModeRepeat;
    mat.normal.wrapS = SCNWrapModeRepeat;
    mat.normal.wrapT = SCNWrapModeRepeat;
    
    materials[name] = mat;
    return mat;
}

@end
