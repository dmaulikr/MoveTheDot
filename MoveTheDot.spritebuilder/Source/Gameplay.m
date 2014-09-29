//
//  Gameplay.m
//  1stShot
//
//  Created by Faisal on 4/25/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "Obstacle.h"

static const CGFloat scrollSpeedRate = 250.f;
static const CGFloat yAccelSpeed = 10.f;
static const CGFloat firstObstaclePosition = 280.f;
static const CGFloat distanceBetweenObstacles = 200.f;

#define kRemoveAdsProductIdentifier @"com.bakwasgames.movethedot.removeads"
#define SYSTEM_VERSION_LESS_THAN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


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
   GADBannerView *_bannerView;
   GADInterstitial *interstitial;
   CCButton *_removeAdsButton;
   UIActivityIndicatorView *spinner;
   NSString *osVersion;
}

// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
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

   // remove ads
   _areAdsRemoved = [[NSUserDefaults standardUserDefaults] boolForKey:@"areAdsRemoved"];
   
   if(!_areAdsRemoved)
   {
   [self cycleInterstitial]; // Prepare our interstitial for after the game so that we can be certain its ready to present
      
   // Initialize the banner at the bottom of the screen.
   CGPoint origin = CGPointMake(0.0,
                                [CCDirector sharedDirector].view.frame.size.height -
                                CGSizeFromGADAdSize(kGADAdSizeSmartBannerPortrait).height);
   _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait origin:origin];
   
   // Specify the ad unit ID.
   _bannerView.adUnitID = @"ca-app-pub-3129568560891761/2856875137";
   
   // Let the runtime know which UIViewController to restore after taking
   // the user wherever the ad goes and add it to the view hierarchy.
   _bannerView.rootViewController = [CCDirector sharedDirector];
   [[[CCDirector sharedDirector]view]addSubview:_bannerView];
   // Initiate a generic request to load it with an ad.
   [_bannerView loadRequest:[GADRequest request]];
   _bannerView.delegate = self;
   _bannerView.hidden = NO;
   }

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
//   [self authenticateLocalPlayer];

    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
   [spinner setCenter:CGPointMake([CCDirector sharedDirector].view.frame.size.width/2.0, [CCDirector sharedDirector].view.frame.size.height/2.0)]; // I do this because I'm in landscape mode
   [[[CCDirector sharedDirector]view]addSubview:spinner];
   
   _gameOver = TRUE;
   _banner.visible = TRUE;

   if(!_areAdsRemoved){
      _removeAdsButton.visible = TRUE;
      _removeAdsButton.enabled = TRUE;
   }
   else{
      _removeAdsButton.visible = FALSE;
      _removeAdsButton.enabled = FALSE;
      _bannerView.hidden = TRUE;
   }
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
   [spinner  stopAnimating];
   if(!_areAdsRemoved)
   {
      [self presentInterlude];
   }
   else
   {
      [self replaceSceneWithTransition];
   }
}

-(void)pause
{
   if([CCDirector sharedDirector].isPaused)
   {
      [[CCDirector sharedDirector] resume];
   }
   else{
   [[CCDirector sharedDirector] pause];
   }
}

-(void)onExit
{
    [self stopAllActions];
    [self unscheduleAllSelectors];
    [self removeAllChildrenWithCleanup:YES];
   [_bannerView removeFromSuperview];
   interstitial.delegate = nil;
   interstitial = nil;
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
           if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
           {
           [self reportScore];
           }
        
        }
        _highScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScore"] ;
        _highScoreValue.string = [NSString stringWithFormat:@"%ld", (long)_highScore];
       
       // Take Screen Shot
       UIGraphicsBeginImageContextWithOptions([CCDirector sharedDirector].view.bounds.size, NO, [UIScreen mainScreen].scale);
       
//       [[CCDirector sharedDirector].view drawViewHierarchyInRect:[CCDirector sharedDirector].view.bounds afterScreenUpdates:NO];
       /* iOS 7 */
       if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
          [[CCDirector sharedDirector].view drawViewHierarchyInRect:[CCDirector sharedDirector].view.bounds afterScreenUpdates:NO];
       else /* iOS 6 */
          [[CCDirector sharedDirector].view.layer renderInContext:UIGraphicsGetCurrentContext()];

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
   [spinner  stopAnimating];
   NSString *message = [NSString stringWithFormat:@"Hey!!! I scored %ld", (long)_points];
   message = [message stringByAppendingString:@" points in Move The Dot."];
   message = [message stringByAppendingString:@" Check it out https://itunes.apple.com/app/id914300555"];
   
   UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:message,_image, nil] applicationActivities:nil];
   activityVC.excludedActivityTypes = @[ UIActivityTypeAssignToContact];
   [[CCDirector sharedDirector] presentViewController:activityVC animated:YES completion:nil];

}

-(void)replaceSceneWithTransition
{
   CCScene *scene = [CCBReader loadAsScene:@"Gameplay"];
   [[CCDirector sharedDirector] replaceScene:scene withTransition:[CCTransition transitionFadeWithDuration:1.0]];
}

-(void)replaceScene
{
   CCScene *scene = [CCBReader loadAsScene:@"Gameplay"];
   [[CCDirector sharedDirector] replaceScene:scene];
}

#pragma mark GameCenter
-(void)reportScore{
   if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
   {
   GKScore *score = [[GKScore alloc] initWithLeaderboardIdentifier:@"2"];
   score.value = _points;
   
   [GKScore reportScores:@[score] withCompletionHandler:^(NSError *error) {
      if (error != nil) {
         NSLog(@"%@", [error localizedDescription]);
      }
   }];
   }
}

-(void)showLeaderboardAndAchievements:(BOOL)shouldShowLeaderboard{
   GKGameCenterViewController *gcViewController = [[GKGameCenterViewController alloc] init];
   
   gcViewController.gameCenterDelegate = self;
   
   if (shouldShowLeaderboard) {
      gcViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
      gcViewController.leaderboardIdentifier = _leaderboardIdentifier;
   }
   else{
      gcViewController.viewState = GKGameCenterViewControllerStateAchievements;
   }
   
   [[CCDirector sharedDirector] presentViewController:gcViewController animated:YES completion:nil];
}

-(void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
   [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)showLeaderboard{
   if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
   {
   [clickSound play];
   [spinner  stopAnimating];
   [self showLeaderboardAndAchievements:YES];
   }
}

#pragma mark GADBannerViewDelegate implementation

// We've received an ad successfully.
- (void)adViewDidReceiveAd:(GADBannerView *)adView {
   NSLog(@"Received ad successfully");
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
   NSLog(@"Failed to receive ad with error: %@", [error localizedFailureReason]);
}

#pragma mark -
#pragma mark Interstitial Management

- (void)cycleInterstitial
{
   if(!_areAdsRemoved)
   {
   // Clean up the old interstitial...
   interstitial.delegate = nil;
   interstitial = nil;
   // GAD
   interstitial = [[GADInterstitial alloc] init];
   interstitial.adUnitID = @"ca-app-pub-3129568560891761/4333608339";
   [interstitial loadRequest:[GADRequest request]];
   interstitial.delegate = self;
   }
}

- (void)presentInterlude
{
   // If the interstitial managed to load, then we'll present it now.
   if (interstitial.isReady) {
      [interstitial presentFromRootViewController:[CCDirector sharedDirector]];
   }
   _bannerView.hidden = YES;
   [self replaceSceneWithTransition];
}

#pragma mark ADInterstitialViewDelegate methods

// This method will be invoked when an error has occurred attempting to get advertisement content.
// The ADError enum lists the possible error codes.
-(void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error
{
   [self cycleInterstitial];
}

-(void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
   [self cycleInterstitial];
}

#pragma mark remove ads

- (void)tapsRemoveAds{
   NSLog(@"User requests to remove ads");
   [spinner startAnimating];
   _scrollSpeed = 0.f;
   if([SKPaymentQueue canMakePayments]){
      NSLog(@"User can make payments");
      
      SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
      productsRequest.delegate = self;
      [productsRequest start];
      
   }
   else{
      NSLog(@"User cannot make payments due to parental controls");
      //this is called the user cannot make payments, most likely due to parental controls
   }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
   SKProduct *validProduct = nil;
   int count = [response.products count];
   if(count > 0){
      validProduct = [response.products objectAtIndex:0];
      NSLog(@"Products Available!");
      [self purchase:validProduct];
   }
   else if(!validProduct){
      NSLog(@"No products available");
      //this is called if your product id is not valid, this shouldn't be called unless that happens.
   }
}

- (void)purchase:(SKProduct *)product{
   SKPayment *payment = [SKPayment paymentWithProduct:product];
   [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
   [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) restore{
   //this is called when the user restores purchases, you should hook this up to a button
   [spinner startAnimating];
   [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
   [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
   NSLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
   for (SKPaymentTransaction *transaction in queue.transactions)
   {
      if(SKPaymentTransactionStateRestored){
         NSLog(@"Transaction state -> Restored");
         //called when the user successfully restores a purchase
         [self doRemoveAds];
         [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
         break;
      }
      
   }
   
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
   for(SKPaymentTransaction *transaction in transactions){
      switch (transaction.transactionState){
         case SKPaymentTransactionStatePurchasing:
         {
            NSLog(@"Transaction state -> Purchasing");
            //called when the user is in the process of purchasing, do not add any of your own code here.
            break;
         }
         case SKPaymentTransactionStatePurchased:
         {
            //this is called when the user has successfully purchased the package (Cha-Ching!)
            [self doRemoveAds]; //you can add your code for what you want to happen when the user buys the purchase here, for this tutorial we use removing ads
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            NSLog(@"Transaction state -> Purchased");
            [spinner stopAnimating];
            break;
         }
         case SKPaymentTransactionStateRestored:
         {
            NSLog(@"Transaction state -> Restored");
            //add the same code as you did from SKPaymentTransactionStatePurchased here
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [spinner stopAnimating];
            break;
         }
         case SKPaymentTransactionStateFailed:
         {
            NSLog(@"Transaction state -> Failed");
            //called when the transaction does not finnish
            if(transaction.error.code != SKErrorPaymentCancelled){
               NSLog(@"Transaction state -> Cancelled");
               //the user cancelled the payment ;(
            }
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [spinner stopAnimating];
            break;
         }
      }
   }
}

- (void)doRemoveAds{
   _areAdsRemoved = YES;
   _bannerView.hidden = YES;
   _removeAdsButton.visible = FALSE;
   [[NSUserDefaults standardUserDefaults] setBool:_areAdsRemoved forKey:@"areAdsRemoved"];
}

@end
