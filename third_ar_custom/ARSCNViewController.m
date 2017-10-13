//
//  ARSCNViewController.m
//  third_ar_custom
//
//  Created by yunfenghan Ling on 2017/10/13.
//  Copyright © 2017年 lingyfh. All rights reserved.
//

#import "ARSCNViewController.h"
@import ARKit;
@import SceneKit;

typedef NS_OPTIONS(NSUInteger, CollisionCategory) {
    CollisionCategoryBottom  = 1 << 0,
    CollisionCategoryCube    = 1 << 1,
};

@interface ARSCNViewController () <ARSCNViewDelegate, SCNPhysicsContactDelegate>
{
    ARSCNView *scnView;
    ARSession *arSession;
    ARWorldTrackingConfiguration *arConfig;
    
    NSMutableDictionary *planeNodes;
    NSMutableArray *cubes;
}
@property (weak, nonatomic) IBOutlet UISwitch *dectectionSwitch;
@end

@implementation ARSCNViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    planeNodes = [NSMutableDictionary new];
    cubes = [NSMutableArray new];
    
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (scnView != nil) {
        [scnView.session pause];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (scnView == nil) {
        scnView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
        [scnView setDelegate:self];
        scnView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        
        [scnView addGestureRecognizer:tap];
        
        SCNBox *box = [SCNBox boxWithWidth:1000 height:0.5 length:1000 chamferRadius:0];
        SCNMaterial *material = [SCNMaterial new];
        material.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0];
        box.materials = @[material];
        SCNNode *bottomNode = [SCNNode nodeWithGeometry:box];
        
        bottomNode.position = SCNVector3Make(0, -2, 0);
        bottomNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:nil];
        bottomNode.physicsBody.categoryBitMask = CollisionCategoryBottom;
        bottomNode.physicsBody.contactTestBitMask = CollisionCategoryCube;
        
        [scnView.scene.rootNode addChildNode:bottomNode];
        [scnView.scene.physicsWorld setContactDelegate:self];
        
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [scnView addGestureRecognizer:longPressGesture];
    }
    
    [self.view addSubview:scnView];
    
    if (arSession == nil) {
        arSession = [ARSession new];
    }
    
    if (arConfig == nil) {
        arConfig = [ARWorldTrackingConfiguration new];
    }
    arConfig.planeDetection = ARPlaneDetectionHorizontal;
    arConfig.lightEstimationEnabled = YES;
    scnView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
    
    [arSession runWithConfiguration:arConfig];
    
    scnView.session = arSession;
    
    [self.view bringSubviewToFront:_dectectionSwitch];
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"did add node");
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        NSLog(@"did add node is not plane anchor");
        return;
    }
    
    SCNMaterial *material = [SCNMaterial material];
    UIImage *img = [UIImage imageNamed:@"tron_grid.png"];
    material.diffuse.contents = img;
    
    
    ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
    SCNBox *planeBox = [SCNBox boxWithWidth:planeAnchor.extent.x height:0.01 length:planeAnchor.extent.z chamferRadius:0];
    // SCNPlane *plane = [SCNPlane planeWithWidth:planeAnchor.extent.x height:planeAnchor.extent.z];
    // plane.materials = @[material];
    
    planeBox.materials = @[];
    
    planeBox.materials = @[material];
    SCNNode *addPlaneNode = [SCNNode nodeWithGeometry:planeBox];
    addPlaneNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:planeBox options:nil]];
    
    addPlaneNode.position = SCNVector3Make(0, -0.01/2, 0);
    // addPlaneNode.transform = SCNMatrix4MakeRotation(-M_PI/2.0, 1.0, 0, 0);
    
    
    SCNNode *tempNode = [SCNNode node];
    [tempNode addChildNode:addPlaneNode];
    [node addChildNode:tempNode];
    
    [planeNodes setValue:tempNode forKey:planeAnchor.identifier.UUIDString];
}


- (void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    
    SCNNode *planeNode = [planeNodes objectForKey:anchor.identifier.UUIDString];
    if (planeNode == nil) {
        return;
    }
    planeNode = [[planeNode childNodes] firstObject];
    ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
    SCNBox *plane = (SCNBox *)planeNode.geometry;
    plane.width = planeAnchor.extent.x;
    plane.length = planeAnchor.extent.z;
    
    planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z);
    planeNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:plane options:nil]];
}

#pragma mark - SCNPhysicsContactDelegate
- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact {
    CollisionCategory contactMask = contact.nodeA.physicsBody.categoryBitMask | contact.nodeB.physicsBody.categoryBitMask;
    if (contactMask == (CollisionCategoryBottom | CollisionCategoryCube)) {
        if (contact.nodeA.physicsBody.categoryBitMask == CollisionCategoryBottom) {
            [contact.nodeB removeFromParentNode];
        } else{
            [contact.nodeA removeFromParentNode];
        }
    }
}

#pragma mark - Tap

- (void)handleTapFrom:(UITapGestureRecognizer *)gesture {
    CGPoint tapPoint = [gesture locationInView:scnView];
    
    NSArray<ARHitTestResult *> *result = [scnView hitTest:tapPoint types:ARHitTestResultTypeExistingPlane];
    if (result.count <= 0) {
        NSLog(@"hit test nothing");
        return;
    }
    
    NSLog(@"hit something");
    [self insertGeometry:result[0]];
}

#pragma mark - LongPress

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    NSLog(@"handleLongPress");
    CGPoint holdPoint = [gesture locationInView:scnView];
    
    NSArray<ARHitTestResult *> *result = [scnView hitTest:holdPoint types:ARHitTestResultTypeExistingPlane];
    
    if (result.count <= 0) {
        return;
    }
    NSLog(@"handleLongPress hit something");
    ARHitTestResult *hitResult = [result firstObject];
    
    [self explodeFrom:hitResult];
}

- (void)explodeFrom:(ARHitTestResult *)hitResult {
    float explosionYOffset = 0.1;
    
    SCNVector3 position = SCNVector3Make(hitResult.worldTransform.columns[3].x,
                                         hitResult.worldTransform.columns[3].y - explosionYOffset,
                                         hitResult.worldTransform.columns[3].z);
    
    for (SCNNode *cubeNode in cubes) {
        NSLog(@"cube node === %@", cubeNode);
        SCNVector3 distance = SCNVector3Make(cubeNode.worldPosition.x - position.x,
                                             cubeNode.worldPosition.y - position.y,
                                             cubeNode.worldPosition.z - position.z);
        
        float len = sqrtf(distance.x*distance.x+distance.y*distance.y+distance.z*distance.z);
        
        float maxDistance = 2;
        float scale = MAX(0, (maxDistance - len));
        scale = scale * scale * 0.5;
        distance.x = distance.x / len * scale;
        distance.y = distance.y / len * scale;
        distance.z = distance.z / len * scale;
        NSLog(@"scale == %f， len = %f, x = %f, y = %f, z = %f", scale, len, distance.x, distance.y, distance.z);
        
        [cubeNode.physicsBody applyForce:distance atPosition:SCNVector3Make(0.05, 0.05, 0.05) impulse:YES];
    }
}

#pragma mark - Insert Geometry

- (void)insertGeometry:(ARHitTestResult *)hitResult {
    float dimension = 0.1;
    SCNBox *cube = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:0];
    
    SCNNode *node = [SCNNode nodeWithGeometry:cube];
    node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
    node.physicsBody.mass = 2;
    node.physicsBody.categoryBitMask = CollisionCategoryCube;
    
    SCNMaterial *material = [SCNMaterial material];
    
    
    
    
    
    float insertYoffset = 0.5;
    node.position = SCNVector3Make(hitResult.worldTransform.columns[3].x,
                                   hitResult.worldTransform.columns[3].y+insertYoffset,
                                   hitResult.worldTransform.columns[3].z);
    [scnView.scene.rootNode addChildNode:node];
    
    [cubes addObject:node];
}

#pragma mark - Action

- (IBAction)action2Detection:(UISwitch *)sender {
    
    if (sender.isOn) {
        NSLog(@"is selected");
        arConfig.planeDetection = ARPlaneDetectionHorizontal;
    } else {
        NSLog(@"is unselected");
        arConfig.planeDetection = ARPlaneDetectionNone;
    }
    [arSession runWithConfiguration:arConfig];
    scnView.session = arSession;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
