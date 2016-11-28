//
//  myScene.m
//  TestGame
//
//  Created by Hamza Lakhani on 2016-11-26.
//  Copyright © 2016 Hamza Lakhani. All rights reserved.
//

#import "myScene.h"
static const uint32_t projectileCategory     =  0x1 << 0;
static const uint32_t targetCategory        =  0x1 << 1;
@interface myScene ()<SKPhysicsContactDelegate>
@property (nonatomic) SKSpriteNode * player;
@property (nonatomic) SKSpriteNode * leftAmp1;
@property (nonatomic) SKSpriteNode * leftAmp2;
@property (nonatomic) SKSpriteNode * rightAmp1;
@property (nonatomic) SKSpriteNode * rightAmp2;
@property (nonatomic) SKSpriteNode * target;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;


@end

@implementation myScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        // 2
        NSLog(@"Size: %@", NSStringFromCGSize(size));
        
        // 3
        SKSpriteNode *bgImage = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        [self addChild:bgImage];
        bgImage.position = CGPointMake(self.size.width/2, self.size.height/2);

        // 4
        self.player = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
        self.player.position = CGPointMake(200, 30);
        [self addChild:self.player];
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
        self.leftAmp1 = [SKSpriteNode spriteNodeWithImageNamed:@"electricleft1"];
        self.leftAmp1.position = CGPointMake(350, 400);
        [self addChild:self.leftAmp1];
        
        self.leftAmp2 = [SKSpriteNode spriteNodeWithImageNamed:@"electricleft2"];
        self.leftAmp2.position = CGPointMake(350, 300);
        [self addChild:self.leftAmp2];

        self.rightAmp1 = [SKSpriteNode spriteNodeWithImageNamed:@"electricright"];
        self.rightAmp1.position = CGPointMake(50, 465);
        [self addChild:self.rightAmp1];
        
        self.rightAmp2 = [SKSpriteNode spriteNodeWithImageNamed:@"electricright2"];
        self.rightAmp2.position = CGPointMake(50, 365);
        [self addChild:self.rightAmp2];

//        self.target = [SKSpriteNode spriteNodeWithImageNamed:@"Target"];
//        self.target.position = CGPointMake(200, 700);
//        [self addChild:self.target];

        
    }
    
    
    return self;
}
-(void)addMonster {
    
    // Create sprite
    SKSpriteNode * target = [SKSpriteNode spriteNodeWithImageNamed:@"Target"];
    target.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:target.size]; // 1
    target.physicsBody.dynamic = YES; // 2
    target.physicsBody.categoryBitMask = targetCategory; // 3
    target.physicsBody.contactTestBitMask = projectileCategory; // 4
    target.physicsBody.collisionBitMask = 0; // 5
    // Determine where to spawn the monster along the Y axis
    int minY = target.size.height ;
    int maxY = self.frame.size.height - target.size.height;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    // Create the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    target.position = CGPointMake(self.frame.size.width + target.size.width, maxY);
    [self addChild:target];
    
    // Determine speed of the monster
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    // Create the actions
    SKAction * actionMove = [SKAction moveTo:CGPointMake(-target.size.width/2, actualY) duration:actualDuration];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [target runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > 5) {
        self.lastSpawnTimeInterval = 0;
        [self addMonster];
    }
}
- (void)update:(NSTimeInterval)currentTime {
    // Handle time delta.
    // If we drop below 60fps, we still want everything to move the same distance.
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 1) { // more than a second since last update
        timeSinceLast = 1.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
    
}

static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint rwSub(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint rwMult(CGPoint a, float b) {
    return CGPointMake(a.x * b, a.y * b);
}

static inline float rwLength(CGPoint a) {
    return sqrtf(a.x * a.x + a.y * a.y);
}

// Makes a vector have a length of 1
static inline CGPoint rwNormalize(CGPoint a) {
    float length = rwLength(a);
    return CGPointMake(a.x / length, a.y / length);
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // 1 - Choose one of the touches to work with
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    // 2 - Set up initial location of projectile
    SKSpriteNode * projectile = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
    projectile.position = self.player.position;
    projectile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:projectile.size.width/2];
    projectile.physicsBody.dynamic = YES;
    projectile.physicsBody.categoryBitMask = projectileCategory;
    projectile.physicsBody.contactTestBitMask = targetCategory;
    projectile.physicsBody.collisionBitMask = 0;
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    // 3- Determine offset of location to projectile
    CGPoint offset = rwSub(location, projectile.position);
    
    // 4 - Bail out if you are shooting down or backwards
    if (offset.x <= 0) return;
    
    // 5 - OK to add now - we've double checked position
    [self addChild:projectile];
    
    // 6 - Get the direction of where to shoot
    CGPoint direction = rwNormalize(offset);
    
    // 7 - Make it shoot far enough to be guaranteed off screen
    CGPoint shootAmount = rwMult(direction, 1000);
    
    // 8 - Add the shoot amount to the current position
    CGPoint realDest = rwAdd(shootAmount, projectile.position);
    
    // 9 - Create the actions
    float velocity = 480.0/1.0;
    float realMoveDuration = self.size.width / velocity;
    SKAction * actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithMonster:(SKSpriteNode *)monster {
    NSLog(@"Hit");
    [projectile removeFromParent];
    [monster removeFromParent];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    // 1
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // 2
    if ((firstBody.categoryBitMask & projectileCategory) != 0 &&
        (secondBody.categoryBitMask & targetCategory) != 0)
    {
        [self projectile:(SKSpriteNode *) firstBody.node didCollideWithMonster:(SKSpriteNode *) secondBody.node];
    }
}
@end