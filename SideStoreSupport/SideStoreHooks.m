//
//  SideStoreHooks.m
//  LiveContainer
//
//  Created by s s on 2026/8/6.
//
#include "../LiveContainer/utils.h"
#include "../LiveContainer/LCSharedUtils.h"
#include "XPCServer.h"
#import <sys/sysctl.h>
@import UserNotifications;
@import UIKit;

@interface LCAuthorizedNotificationSettings : UNNotificationSettings
@end

@implementation LCAuthorizedNotificationSettings

- (UNAuthorizationStatus)authorizationStatus {
    return UNAuthorizationStatusAuthorized;
}

@end

static NSMutableDictionary<NSString *, UIWindow *> *SSVersionWindows;
static id SSSceneObserver;

@interface PassthroughWindow : UIWindow
@end

@implementation PassthroughWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return nil;
}

@end

@implementation UNUserNotificationCenter(SideStoreHooks)

- (void)lc_addNotificationRequest:(UNNotificationRequest*)request
            withCompletionHandler:(void (^)(NSError* error))completionHandler {
    LiveProcessSideStoreHandler* handler = [PrivClass(LiveProcessSideStoreHandler) shared];
    [handler.server addNotificationRequest:request];
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (void)lc_removePendingNotificationRequestsWithIdentifiers:(NSArray<NSString*>*)identifiers {
    LiveProcessSideStoreHandler* handler = [PrivClass(LiveProcessSideStoreHandler) shared];
    [handler.server removePendingNotificationRequestsWithIdentifiers:identifiers];
}

- (void)lc_getNotificationSettingsWithCompletionHandler:(void (^)(UNNotificationSettings* settings))completionHandler {
    if (!completionHandler) {
        return;
    }

    UNNotificationSettings* settings = class_createInstance(LCAuthorizedNotificationSettings.class, 0);
    completionHandler(settings);
}

@end

@implementation NSBundle(SideStoreHooks)

+ (NSString*)hook_appbundleIdentifier {
    return @"com.kdt.livecontainer";
}

+ (NSString*)hook_storeAppBundleIdentifier {
    return @"com.kdt.livecontainer";
}

- (NSString*)hook_altstoreAppGroup {
    return LCSharedUtils.appGroupID;
}

+ (NSString*)hook_baseAltStoreAppGroupID {
    return @"group.com.SideStore.SideStore";
}

+ (NSBundle*)hook_activeBundle {
    if (!NSUserDefaults.isLiveProcess) return NSUserDefaults.lcMainBundle;
    
    static NSBundle* lcAppBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lcAppBundle = [NSBundle bundleWithURL: NSUserDefaults.lcMainBundle.bundleURL.URLByDeletingLastPathComponent.URLByDeletingLastPathComponent];
    });
    return lcAppBundle;
}

@end

// BEGIN MME_CLIENT_INFO_FIX (compiled by .github/tests/mme_client_info_test.m)
// Since 2026-11-20 Apple's GSA edge answers 503 when X-Mme-Client-Info names the OS "macOS;".
// "Mac OS X;" is accepted, so rewrite it on every request SideStore builds, whatever the
// value's source (built-in default, anisette server, or user override).
static NSString* LCFixMmeClientInfo(NSString* field, NSString* value) {
    if (![field isKindOfClass:NSString.class] || ![value isKindOfClass:NSString.class]) return value;
    if ([field caseInsensitiveCompare:@"X-Mme-Client-Info"] != NSOrderedSame) return value;
    return [value stringByReplacingOccurrencesOfString:@"<macOS;"
                                            withString:@"<Mac OS X;"
                                               options:NSCaseInsensitiveSearch
                                                 range:NSMakeRange(0, value.length)];
}

@implementation NSMutableURLRequest(SideStoreHooks)

- (void)lc_setValue:(NSString*)value forHTTPHeaderField:(NSString*)field {
    [self lc_setValue:LCFixMmeClientInfo(field, value) forHTTPHeaderField:field];
}

- (void)lc_addValue:(NSString*)value forHTTPHeaderField:(NSString*)field {
    [self lc_addValue:LCFixMmeClientInfo(field, value) forHTTPHeaderField:field];
}

- (void)lc_setAllHTTPHeaderFields:(NSDictionary<NSString*, NSString*>*)fields {
    NSMutableDictionary* fixed = fields ? [NSMutableDictionary dictionaryWithCapacity:fields.count] : nil;
    for (NSString* key in fields) {
        [fixed setObject:LCFixMmeClientInfo(key, [fields objectForKey:key]) forKey:key];
    }
    [self lc_setAllHTTPHeaderFields:fixed];
}

@end
// END MME_CLIENT_INFO_FIX

NSURL* SideStoreSource_hook_altStoreSourceURL(id self, SEL cmd) {
    static NSURL* sourceURL = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Builds made from a fork set LCUpdateSourceURL so built-in SideStore updates LC from that fork.
        NSString* custom = NSUserDefaults.lcMainBundle.infoDictionary[@"LCUpdateSourceURL"];
        if ([custom isKindOfClass:NSString.class] && custom.length > 0) {
            sourceURL = [NSURL URLWithString:custom];
        }
        if (!sourceURL) {
            sourceURL = [NSURL URLWithString:@"https://github.com/LiveContainer/LiveContainer/releases/download/1.0/apps_ss_lc.json"];
        }
    });
    return sourceURL;
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
void (*SideStoreMyAppsViewController_orig_viewDidload)(UICollectionViewController* self, SEL cmd) = nil;
void SideStoreMyAppsViewController_hook_viewDidload(UICollectionViewController* self, SEL cmd) {
    if(!SideStoreMyAppsViewController_orig_viewDidload) return;
    SideStoreMyAppsViewController_orig_viewDidload(self, cmd);
    
    UIImage *escapeImage = [UIImage systemImageNamed:@"escape"];
    UIBarButtonItem *escapeItem = [[UIBarButtonItem alloc] initWithImage:escapeImage
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(escapeButtonTapped:)];
        
    NSMutableArray* oldToolBarItems = [self.navigationItem.leftBarButtonItems mutableCopy];
    [oldToolBarItems addObject:escapeItem];
    self.navigationItem.leftBarButtonItems = oldToolBarItems;
}

void SideStoreMyAppsViewController_hook_escapeButtonTapped(UICollectionViewController* self, SEL cmd, id target) {
    [LCSharedUtils launchToGuestAppWithClassicMode:0];
}





static void SSInstallVersionWindow(UIWindowScene *windowScene)
{
    NSString *identifier = windowScene.session.persistentIdentifier;
    if (identifier.length == 0 || SSVersionWindows[identifier] != nil) {
        return;
    }
    
    
    NSString* LCVersion = [NSString stringWithFormat:@"%@-%@",
                         NSUserDefaults.lcMainBundle.infoDictionary[@"CFBundleShortVersionString"],
                         NSUserDefaults.lcMainBundle.infoDictionary[@"LCVersionInfo"]];
    
    NSString* SSVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    size_t size = 32;
    char iosBuild[32];
    sysctlbyname("kern.osversion", iosBuild, &size, NULL, 0);
    bool isPhone = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    NSString* allVersionString = [NSString stringWithFormat:isPhone ? @"LC %@, SS %@\niOS %@ (%s), sign-in fix on" : @"LC %@, SS %@, iOS %@ (%s), sign-in fix on", LCVersion, SSVersion, osVersion, iosBuild];

    UILabel* versionLabel = [UILabel new];
    versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    versionLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightRegular];
    versionLabel.textColor = UIColor.labelColor;
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.userInteractionEnabled = NO;
    versionLabel.text = allVersionString;
    versionLabel.numberOfLines = 0;
    versionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    UIViewController *rootController = [[UIViewController alloc] init];
    rootController.view.backgroundColor = UIColor.clearColor;
    [rootController.view addSubview:versionLabel];
    
    if(windowScene.keyWindow.safeAreaInsets.bottom == 0) {
        // old devices with no bottom safe area
        [NSLayoutConstraint activateConstraints:@[
            [versionLabel.centerXAnchor constraintEqualToAnchor:rootController.view.centerXAnchor],
            [versionLabel.topAnchor constraintEqualToAnchor: rootController.view.safeAreaLayoutGuide.topAnchor]
        ]];
    } else {
        // new devices
        [NSLayoutConstraint activateConstraints:@[
            [versionLabel.centerXAnchor constraintEqualToAnchor:rootController.view.centerXAnchor],
            [versionLabel.bottomAnchor constraintEqualToAnchor: rootController.view.safeAreaLayoutGuide.bottomAnchor
                                                      constant: isPhone ? 22 : 0]
        ]];
    }
    PassthroughWindow *window = [[PassthroughWindow alloc] initWithWindowScene:windowScene];

    window.rootViewController = rootController;
    window.backgroundColor = UIColor.clearColor;

    window.windowLevel = UIWindowLevelAlert;

    window.hidden = NO;

    SSVersionWindows[identifier] = window;
}


void installSideStoreHooks(void) {

    swizzleClassMethod(NSBundle.class, @selector(appbundleIdentifier), @selector(hook_appbundleIdentifier));
    swizzleClassMethod(NSBundle.class, @selector(storeAppBundleIdentifier), @selector(hook_storeAppBundleIdentifier));
    swizzle(NSBundle.class, @selector(altstoreAppGroup), @selector(hook_altstoreAppGroup));
    swizzleClassMethod(NSBundle.class, @selector(activeBundle), @selector(hook_activeBundle));
    swizzleClassMethod(NSBundle.class, @selector(baseAltStoreAppGroupID), @selector(hook_baseAltStoreAppGroupID));

    // fix Apple ID sign-in 503 (see LCFixMmeClientInfo)
    swizzle(NSMutableURLRequest.class, @selector(setValue:forHTTPHeaderField:), @selector(lc_setValue:forHTTPHeaderField:));
    swizzle(NSMutableURLRequest.class, @selector(addValue:forHTTPHeaderField:), @selector(lc_addValue:forHTTPHeaderField:));
    swizzle(NSMutableURLRequest.class, @selector(setAllHTTPHeaderFields:), @selector(lc_setAllHTTPHeaderFields:));

    // replace altStoreSourceURL
    Method altStoreSourceURLMethod = class_getClassMethod(PrivClass(Source), @selector(altStoreSourceURL));
    method_setImplementation(altStoreSourceURLMethod, (IMP)SideStoreSource_hook_altStoreSourceURL);
    
    if (!NSUserDefaults.isLiveProcess) {
        // add escape button
        Method viewDidLoadMethod = class_getInstanceMethod(PrivClass(MyAppsViewController), @selector(viewDidLoad));
        SideStoreMyAppsViewController_orig_viewDidload = (void (*)(UICollectionViewController *, SEL))method_getImplementation(viewDidLoadMethod);
        method_setImplementation(viewDidLoadMethod, (IMP)SideStoreMyAppsViewController_hook_viewDidload);
        class_addMethod(PrivClass(MyAppsViewController), @selector(escapeButtonTapped:), (IMP)SideStoreMyAppsViewController_hook_escapeButtonTapped, "v@:@");
        
        // add version number
        SSVersionWindows = [NSMutableDictionary dictionary];

        SSSceneObserver =
        [NSNotificationCenter.defaultCenter addObserverForName:UISceneDidActivateNotification
                                                        object:nil
                                                         queue:NSOperationQueue.mainQueue
                                                    usingBlock:^(NSNotification *notification) {
            UIScene *scene = notification.object;
            
            if ([scene isKindOfClass:UIWindowScene.class]) {
                SSInstallVersionWindow((UIWindowScene *)scene);
            }
        }];
        
        
        
    }
    

}
#pragma clang diagnostic pop

void installSideStoreNotificationHooks(void) {
    swizzle(UNUserNotificationCenter.class,
            @selector(addNotificationRequest:withCompletionHandler:),
            @selector(lc_addNotificationRequest:withCompletionHandler:));
    swizzle(UNUserNotificationCenter.class,
            @selector(removePendingNotificationRequestsWithIdentifiers:),
            @selector(lc_removePendingNotificationRequestsWithIdentifiers:));
    swizzle(UNUserNotificationCenter.class,
            @selector(getNotificationSettingsWithCompletionHandler:),
            @selector(lc_getNotificationSettingsWithCompletionHandler:));
}
