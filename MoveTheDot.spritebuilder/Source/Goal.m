//
//  Goal.m
//  1stShot
//
//  Created by Faisal on 5/2/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Goal.h"

@implementation Goal

- (void)didLoadFromCCB {
    self.physicsBody.collisionType = @"goal";
    self.physicsBody.sensor = TRUE;
}

@end
