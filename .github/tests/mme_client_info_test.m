#import <Foundation/Foundation.h>
#import <objc/runtime.h>
static inline void swizzle(Class class, SEL originalAction, SEL swizzledAction) {
    method_exchangeImplementations(class_getInstanceMethod(class, originalAction), class_getInstanceMethod(class, swizzledAction));
}
#include "mme_client_info_fix.inc"
static int fails = 0;
#define CHECK(c, msg) do { if (!(c)) { fails++; NSLog(@"FAIL: %@", msg); } else NSLog(@"ok: %@", msg); } while(0)
int main(void) { @autoreleasepool {
    swizzle(NSMutableURLRequest.class, @selector(setValue:forHTTPHeaderField:), @selector(lc_setValue:forHTTPHeaderField:));
    swizzle(NSMutableURLRequest.class, @selector(addValue:forHTTPHeaderField:), @selector(lc_addValue:forHTTPHeaderField:));
    swizzle(NSMutableURLRequest.class, @selector(setAllHTTPHeaderFields:), @selector(lc_setAllHTTPHeaderFields:));
    NSString* def = @"<MacBookPro18,3> <macOS;26.6;25F84> <com.apple.AuthKit/1 (com.apple.akd/1.0)>";
    NSString* want = @"<MacBookPro18,3> <Mac OS X;26.6;25F84> <com.apple.AuthKit/1 (com.apple.akd/1.0)>";
    NSMutableURLRequest* r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://gsa.apple.com/grandslam/GsService2"]];
    [r setValue:def forHTTPHeaderField:@"X-MMe-Client-Info"];
    CHECK([[r valueForHTTPHeaderField:@"X-MMe-Client-Info"] isEqual:want], @"setValue X-MMe-Client-Info (SideSign casing)");
    [r setValue:def forHTTPHeaderField:@"X-Mme-Client-Info"];
    CHECK([[r valueForHTTPHeaderField:@"X-Mme-Client-Info"] isEqual:want], @"setValue X-Mme-Client-Info (AnisetteKit casing)");
    [r setValue:@"<Mac15,7> <macOS;27.0;26A5378j> <com.apple.AuthKit/1 (com.apple.akd/1.0)>" forHTTPHeaderField:@"x-mme-client-info"];
    CHECK([[r valueForHTTPHeaderField:@"X-Mme-Client-Info"] isEqual:@"<Mac15,7> <Mac OS X;27.0;26A5378j> <com.apple.AuthKit/1 (com.apple.akd/1.0)>"], @"reporter's 503 string becomes their 401 string");
    [r setValue:want forHTTPHeaderField:@"X-Mme-Client-Info"];
    CHECK([[r valueForHTTPHeaderField:@"X-Mme-Client-Info"] isEqual:want], @"already-fixed value untouched");
    [r setValue:@"<iPhone> <iPhone OS;27.2;24B156> <x>" forHTTPHeaderField:@"X-Mme-Client-Info"];
    CHECK([[r valueForHTTPHeaderField:@"X-Mme-Client-Info"] isEqual:@"<iPhone> <iPhone OS;27.2;24B156> <x>"], @"non-macOS value untouched");
    [r setValue:@"AuthKit/1 (Macintosh; macOS;26.6)" forHTTPHeaderField:@"User-Agent"];
    CHECK([[r valueForHTTPHeaderField:@"User-Agent"] isEqual:@"AuthKit/1 (Macintosh; macOS;26.6)"], @"other headers untouched");
    [r setValue:nil forHTTPHeaderField:@"X-Mme-Client-Info"];
    CHECK([r valueForHTTPHeaderField:@"X-Mme-Client-Info"] == nil, @"nil value removes header");
    NSMutableURLRequest* r2 = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://gsa.apple.com/"]];
    [r2 addValue:def forHTTPHeaderField:@"X-Mme-Client-Info"];
    CHECK([[r2 valueForHTTPHeaderField:@"X-Mme-Client-Info"] isEqual:want], @"addValue");
    NSMutableURLRequest* r3 = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://gsa.apple.com/"]];
    [r3 setAllHTTPHeaderFields:@{@"X-MMe-Client-Info": def, @"Accept": @"*/*"}];
    CHECK([[r3 valueForHTTPHeaderField:@"X-Mme-Client-Info"] isEqual:want] && [[r3 valueForHTTPHeaderField:@"Accept"] isEqual:@"*/*"], @"setAllHTTPHeaderFields");
    [r3 setAllHTTPHeaderFields:nil];
    CHECK(YES, @"setAllHTTPHeaderFields:nil does not crash");
    NSLog(@"%d failure(s)", fails);
    return fails;
}}
