#import "FLEXManager.h"
#import "FLEXWindow.h"

@interface SpringBoard : UIApplication // iOS 3 - 12
-(BOOL)isLocked; // iOS 4 - 12
@end

@interface SBBacklightController : NSObject // iOS 7 - 12
+(id)sharedInstance; // iOS 7 - 12
-(NSTimeInterval)defaultLockScreenDimInterval; // iOS 7 - 12
-(void)preventIdleSleepForNumberOfSeconds:(NSTimeInterval)arg1; // iOS 7 - 12
-(void)resetLockScreenIdleTimer; // iOS 7 - 10
@end

@interface UIStatusBarWindow : UIWindow // iOS 4 - 12
@end

#define REGISTER_THREE_FINGER_GESTURE()																																	\
	if (![self isKindOfClass:%c(FLEXWindow)]) {																											\
		UILongPressGestureRecognizer *threeFinger = [[UILongPressGestureRecognizer alloc] initWithTarget:[FLEXManager sharedManager] action:@selector(showExplorer)];	\
		threeFinger.numberOfTouchesRequired = 3;																																\
		[self addGestureRecognizer:threeFinger];																														\
	}

%hook UIWindow
-(void)becomeKeyWindow {
	%orig();

	REGISTER_THREE_FINGER_GESTURE();
}
%end

%hook FLEXWindow
-(BOOL)_shouldCreateContextAsSecure {
	return YES;	
}

-(id)initWithFrame:(CGRect)arg1 {
	self = %orig(arg1);
	if (self != nil)
		self.windowLevel = 2050; // above springboard alert window but below flash window (and callout bar stuff)
	return self;
}

-(id)hitTest:(CGPoint)arg1 withEvent:(id)arg2 {
	id result = %orig();
	if ([(SpringBoard *)[%c(SpringBoard) sharedApplication] isLocked]) {
		SBBacklightController *backlightController = [%c(SBBacklightController) sharedInstance];
		if ([backlightController respondsToSelector:@selector(resetLockScreenIdleTimer)])
			[backlightController resetLockScreenIdleTimer];
		else
			[backlightController preventIdleSleepForNumberOfSeconds:[backlightController defaultLockScreenDimInterval]];
	}
	return result;
}
%end

%hook UIStatusBarWindow
-(id)initWithFrame:(CGRect)arg1 {
	self = %orig(arg1);
	if (self != nil) {
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:[FLEXManager sharedManager] action:@selector(showExplorer)];
		[self addGestureRecognizer:longPress];
	}
	return self;
}
%end