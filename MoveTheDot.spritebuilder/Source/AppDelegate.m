/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2012 Zynga Inc.
 * Copyright (c) 2013 Apportable Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "cocos2d.h"

#import "AppDelegate.h"
#import "CCBuilderReader.h"
#import "Gameplay.h"

@implementation AppController
{
   AVAudioPlayer *playSound;
}

@synthesize gamePlay;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure Cocos2d with the options set in SpriteBuilder
    NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Published-iOS"]; // TODO: add support for Published-Android support
    configPath = [configPath stringByAppendingPathComponent:@"configCocos2d.plist"];
    
    NSMutableDictionary* cocos2dSetup = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
    
    // Note: this needs to happen before configureCCFileUtils is called, because we need apportable to correctly setup the screen scale factor.
#ifdef APPORTABLE
    if([cocos2dSetup[CCSetupScreenMode] isEqual:CCScreenModeFixed])
        [UIScreen mainScreen].currentMode = [UIScreenMode emulatedMode:UIScreenAspectFitEmulationMode];
    else
        [UIScreen mainScreen].currentMode = [UIScreenMode emulatedMode:UIScreenScaledAspectFitEmulationMode];
#endif
    
    // Configure CCFileUtils to work with SpriteBuilder
    [CCBReader configureCCFileUtils];
    
    // Do any extra configuration of Cocos2d here (the example line changes the pixel format for faster rendering, but with less colors)
    //[cocos2dSetup setObject:kEAGLColorFormatRGB565 forKey:CCConfigPixelFormat];
    
    [self setupCocos2dWithOptions:cocos2dSetup];
   
   // The AV Audio Player needs a URL to the file that will be played to be specified.
   // So, we're going to set the audio file's path and then convert it to a URL.
   // play sound
   NSString *audioFilePath1 = [[NSBundle mainBundle] pathForResource:@"soothing" ofType:@"wav"];
   NSURL *pathAsURL1 = [[NSURL alloc] initFileURLWithPath:audioFilePath1];
   NSError *error1;
   playSound = [[AVAudioPlayer alloc] initWithContentsOfURL:pathAsURL1 error:&error1];
   playSound.numberOfLoops = -1;
   playSound.volume = 0.5;
   
   // Check out what's wrong in case that the player doesn't init.
   if (error1) {
      NSLog(@"%@", [error1 localizedDescription]);
   }
   else{
      // In this example we'll pre-load the audio into the buffer. You may avoid it if you want
      // as it's not always possible to pre-load the audio.
      if(playSound.playing == FALSE)
      {
         [playSound prepareToPlay];
         [playSound play];
      }
   }
   
//   [playSound setDelegate:self];
   GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
   
   localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
      if (viewController != nil) {
         [[CCDirector sharedDirector] presentViewController:viewController animated:YES completion:nil];
      }
      else{
         if ([GKLocalPlayer localPlayer].authenticated) {
            gamePlay.gameCenterEnabled = YES;
            
            // Get the default leaderboard identifier.
            [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
               
               if (error != nil) {
                  NSLog(@"%@", [error localizedDescription]);
               }
               else{
                  gamePlay.leaderboardIdentifier = leaderboardIdentifier;
               }
            }];
         }
         
         else{
            gamePlay.gameCenterEnabled = NO;
         }
      }
   };
   
    return YES;
}

- (CCScene*) startScene
{
    return [CCBReader loadAsScene:@"Gameplay"];
}

@end
