#import "UIAlertController+PrivateAPI.h"

@implementation UIAlertController (PrivateAPI)

-(void)triggerAction:(UIAlertAction *)action {
    SEL selector = NSSelectorFromString(@"_dismissAnimated:triggeringAction:triggeredByPopoverDimmingView:dismissCompletion:");
    NSMethodSignature* signature = [[self class] instanceMethodSignatureForSelector:selector];
    NSAssert(signature != nil, @"Couldn't find trigger method");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    BOOL boolValue = YES;
    [invocation setArgument:&boolValue atIndex:2];
    [invocation setArgument:&action atIndex:3];
    [invocation setArgument:&boolValue atIndex:4];
    // Not setting anything for the dismissCompletion block atIndex:5
    [invocation invoke];
}

@end
