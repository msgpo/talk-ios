//
//  NCNotificationController.m
//  VideoCalls
//
//  Created by Ivan Sein on 23.10.18.
//  Copyright © 2018 struktur AG. All rights reserved.
//

#import "NCNotificationController.h"
#import <UserNotifications/UserNotifications.h>

#import "NCAPIController.h"
#import "NCConnectionController.h"
#import "NCNotification.h"
#import "NCUserInterfaceController.h"

@interface NCNotificationController () <UNUserNotificationCenterDelegate>

@property (nonatomic, strong) UNUserNotificationCenter *notificationCenter;

@end

@implementation NCNotificationController

+ (NCNotificationController *)sharedInstance
{
    static dispatch_once_t once;
    static NCNotificationController *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        _notificationCenter.delegate = self;
    }
    
    return self;
}

- (void)processIncomingPushNotification:(NCPushNotification *)pushNotification
{
    if (pushNotification) {
        if (pushNotification.type == NCPushNotificationTypeChat) {
            NSInteger notificationId = pushNotification.notificationId;
            if (notificationId) {
                [[NCAPIController sharedInstance] getServerNotification:notificationId withCompletionBlock:^(NSDictionary *notification, NSError *error) {
                    if (!error) {
                        NCNotification *serverNotification = [NCNotification notificationWithDictionary:notification];
                        [self showLocalNotificationForPushNotification:pushNotification withServerNotification:serverNotification];
                    } else {
                        NSLog(@"Could not retrieve server notification.");
                        [self showLocalNotificationForPushNotification:pushNotification withServerNotification:nil];
                    }
                }];
            }
        } else {
            [self showLocalNotificationForPushNotification:pushNotification withServerNotification:nil];
        }
    }
}

- (void)showLocalNotificationForPushNotification:(NCPushNotification *)pushNotification withServerNotification:(NCNotification *)serverNotification
{
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.body = pushNotification.bodyForRemoteAlerts;
    if (serverNotification && serverNotification.notificationType == kNCNotificationTypeChat) {
        content.title = serverNotification.chatMessageTitle;
        content.body = serverNotification.message;
    }
    content.sound = [UNNotificationSound defaultSound];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:pushNotification.jsonString forKey:@"pushNotification"];
    content.userInfo = userInfo;
    
    NSString *identifier = [NSString stringWithFormat:@"Notification-%ld", (long)pushNotification.notificationId];
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    [_notificationCenter addNotificationRequest:request withCompletionHandler:nil];
}

#pragma mark - UNUserNotificationCenter delegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    UNNotificationRequest *notificationRequest = response.notification.request;
    NSString *notificationString = [notificationRequest.content.userInfo objectForKey:@"pushNotification"];
    NCPushNotification *pushNotification = [NCPushNotification pushNotificationFromDecryptedString:notificationString];
    
    if (pushNotification) {
        switch (pushNotification.type) {
            case NCPushNotificationTypeCall:
            {
                [[NCUserInterfaceController sharedInstance] presentAlertForPushNotification:pushNotification];
            }
                break;
            case NCPushNotificationTypeRoom:
            case NCPushNotificationTypeChat:
            {
                [[NCUserInterfaceController sharedInstance] presentChatForPushNotification:pushNotification];
            }
                break;
            default:
                break;
        }
    }
    
    completionHandler();
}

@end
