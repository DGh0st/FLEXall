#import "FLEXManager.h"
#import "FLEXWindow.h"
#import "FLEXExplorerViewController.h"
#import "FLEXObjectExplorerViewController.h"

@interface SpringBoard : UIApplication // iOS 3 - 12
-(BOOL)isLocked; // iOS 4 - 12
-(id)statusBar; // iOS 4 - 12
-(id)_accessibilityTopDisplay; // iOS 5 - 12
@end

@interface UIStatusBar : UIView // iOS 4 - 12
-(id)foregroundColor; // iOS 7 - 12 (inherited on iOS 11+)
-(void)setForegroundColor:(id)arg1; // iOS 7 - 12 (inherited on iOS 11+)
@end

@interface _UIStatusBar : UIView // iOS 11 - 12 (modern status bar)
-(id)foregroundColor; // iOS 11 - 12
-(void)setForegroundColor:(id)arg1; // iOS 11 - 12
@end

@interface SBBacklightController : NSObject // iOS 7 - 12
+(id)sharedInstance; // iOS 7 - 12
-(NSTimeInterval)defaultLockScreenDimInterval; // iOS 7 - 12
-(void)preventIdleSleepForNumberOfSeconds:(NSTimeInterval)arg1; // iOS 7 - 12
-(void)resetLockScreenIdleTimer; // iOS 7 - 10
@end

@interface UIStatusBarWindow : UIWindow // iOS 4 - 12
@end

@interface FLEXExplorerViewController (PrivateFLEXall)
@property (nonatomic, strong) UIColor *previousStatusBarForegroundColor;
-(void)resignKeyAndDismissViewControllerAnimated:(BOOL)arg1 completion:(id)arg2;
@end

@interface FLEXManager (PrivateFLEXall)
@property (nonatomic, strong) FLEXExplorerViewController *explorerViewController;
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
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:[FLEXManager sharedManager] action:@selector(showExplorer)];
		[self addGestureRecognizer:longPress];
	}
	return self;
}
%end

%group StatusBarFixColor
%hook FLEXExplorerViewController
%property (nonatomic, strong) UIColor *previousStatusBarForegroundColor;

-(void)makeKeyAndPresentViewController:(id)arg1 animated:(BOOL)arg2 completion:(id)arg3 {
	%orig(arg1, arg2, arg3);

	id statusBar = [(SpringBoard *)[%c(SpringBoard) sharedApplication] statusBar];
	self.previousStatusBarForegroundColor = [statusBar foregroundColor];
	[statusBar setForegroundColor:[UIColor blackColor]];
}

-(void)resignKeyAndDismissViewControllerAnimated:(BOOL)arg1 completion:(id)arg2 {
	%orig(arg1, arg2);

	id statusBar = [(SpringBoard *)[%c(SpringBoard) sharedApplication] statusBar];
	if (self.previousStatusBarForegroundColor != nil) {
		if ([statusBar isKindOfClass:%c(_UIStatusBar)])
			[(_UIStatusBar *)statusBar setForegroundColor:self.previousStatusBarForegroundColor];
		else if ([statusBar isKindOfClass:%c(UIStatusBar)])
			[(UIStatusBar *)statusBar setForegroundColor:self.previousStatusBarForegroundColor];
		self.previousStatusBarForegroundColor = nil;
	}
}
%end
%end

%ctor {
	if (%c(SpringBoard))
		%init(StatusBarFixColor);
	%init();
}