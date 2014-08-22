//
//  Obstacle.m
//  1stShot
//
//  Created by Faisal on 5/1/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Obstacle.h"
@implementation Obstacle {
    CCNode *_topPipe;
    CCNode *_bottomPipe;
    int _random;
    int _yPosition;
}
// distance between top and bottom pipe
static const CGFloat pipeDistance = 50.f;
//static const CGFloat scrollSpeed = 1.f;

- (void)setupRandomPosition {
    _random = arc4random() % 4;
    switch(_random)
    {
        case 0:
            _yPosition = 210; // hero position 330
//          _yPosition = 210;
            break;
        case 1:
            _yPosition = 290;//hero position 250
//          _yPosition = 210;
            break;
        case 2:
            _yPosition = 370; // hero position 170
//          _yPosition = 210;
            break;
        case 3:
            _yPosition = 450; // hero position 90
//          _yPosition = 210;
            break;
        default:
            break;
    }
    _topPipe.position = ccp(_topPipe.position.x, _yPosition);
    _bottomPipe.position = ccp(_bottomPipe.position.x, _topPipe.position.y + pipeDistance);
//    CCLOG(@"%d",_yPosition);
   //    CCLOG(@"%f",_bottomPipe.position.x);
//    CCLOG(@"%f",_topPipe.position.y);
}

- (void)didLoadFromCCB {
    _topPipe.physicsBody.collisionType = @"level";
    _topPipe.physicsBody.sensor = TRUE;
    _bottomPipe.physicsBody.collisionType = @"level";
    _bottomPipe.physicsBody.sensor = TRUE;
}

@end