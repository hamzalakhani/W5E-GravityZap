//
//  myScene.m
//  TestGame
//
//  Created by Hamza Lakhani on 2016-11-26.
//  Copyright © 2016 Hamza Lakhani. All rights reserved.
//

#import "myScene.h"
#import "RetryScene.h"
static const uint32_t projectileCategory     =  0x1 << 0;
static const uint32_t targetCategory        =  0x1 << 1;
static const uint32_t powerUpCategory     =  0x1 << 1;

@interface myScene ()<SKPhysicsContactDelegate>
@property (nonatomic) SKSpriteNode * bulletNode;
@property (nonatomic) SKSpriteNode * superBullet;

@property (nonatomic) SKSpriteNode * leftAmp1;
@property (nonatomic) SKSpriteNode * leftAmp2;
@property (nonatomic) SKSpriteNode * rightAmp1;
@property (nonatomic) SKSpriteNode * rightAmp2;
@property (nonatomic) SKSpriteNode * target;
@property (nonatomic) NSTimeInterval lastForceSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastTargetSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) SKSpriteNode * powerUp;
@property (nonatomic) SKSpriteNode * scoreBoard;
@property (nonatomic) int scoreValue;
@property (nonatomic) SKSpriteNode * pauseButton;
@property (nonatomic) int count;

@end

@implementation myScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        self.scoreValue = 0;

        // 1 Create a physics body that borders the screen
        SKPhysicsBody* borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        // 2 Set physicsBody of scene to borderBody
        self.physicsBody = borderBody;
        borderBody.node.name = @"wall";
        // 3 Set the friction of that physicsBody to 0
        self.physicsBody.friction = 0.0f;
        
        // 2
        NSLog(@"Size: %@", NSStringFromCGSize(size));
        
        // 3
        SKSpriteNode *bgImage = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        [self addChild:bgImage];
        bgImage.position = CGPointMake(self.size.width/2, self.size.height/2);
        
        
        //adding the powerup
        self.powerUp = [SKSpriteNode spriteNodeWithImageNamed:@"powerup"];
        self.powerUp.name = @"powerup";
        self.powerUp.position = CGPointMake(self.frame.size.width/3, self.frame.size.height/3);
        [self addChild:self.powerUp];
        self.powerUp.physicsBody.dynamic = YES; // 2
        
        self.powerUp.physicsBody.categoryBitMask = powerUpCategory; // 3
        self.powerUp.physicsBody.contactTestBitMask = projectileCategory; // 4
        self.powerUp.physicsBody.collisionBitMask = 0;
        // 2
        self.powerUp.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.powerUp.frame.size.width/2];
        // 3
        self.powerUp.physicsBody.friction = 0.0f;
        // 4
        self.powerUp.physicsBody.restitution = 1.0f;
        // 5
        self.powerUp.physicsBody.linearDamping = 0.0f;
        // 6
        self.powerUp.physicsBody.allowsRotation = YES;
        [self.powerUp.physicsBody applyImpulse:CGVectorMake(10.0f, -10.0f)];
        
        // 4
        self.bulletNode = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
        self.bulletNode.position = CGPointMake(200, 30);
        self.bulletNode.name = @"bullet";
        [self addChild:self.bulletNode];
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
        
//        self.leftAmp1 = [SKSpriteNode spriteNodeWithImageNamed:@"electricleft1"];
//        self.leftAmp1.position = CGPointMake(350, 400);
//        [self addChild:self.leftAmp1];
//        
//        self.leftAmp2 = [SKSpriteNode spriteNodeWithImageNamed:@"electricleft2"];
//        self.leftAmp2.position = CGPointMake(350, 300);
//        [self addChild:self.leftAmp2];
//        
//        self.rightAmp1 = [SKSpriteNode spriteNodeWithImageNamed:@"electricright"];
//        self.rightAmp1.position = CGPointMake(50, 465);
//        [self addChild:self.rightAmp1];
//        
//        self.rightAmp2 = [SKSpriteNode spriteNodeWithImageNamed:@"electricright2"];
//        self.rightAmp2.position = CGPointMake(50, 365);
//        [self addChild:self.rightAmp2];
//        
        //        self.target = [SKSpriteNode spriteNodeWithImageNamed:@"Target"];
        //        self.target.position = CGPointMake(200, 700);
        //        [self addChild:self.target];
        
        //Add score
        self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score0"];
        self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
        [self addChild:self.scoreBoard];
        
    }
    
    
    return self;
}
-(void)addMonster {
    
    // Create sprite
    SKSpriteNode * target = [SKSpriteNode spriteNodeWithImageNamed:@"Target"];
    target.name = @"target";
    target.size = CGSizeMake(80, 80);
    target.texture = [SKTexture textureWithImageNamed:@"Target"];
    target.physicsBody = [SKPhysicsBody bodyWithTexture:target.texture size:target.size]; // 1
    target.physicsBody.dynamic = YES; // 2
    target.physicsBody.categoryBitMask = targetCategory; // 3
    target.physicsBody.contactTestBitMask = projectileCategory; // 4
    target.physicsBody.collisionBitMask = 0; // 5
    // Determine where to spawn the monster along the Y axis
    int maxY = self.frame.size.height - 20;
    
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
    SKAction * actionMove = [SKAction moveTo:CGPointMake(-target.size.width/2, maxY) duration:minDuration];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [target runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
}

-(void)addBlueChip {
    
    // Create sprite
    SKSpriteNode * target = [SKSpriteNode spriteNodeWithImageNamed:@"blueChip"];
    target.name = @"blueChip";
    target.size = CGSizeMake(80, 80);
    target.texture = [SKTexture textureWithImageNamed:@"blueChip"];
    target.physicsBody = [SKPhysicsBody bodyWithTexture:target.texture size:target.size]; // 1
    target.physicsBody.dynamic = YES; // 2
    target.physicsBody.categoryBitMask = targetCategory; // 3
    target.physicsBody.contactTestBitMask = projectileCategory; // 4
    target.physicsBody.collisionBitMask = 0; // 5
    // Determine where to spawn the monster along the Y axis
    int maxY = self.frame.size.height - 20;
    
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
    SKAction * actionMove = [SKAction moveTo:CGPointMake(-target.size.width/2, maxY) duration:minDuration];
    SKAction * actionMoveDone = [SKAction removeFromParent];
    [target runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];

}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    
    self.lastForceSpawnTimeInterval += timeSinceLast;
    if (self.lastForceSpawnTimeInterval > 2) {
        self.lastForceSpawnTimeInterval = 0;
        //apply force to bullet
        int randomXDirection = arc4random_uniform(400) + 2000;
        int randomNegative = arc4random_uniform(2) + 1;
        if (randomNegative == 1) {
            randomXDirection = randomXDirection * - 1;
        }
        SKAction * actionMove = [SKAction runBlock:^{
            [self.bulletNode.physicsBody applyForce:CGVectorMake(randomXDirection, 0)];
        }];
        [self.bulletNode runAction:[SKAction sequence:@[actionMove]] withKey:@"bullet action"];
        
        //add target
        
    }
    
}

-(void)updateTargetWithTime:(CFTimeInterval)timeSinceLast {
    
    self.lastTargetSpawnTimeInterval += timeSinceLast;
    
    srand48(time(0));
    double randomTime = drand48() + 1;
    
    if (self.lastTargetSpawnTimeInterval > randomTime) {
        self.lastTargetSpawnTimeInterval = 0;
       
        int randomChip = arc4random_uniform(5) + 2;
        //add target
        if (self.count > randomChip) {
            [self addBlueChip];
            self.count = 0;
        } else {
            [self addMonster];
            self.count += 1;
        }
        
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
    [self updateTargetWithTime:timeSinceLast];
    
}
//
//static inline CGPoint rwAdd(CGPoint a, CGPoint b) {
//    return CGPointMake(a.x + b.x, a.y + b.y);
//}
//
//static inline CGPoint rwSub(CGPoint a, CGPoint b) {
//    return CGPointMake(a.x - b.x, a.y - b.y);
//}
//
//static inline CGPoint rwMult(CGPoint a, float b) {
//    return CGPointMake(a.x * b, a.y * b);
//}
//
//static inline float rwLength(CGPoint a) {
//    return sqrtf(a.x * a.x + a.y * a.y);
//}
//
//// Makes a vector have a length of 1
//static inline CGPoint rwNormalize(CGPoint a) {
//    float length = rwLength(a);
//    return CGPointMake(a.x / length, a.y / length);
//}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // 1 - Choose one of the touches to work with
    UITouch * touch = [touches anyObject];
    //CGPoint location = [touch locationInNode:self];
    
    // 2 - Set up initial location of projectile
    //    SKSpriteNode * projectile = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
    self.bulletNode.position = self.bulletNode.position;
    self.bulletNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.bulletNode.size.width/2];
    self.bulletNode.physicsBody.dynamic = YES;
    self.bulletNode.physicsBody.categoryBitMask = projectileCategory;
    self.bulletNode.physicsBody.contactTestBitMask = targetCategory;
    self.bulletNode.physicsBody.collisionBitMask = 0;
    self.bulletNode.physicsBody.usesPreciseCollisionDetection = YES;
//    // 3- Determine offset of location to projectile
//    CGPoint offset = rwSub(location, self.bulletNode.position);
//    
//    // 4 - Bail out if you are shooting down or backwards
//    //    if (offset.x <= 0) return;
//    
//    // 5 - OK to add now - we've double checked position
//    //[self addChild:self.bulletNode];
//    
//    // 6 - Get the direction of where to shoot
//    CGPoint direction = rwNormalize(offset);
//    
//    // 7 - Make it shoot far enough to be guaranteed off screen
//    CGPoint shootAmount = rwMult(direction, 1000);
//    
//    // 8 - Add the shoot amount to the current position
//    CGPoint realDest = rwAdd(shootAmount, self.bulletNode.position);
    
    // 9 - Create the actions
    //float velocity = 480.0/1.0;
    //float realMoveDuration = self.size.width / velocity;
    SKAction * actionMove = [SKAction runBlock:^{
        [self.bulletNode.physicsBody applyForce:CGVectorMake(0, 2500)];
    }];
    [self.bulletNode runAction:[SKAction sequence:@[actionMove]] withKey:@"bullet action"];
    
}

- (void)projectile:(SKSpriteNode *)projectile didCollideWithMonster:(SKSpriteNode *)monster {
    NSLog(@"Hit");
    
    [self.bulletNode removeFromParent];
    [monster removeFromParent];
    self.bulletNode = [SKSpriteNode spriteNodeWithImageNamed:@"bullet"];
    self.bulletNode.position = CGPointMake(200, 30);
    [self addChild:self.bulletNode];
    
    
}
//contact with powerup
- (void)thePowerUp:(SKSpriteNode *)thePowerUp didcolideWithPowerUp:(SKSpriteNode *)powerUp {
    NSLog(@"power up!!");
    [self.powerUp removeFromParent];
    [powerUp removeFromParent];
    self.bulletNode = [SKSpriteNode spriteNodeWithImageNamed:@"doublebullet"];
    self.bulletNode.position = CGPointMake(200, 30);
    [self addChild:self.bulletNode];
    
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
        
        if([secondBody.node.name  isEqual: @"powerup"]){
            [self shrinkAndMoveToPosition:self.view.center];
            
            [self thePowerUp:(SKSpriteNode *)firstBody.node didcolideWithPowerUp:(SKSpriteNode *)secondBody.node];
            
        }else if ([secondBody.node.name isEqual:@"wall"]){
            RetryScene* retryScene = [[RetryScene alloc] initWithSize:self.frame.size playerWon:NO];
            [self.view presentScene:retryScene];

        }else {
            
            self.scoreValue += 1;
            
            switch (self.scoreValue) {
                case 1:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score1"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                case 2:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score2"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 3:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score3"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 4:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score4"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 5:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score5"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 6:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score6"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 7:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score7"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 8:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score8"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 9:
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score9"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                case 10:
                    
                    //NEXT LEVEL
//                    [self.scoreBoard removeFromParent];
//                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score1"];
//                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
//                    [self addChild:self.scoreBoard];
                    
                    break;
                    
                default:
                    
                    self.scoreValue = 0;
                    
                    [self.scoreBoard removeFromParent];
                    self.scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"score1"];
                    self.scoreBoard.position = CGPointMake(self.frame.size.width - 20, self.frame.size.height - 25);
                    [self addChild:self.scoreBoard];
                    
                    break;
            }
            
            
        }
        
    }
    
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches){
        self.pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"pause"];
        self.pauseButton.size = CGSizeMake(50, 50);
        self.pauseButton.position = CGPointMake( 20, self.frame.size.height - 25);
        [self addChild:self.pauseButton];
        CGPoint location = [touch locationInNode:self];
        if([self.pauseButton containsPoint:location]){
            self.scene.view.paused = YES;

        }
    }


}

- (void)shrinkAndMoveToPosition:(CGPoint)position {
    
    SKSpriteNode* superPower = [SKSpriteNode spriteNodeWithImageNamed:@"superPower"];
    superPower.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [self addChild:superPower];

    
    SKAction *move = [SKAction moveTo:position duration:.5];
    SKAction *scale = [SKAction scaleTo:.3 duration:.5];
    SKAction *moveAndScale = [SKAction group:@[move, scale]];
    [self runAction:moveAndScale completion:^{
        

        SKAction *animate = [SKAction scaleBy:0.0 duration:.5];
        
        [superPower runAction:[SKAction repeatActionForever:animate]];
        
    }];
}
@end
