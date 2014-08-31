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


@interface Gameplay : CCNode <CCPhysicsCollisionDelegate, UIGestureRecognizerDelegate, AVAudioPlayerDelegate,GKGameCenterControllerDelegate>
{
}

@property NSInteger highScore;
// A flag indicating whether the Game Center features can be used after a user has been authenticated.
@property (nonatomic) BOOL gameCenterEnabled;

// This property stores the default leaderboard's identifier.
@property (nonatomic, strong) NSString *leaderboardIdentifier;


-(void)screenWasSwipedUp;
-(void)screenWasSwipedDown;
-(void)authenticateLocalPlayer;
-(void)reportScore;
-(void)showLeaderboardAndAchievements:(BOOL)shouldShowLeaderboard;

@end
