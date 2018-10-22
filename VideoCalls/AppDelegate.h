//
//  AppDelegate.h
//  VideoCalls
//
//  Created by Ivan Sein on 30.05.17.
//  Copyright © 2017 struktur AG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, PKPushRegistryDelegate>
{
    PKPushRegistry *pushRegistry;
}
@property (strong, nonatomic) UIWindow *window;


@end

