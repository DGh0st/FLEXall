#import "FLEXManager.h"
#import "FLEXWindow.h"
#import "FLEXExplorerViewController.h"
#import "FLEXObjectExplorerViewController.h"

@interface SpringBoard : UIApplication // iOS 3 - 13
-(BOOL)isLocked; // iOS 4 - 13
// -(id)_accessibilityTopDisplay; // iOS 5 - 13
@end

@interface SBBacklightController : NSObject // iOS 7 - 13
+(id)sharedInstance; // iOS 7 - 13
// -(NSTimeInterval)defaultLockScreenDimInterval; // iOS 7 - 13
// -(void)preventIdleSleepForNumberOfSeconds:(NSTimeInterval)arg1; // iOS 7 - 13
-(void)resetLockScreenIdleTimer; // iOS 7 - 10
@end

@interface SBDashBoardIdleTimerProvider : NSObject // iOS 11 - 13
// -(void)addDisabledIdleTimerAssertionReason:(id)arg1; // iOS 11 - 13
// -(void)removeDisabledIdleTimerAssertionReason:(id)arg1; // iOS 11 - 13
// -(BOOL)isDisabledAssertionActiveForReason:(id)arg1; // iOS 11 - 13
-(void)resetIdleTimer; // iOS 11 - 13
@end

@interface SBDashBoardViewController : UIViewController { // iOS 10 - 12
	SBDashBoardIdleTimerProvider *_idleTimerProvider; // iOS 11 - 12
}
@end

@interface SBDashBoardIdleTimerController : NSObject { // iOS 13
	SBDashBoardIdleTimerProvider *_dashBoardIdleTimerProvider; // iOS 13
}
@end

@interface CSCoverSheetViewController : UIViewController // iOS 13
-(id)idleTimerController; // iOS 13
@end

@interface SBCoverSheetPresentationManager : NSObject // iOS 11 - 13
+(id)sharedInstance; // iOS 11 - 13
-(id)dashBoardViewController; // iOS 11 - 12
-(id)coverSheetViewController; // iOS 13
@end

@interface UIStatusBarWindow : UIWindow // iOS 4 - 13
@end

@interface UIStatusBarManager : NSObject // iOS 13
@property (nonatomic, retain) UIView *longPressStatusBarView;
@property (nonatomic, readonly) CGRect statusBarFrame; // iOS 13
@end

@interface FLEXExplorerViewController (PrivateFLEXall)
-(void)resignKeyAndDismissViewControllerAnimated:(BOOL)arg1 completion:(id)arg2;
@end

@interface FLEXManager (PrivateFLEXall)
@property (nonatomic, strong) FLEXExplorerViewController *explorerViewController;
@end

@interface NSObject (PrivateFLEXall)
-(id)safeValueForKey:(id)arg1;
@end

#define REGISTER_LONG_PRESS_GESTURE(window, fingers)																												\
	if (![window isKindOfClass:%c(FLEXWindow)]) {																													\
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:[FLEXManager sharedManager] action:@selector(showExplorer)];	\
		longPress.numberOfTouchesRequired = fingers;																												\
		[window addGestureRecognizer:longPress];																													\
	}

%hook UIWindow
-(void)becomeKeyWindow {
	%orig();

	REGISTER_LONG_PRESS_GESTURE(self, 3);
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
		if ([backlightController respondsToSelector:@selector(resetLockScreenIdleTimer)]) {
			[backlightController resetLockScreenIdleTimer];
		} else {
			SBCoverSheetPresentationManager *presentationManager = [%c(SBCoverSheetPresentationManager) sharedInstance];
			SBDashBoardIdleTimerProvider *_idleTimerProvider = nil;
			if ([presentationManager respondsToSelector:@selector(dashBoardViewController)]) {
				SBDashBoardViewController *dashBoardViewController = [presentationManager dashBoardViewController];
				_idleTimerProvider = [dashBoardViewController safeValueForKey:@"_idleTimerProvider"];
			} else if ([presentationManager respondsToSelector:@selector(coverSheetViewController)]) {
				SBDashBoardIdleTimerController *dashboardIdleTimerController = [[presentationManager coverSheetViewController] idleTimerController];
				_idleTimerProvider = [dashboardIdleTimerController safeValueForKey:@"_dashBoardIdleTimerProvider"];
			}
			[_idleTimerProvider resetIdleTimer];
		}
	}
	return result;
}
%end

%hook FLEXObjectExplorerViewController
-(void)viewDidLoad {
	%orig();

	if (self.navigationItem.rightBarButtonItems.count == 0)
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDonePressed:)];
}

%new
-(void)handleDonePressed:(id)arg1 {
	[[FLEXManager sharedManager].explorerViewController resignKeyAndDismissViewControllerAnimated:YES completion:nil];
}
%end

%hook UIStatusBarWindow
-(id)initWithFrame:(CGRect)arg1 {
	self = %orig(arg1);
	if (self != nil) {
		REGISTER_LONG_PRESS_GESTURE(self, 1);
	}
	return self;
}
%end