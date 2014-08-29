//
//  Gameplay.m
//  1stShot
//
//  Created by Faisal on 4/25/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "Obstacle.h"

static const CGFloat scrollSpeedRate = 200.f;
static const CGFloat yAccelSpeed = 10.f;
static const CGFloat firstObstaclePosition = 280.f;
static const CGFloat distanceBetweenObstacles = 200.f;

// fixing the drawing order. forcing the ground to be drawn above the pipes.
typedef NS_ENUM(NSInteger, DrawingOrder) {
   DrawingOrderPipes,
   DrawingOrderGround,
   DrawingOrdeHero
};

@implementation Gameplay
{
    CCPhysicsNode *_physicsNode;
    CCSprite *_hero;
    CCNode *_ground1;
    CCNode *_ground2;
   CCNode *_ground3;
    NSArray *_grounds;
   CCNode *_cloud1;
   CCNode *_cloud2;
   CCNode *_cloud3;
   NSArray *_clouds;
    NSMutableArray *_obstacles;
    BOOL _gameOver;
    CGFloat _scrollSpeed;
    CGFloat _elapsedTime;
    NSInteger _points;
   NSInteger _localCounter;
    CCLabelTTF *_scoreLabel;
    CGFloat _swiped;
    CGFloat _newHeroPosition;
    CCNode *_gameOverBox;
   CCNode *_scoreLabelBox;
   CCNode *_banner;
    CCLabelTTF *_highScoreValue;
    CCLabelTTF *_scoreValue;
   AVAudioPlayer *clickSound, *gameOverSound;
   UIImage *_image;

}

// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
//    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
//    [_levelNode addChild:level];
    
    _physicsNode.collisionDelegate = self;
    
    _grounds = @[_ground1, _ground2, _ground3];
   _clouds = @[_cloud1, _cloud2, _cloud3];
   
    _obstacles = [NSMutableArray array];
    [self spawnNewObstacle];
    [self spawnNewObstacle];
    [self spawnNewObstacle];
   
    for (CCNode *ground in _grounds) {
        // set collision txpe
        ground.physicsBody.collisionType = @"level";
       ground.zOrder = DrawingOrderGround;
    }
   for (CCNode *cloud in _clouds) {
      // set collision txpe
      cloud.physicsBody.collisionType = @"level";
   }
    // set collision type
    _hero.physicsBody.collisionType = @"hero";
   _hero.zOrder = DrawingOrdeHero;

   
    _scrollSpeed = scrollSpeedRate;
    
    // GestureRecognizer Code
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(screenWasSwipedUp)];
    swipeUp.numberOfTouchesRequired = 1;
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(screenWasSwipedDown)];
    swipeDown.numberOfTouchesRequired = 1;
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeDown];

   UISwipeGestureRecognizer *swipRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(screenWasSwipedRight)];
   swipRight.numberOfTouchesRequired = 1;
   swipRight.direction = UISwipeGestureRecognizerDirectionRight;
   
   [[[CCDirector sharedDirector] view] addGestureRecognizer:swipRight];

   UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(screenWasSwipedRight)];
   swipeLeft.numberOfTouchesRequired = 1;
   swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
   
   [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeLeft];
   
   UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped)];
    tapped.numberOfTapsRequired = 1;
    tapped.numberOfTouchesRequired = 1;
    tapped.cancelsTouchesInView = NO;
    
    [[[CCDirector sharedDirector] view] addGestureRecognizer:tapped];
    
    _newHeroPosition = _hero.position.y;
    
    _highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"] ;
   
   // The AV Audio Player needs a URL to the file that will be played to be specified.
   // So, we're going to set the audio file's path and then convert it to a URL.
   // game over sound
   NSString *audioFilePath1 = [[NSBundle mainBundle] pathForResource:@"game_over" ofType:@"wav"];
   NSURL *pathAsURL1 = [[NSURL alloc] initFileURLWithPath:audioFilePath1];
   NSError *error1;
   gameOverSound = [[AVAudioPlayer alloc] initWithContentsOfURL:pathAsURL1 error:&error1];
   gameOverSound.volume = 0.5;

   // Check out what's wrong in case that the player doesn't init.
   if (error1) {
      NSLog(@"%@", [error1 localizedDescription]);
   }
   else{
      // In this example we'll pre-load the audio into the buffer. You may avoid it if you want
      // as it's not always possible to pre-load the audio.
      [gameOverSound prepareToPlay];
   }
   
   [gameOverSound setDelegate:self];
   
   // click sound
   NSString *audioFilePath2 = [[NSBundle mainBundle] pathForResource:@"click" ofType:@"wav"];
   NSURL *pathAsURL2 = [[NSURL alloc] initFileURLWithPath:audioFilePath2];
   NSError *error2;
   clickSound = [[AVAudioPlayer alloc] initWithContentsOfURL:pathAsURL2 error:&error2];
   clickSound.volume = 0.5;
   
   // Check out what's wrong in case that the player doesn't init.
   if (error2) {
      NSLog(@"%@", [error2 localizedDescription]);
   }
   else{
      // In this example we'll pre-load the audio into the buffer. You may avoid it if you want
      // as it's not always possible to pre-load the audio.
      [clickSound prepareToPlay];
   }
   
   [clickSound setDelegate:self];

   _gameOver = TRUE;
   _banner.visible = TRUE;

}

-(void)screenWasSwipedUp
{
   if (_gameOver && _scrollSpeed != 0) {
      _gameOver = FALSE;
      [_banner runAction:[CCActionFadeOut actionWithDuration:1.0]];
   }
   else {
    if(_hero.position.y < 340)
    {
    if(_hero.position.y == 90 ||
       _hero.position.y == 170 ||
       _hero.position.y == 250 ||
       _hero.position.y == 330)
//       _hero.position.y == 410)
    {
    _swiped = 1.0f;
    _newHeroPosition = _hero.position.y;
    }
    }
    }
}

-(void)screenWasSwipedDown
{
   if (_gameOver && _scrollSpeed != 0) {
      _gameOver = FALSE;
      [_banner runAction:[CCActionFadeOut actionWithDuration:1.0]];
   }
   else {
    if(_hero.position.y == 90 ||
       _hero.position.y == 170 ||
       _hero.position.y == 250 ||
       _hero.position.y == 330)
//       _hero.position.y == 410)
    {
        _swiped = -1.0f;
        _newHeroPosition = _hero.position.y;
    }
   }
}

-(void)screenTapped
{
    if (_gameOver && _scrollSpeed != 0) {
          _gameOver = FALSE;
      [_banner runAction:[CCActionFadeOut actionWithDuration:1.0]];
    }
}

-(void)screenWasSwipedRight
{
   if (!_gameOver) {
//      if(_missileCount > 0)
//      {
//         [self launchMissile];
//         _missileCount--;
//         _missileLabel.string = [NSString stringWithFormat:@"%ld", (long)_missileCount];
//      }
//      else{
//         [errorSound play];
//      }
   }
}


- (void)update:(CCTime)delta
{
   if(!_gameOver){
      if (_hero.position.y - _newHeroPosition >= 80.0)
      {
         _hero.position = ccp(_hero.position.x + delta * _scrollSpeed, _hero.position.y);
      }
      else if(_hero.position.y - _newHeroPosition <= -80.0)
      {
         _hero.position = ccp(_hero.position.x + delta * _scrollSpeed, _hero.position.y);
      }
      else
      {
         _hero.position = ccp(_hero.position.x + delta * _scrollSpeed, _hero.position.y + _swiped * yAccelSpeed);
      }
      //        CCLOG(@"%f",_hero.position.y);
      _physicsNode.position = ccp(_physicsNode.position.x - (_scrollSpeed *delta), _physicsNode.position.y);
      // loop the ground
      for (CCNode *ground in _grounds) {
         // get the world position of the ground
         CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
         // get the screen position of the ground
         CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
         // if the left corner is one complete width off the screen, move it to the right
         if (groundScreenPosition.x <= (-1 * ground.contentSize.width)) {
            ground.position = ccp(ground.position.x + 2 * ground.contentSize.width, ground.position.y);
         }
         
      }
      // loop the cloud
      for (CCNode *cloud in _clouds) {
         // get the world position of the cloud
         CGPoint cloudWorldPosition = [_physicsNode convertToWorldSpace:cloud.position];
         // get the screen position of the cloud
         CGPoint cloudScreenPosition = [self convertToNodeSpace:cloudWorldPosition];
         // if the left corner is one complete width off the screen, move it to the right
         if (cloudScreenPosition.x <= (-1 * cloud.contentSize.width)) {
            cloud.position = ccp(cloud.position.x + 2 * cloud.contentSize.width, cloud.position.y);
         }
         
      }

      // Spawning new obstacles when old ones leave the screen
      
      NSMutableArray *offScreenObstacles = nil;
      for (CCNode *obstacle in _obstacles) {
         CGPoint obstacleWorldPosition = [_physicsNode convertToWorldSpace:obstacle.position];
         CGPoint obstacleScreenPosition = [self convertToNodeSpace:obstacleWorldPosition];
         if (obstacleScreenPosition.x < -obstacle.contentSize.width) {
            if (!offScreenObstacles) {
               offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
         }
      }
      for (CCNode *obstacleToRemove in offScreenObstacles) {
         [obstacleToRemove removeFromParent];
         [_obstacles removeObject:obstacleToRemove];
         // for each removed obstacle, add a new one
         [self spawnNewObstacle];
      }
   }
   else if (_gameOver && _scrollSpeed == 0)
   {
         _elapsedTime += delta;
         if(_localCounter <= _points && _elapsedTime > 2)
         {
//            [playSound stop];
            _physicsNode.visible = FALSE;
            _scoreLabel.visible = FALSE;
            _scoreLabelBox.visible = FALSE;
            _gameOverBox.visible = TRUE;
            [_gameOverBox runAction:[CCActionFadeIn  actionWithDuration:0.5]];

            _localCounter++;
            _scoreValue.string = [NSString stringWithFormat:@"%ld", (long)_localCounter-1];
            
         }
   }
}

- (void)heroRemoved:(CCNode *)hero {
    // remove the hero
    [hero removeFromParent];
}

- (void)spawnNewObstacle {
    CCNode *previousObstacle = [_obstacles lastObject];
    CGFloat previousObstacleXPosition = previousObstacle.position.x;
    if (!previousObstacle) {
        // this is the first obstacle
        previousObstacleXPosition = firstObstaclePosition;
    }
    Obstacle *obstacle = (Obstacle *)[CCBReader load:@"Obstacle"];
    obstacle.position = ccp(previousObstacleXPosition + distanceBetweenObstacles, 0);
    [obstacle setupRandomPosition];
    [_physicsNode addChild:obstacle];
    [_obstacles addObject:obstacle];
   // fixing drawing order. drawing grounds in front of pipes.
   obstacle.zOrder = DrawingOrderPipes;
}


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero level:(CCNode *)level {
   [gameOverSound play];
   _hero.effect = [CCEffectPixellate effectWithBlockSize: 4];
//   _hero.effect = [CCEffectBrightness effectWithBrightness:1];
//    [self heroRemoved:hero];
    [self gameOver];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair hero:(CCNode *)hero goal:(CCNode *)goal {
    [goal removeFromParent];
    _points++;
    _scoreLabel.string = [NSString stringWithFormat:@"%ld", (long)_points];
    return TRUE;
}

- (void)restart
{
   [clickSound play];
   CCScene *scene = [CCBReader loadAsScene:@"Gameplay"];
   [[CCDirector sharedDirector] replaceScene:scene withTransition:[CCTransition transitionFadeWithDuration:1.0]];
}

-(void)onExit
{
    [self stopAllActions];
    [self unscheduleAllSelectors];
    [self removeAllChildrenWithCleanup:YES];
   clickSound.delegate = nil;
   clickSound = nil;
   gameOverSound.delegate = nil;
   gameOverSound = nil;
    [super onExit];
}



- (void)gameOver {
    if (!_gameOver) {
        _scrollSpeed = 0.f;
        _gameOver = TRUE;
//        _highScoreValue.visible = TRUE;
//        _scoreValue.visible = TRUE;
        [_hero stopAllActions];
       
//        CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.5f position:ccp(0, 163)];
//        CCActionInterval *reverseMovement = [moveBy reverse];
//        CCActionSequence *shakeSequence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
//        CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSequence];
//       [_gameOverBox runAction:bounce];
       
        // save high score
        //To save the score (in this case, 10000 ) to standard defaults:
        
        if(_points > _highScore)
        {
        
            [[NSUserDefaults standardUserDefaults] setInteger: _points forKey: @"highScore"];
        
            // To read it back:
        
        }
        _highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"] ;
        _highScoreValue.string = [NSString stringWithFormat:@"%ld", (long)_highScore];
       
       // Take Screen Shot
       UIGraphicsBeginImageContextWithOptions([CCDirector sharedDirector].view.bounds.size, NO, [UIScreen mainScreen].scale);
       
       [[CCDirector sharedDirector].view drawViewHierarchyInRect:[CCDirector sharedDirector].view.bounds afterScreenUpdates:NO];
       
       _image = UIGraphicsGetImageFromCurrentImageContext();
       UIGraphicsEndImageContext();
       
//        [self runAction:bounce];
    }
}

-(void)resetHighScore{
    [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"highScore"];
    _highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"] ;
    _highScoreValue.string = [NSString stringWithFormat:@"%ld", (long)_highScore];
}

-(void)shareImage{
   [clickSound play];
   NSString *message = [NSString stringWithFormat:@"Hey!!! I scored %d", _points];
   message = [message stringByAppendingString:@" points in Fast Fingers."];
   
   UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:message,_image, nil] applicationActivities:nil];
   activityVC.excludedActivityTypes = @[ UIActivityTypeAssignToContact];
   [[CCDirector sharedDirector] presentViewController:activityVC animated:YES completion:nil];

}

@end
