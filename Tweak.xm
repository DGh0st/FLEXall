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
-(void)addDisabledIdleTimerAssertionReason:(id)arg1; // iOS 11 - 13
-(void)removeDisabledIdleTimerAssertionReason:(id)arg1; // iOS 11 - 13
// -(BOOL)isDisabledAssertionActiveForReason:(id)arg1; // iOS 11 - 13
// -(void)resetIdleTimer; // iOS 11 - 13
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

@interface UIStatusBarTapAction : NSObject // iOS 13
@property (nonatomic, readonly) NSInteger type; // iOS 13
@end

@interface UIStatusBar : UIView // iOS 4 - 13
@end

@interface SBMainDisplaySceneLayoutStatusBarView : UIView // iOS 13
-(void)_statusBarTapped:(id)arg1 type:(NSInteger)arg2; // iOS 13
@end

@interface FLEXExplorerViewController : UIViewController
-(void)resignKeyAndDismissViewControllerAnimated:(BOOL)arg1 completion:(id)arg2;
@end

@interface FLEXManager : NSObject
@property (nonatomic) FLEXExplorerViewController *explorerViewController;
+(FLEXManager *)sharedManager;
-(void)showExplorer;
@end

@interface FLEXWindow : UIWindow
@end

typedef NS_ENUM(NSUInteger, FLEXObjectExplorerSection) {
    FLEXObjectExplorerSectionDescription,
    FLEXObjectExplorerSectionCustom,
    FLEXObjectExplorerSectionProperties,
    FLEXObjectExplorerSectionIvars,
    FLEXObjectExplorerSectionMethods,
    FLEXObjectExplorerSectionClassMethods,
    FLEXObjectExplorerSectionSuperclasses,
    FLEXObjectExplorerSectionReferencingInstances
};

@interface FLEXObjectExplorerViewController : UITableViewController
@end

@interface NSObject (PrivateFLEXall)
-(id)safeValueForKey:(id)arg1;
@end

@interface UIWindow (PrivateFLEXall)
@property (nonatomic, strong) UILongPressGestureRecognizer *flexAllLongPress;
@end

#define kFLEXallLongPressType 1337
#define kFLEXallBlacklistPath @"/var/mobile/Library/Preferences/com.dgh0st.flexall.blacklist.plist"

static UILongPressGestureRecognizer *RegisterLongPressGesture(UIWindow *window, NSUInteger fingers) {
	UILongPressGestureRecognizer *longPress = nil;
	if (![window isKindOfClass:%c(FLEXWindow)]) {
		longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:[%c(FLEXManager) sharedManager] action:@selector(showExplorer)];
		longPress.numberOfTouchesRequired = fingers;
		[window addGestureRecognizer:longPress];
	}
	return longPress;
}

%hook UIWindow
%property (nonatomic, strong) UILongPressGestureRecognizer *flexAllLongPress;

-(void)becomeKeyWindow {
	%orig();

	if (self.flexAllLongPress == nil) {
		self.flexAllLongPress = RegisterLongPressGesture(self, 3);
	}
}

-(void)resignKeyWindow {
	if (self.flexAllLongPress != nil) {
		[self removeGestureRecognizer:self.flexAllLongPress];
		self.flexAllLongPress = nil;
	}

	%orig();
}
%end

%hook FLEXExplorerViewController
-(BOOL)_canShowWhileLocked {
	return YES;
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
%end

%hook FLEXObjectExplorerViewController
-(void)viewDidLoad {
	%orig();

	if (self.navigationItem.rightBarButtonItems.count == 0)
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDonePressed:)];
}

-(NSArray<NSNumber *> *)possibleExplorerSections {
	static NSArray<NSNumber *> *possibleSections = %orig();
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSNumber *referencingInstancesSection = @(FLEXObjectExplorerSectionReferencingInstances);
		NSMutableArray<NSNumber *> *newSections = [possibleSections mutableCopy];
		[newSections removeObject:referencingInstancesSection];
		NSUInteger newIndex = [newSections indexOfObject:@(FLEXObjectExplorerSectionCustom)];
		[newSections insertObject:referencingInstancesSection atIndex:newIndex + 1];
		possibleSections = [newSections copy];
	});
	return possibleSections;
}

%new
-(void)handleDonePressed:(id)arg1 {
	FLEXManager *flexManager = [%c(FLEXManager) sharedManager];
	[flexManager.explorerViewController resignKeyAndDismissViewControllerAnimated:YES completion:nil];
}
%end

%hook UIStatusBarWindow
-(id)initWithFrame:(CGRect)arg1 {
	self = %orig(arg1);
	if (self != nil) {
		RegisterLongPressGesture(self, 1);
	}
	return self;
}
%end

%group iOS13plusStatusBar
// runs in SpringBoard
%hook SBMainDisplaySceneLayoutStatusBarView
-(void)_addStatusBarIfNeeded {
	%orig();

	UIStatusBar *_statusBar = [self valueForKey:@"_statusBar"];
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_statusBarLongPressed:)];
	[_statusBar addGestureRecognizer:longPress];
}

%new
-(void)_statusBarLongPressed:(UILongPressGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		[self _statusBarTapped:recognizer type:kFLEXallLongPressType];
	}
}
%end

%hook UIStatusBarManager
// handled in applications
-(void)handleTapAction:(UIStatusBarTapAction *)arg1 {
	if (arg1.type == kFLEXallLongPressType) {
		[[%c(FLEXManager) sharedManager] showExplorer];
	} else {
		%orig(arg1);
	}
}
%end
%end

%group iOS11plusDisableIdleTimer
static SBDashBoardIdleTimerProvider *GetDashBoardIdleTimerProvider() {
	SBCoverSheetPresentationManager *presentationManager = [%c(SBCoverSheetPresentationManager) sharedInstance];
	SBDashBoardIdleTimerProvider *_idleTimerProvider = nil;
	if ([presentationManager respondsToSelector:@selector(dashBoardViewController)]) {
		SBDashBoardViewController *dashBoardViewController = [presentationManager dashBoardViewController];
		_idleTimerProvider = [dashBoardViewController safeValueForKey:@"_idleTimerProvider"];
	} else if ([presentationManager respondsToSelector:@selector(coverSheetViewController)]) {
		SBDashBoardIdleTimerController *dashboardIdleTimerController = [[presentationManager coverSheetViewController] idleTimerController];
		_idleTimerProvider = [dashboardIdleTimerController safeValueForKey:@"_dashBoardIdleTimerProvider"];
	}
	return _idleTimerProvider;
}

%hook FLEXManager
-(void)showExplorer {
	%orig();

	[GetDashBoardIdleTimerProvider() addDisabledIdleTimerAssertionReason:@"FLEXall"];
}

-(void)hideExplorer {
	%orig();

	[GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:@"FLEXall"];
}
%end
%end

%group preiOS11ResetIdleTimer
%hook FLEXWindow
-(id)hitTest:(CGPoint)arg1 withEvent:(id)arg2 {
	id result = %orig();
	if ([(SpringBoard *)[%c(SpringBoard) sharedApplication] isLocked]) {
		SBBacklightController *backlightController = [%c(SBBacklightController) sharedInstance];
		[backlightController resetLockScreenIdleTimer];
	}
	return result;
}
%end
%end

%ctor {
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if (args != nil && args.count != 0) {
		NSString *execPath = args[0];
		BOOL isSpringBoard = [[execPath lastPathComponent] isEqualToString:@"SpringBoard"];
		BOOL isApplication = [execPath rangeOfString:@"/Application"].location != NSNotFound;

		// get blacklisted processes
		NSArray *blacklistedProcesses = nil;
		if ([[NSFileManager defaultManager] fileExistsAtPath:kFLEXallBlacklistPath]) {
			/*
			Looks for the following format in blacklist plist:

				<dict>
					<key>blacklist</key>
					<array>
						<string>process.bundle.identifier</string>
					</array>
				</dict>
			*/
			NSMutableDictionary *blacklistDict = [NSMutableDictionary dictionaryWithContentsOfFile:kFLEXallBlacklistPath];
			blacklistedProcesses = [blacklistDict objectForKey:@"blacklist"];
		} else {
			blacklistedProcesses = @[
				@"com.toyopagroup.picaboo" // snapchat
			];
		}

		NSString *processBundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
		BOOL isBlacklisted = [blacklistedProcesses containsObject:processBundleIdentifier];
		if (!isBlacklisted && (isSpringBoard || isApplication) && dlopen("/Library/MobileSubstrate/DynamicLibraries/libFLEX.dylib", RTLD_LAZY)) {
			if (%c(UIStatusBarManager)) {
				%init(iOS13plusStatusBar);
			}

			if (%c(SBBacklightController) && [%c(SBBacklightController) instancesRespondToSelector:@selector(resetLockScreenIdleTimer)]) {
				%init(preiOS11ResetIdleTimer);
			} else if (%c(SBCoverSheetPresentationManager)) {
				%init(iOS11plusDisableIdleTimer);
			}

			%init();
		}
	}
}
