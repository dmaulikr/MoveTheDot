//
//  Gameplay.h
//  1stShot
//
//  Created by Faisal on 4/25/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"
#import <AVFoundation/AVFoundation.h>


@interface Gameplay : CCNode <CCPhysicsCollisionDelegate, UIGestureRecognizerDelegate, AVAudioPlayerDelegate>
{
}

@property NSInteger highScore;

-(void)screenWasSwipedUp;
-(void)screenWasSwipedDown;

@end
