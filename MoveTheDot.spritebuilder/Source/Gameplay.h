//
//  Gameplay.h
//  1stShot
//
//  Created by Faisal on 4/25/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"
#import <AVFoundation/AVFoundation.h>
#import <GameKit/GameKit.h>
#import "GADInterstitial.h"
#import "GADBannerView.h"
#import "StoreKit/StoreKit.h"


@interface Gameplay : CCNode <CCPhysicsCollisionDelegate, UIGestureRecognizerDelegate, AVAudioPlayerDelegate,GKGameCenterControllerDelegate,GADBannerViewDelegate,GADInterstitialDelegate,SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
}

@property NSInteger highScore;
@property BOOL areAdsRemoved;
// A flag indicating whether the Game Center features can be used after a user has been authenticated.
@property (nonatomic) BOOL gameCenterEnabled;

// This property stores the default leaderboard's identifier.
@property (nonatomic, strong) NSString *leaderboardIdentifier;


-(void)screenWasSwipedUp;
-(void)screenWasSwipedDown;
// game center
-(void)reportScore;
-(void)showLeaderboardAndAchievements:(BOOL)shouldShowLeaderboard;
// iap
//-(void)purchase;
//-(void)restore;
//-(void)tapsRemoveAds;
// Interstitials
-(void)cycleInterstitial;
-(void)presentInterlude;



@end
