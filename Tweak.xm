#include <dlfcn.h>

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
-(void)resignKeyAndDismissViewControllerAnimated:(BOOL)arg1 completion:(id)arg2; // Pre-FLEX 4
@end

@interface FLEXManager : NSObject
@property (nonatomic) FLEXExplorerViewController *explorerViewController;
+(FLEXManager *)sharedManager;
// -(void)showExplorer;
@end

@interface FLEXWindow : UIWindow
@end

typedef NS_ENUM(NSUInteger, FLEXObjectExplorerSection) { // Pre-FLEX 4
    FLEXObjectExplorerSectionDescription,
    FLEXObjectExplorerSectionCustom,
    FLEXObjectExplorerSectionProperties,
    FLEXObjectExplorerSectionIvars,
    FLEXObjectExplorerSectionMethods,
    FLEXObjectExplorerSectionClassMethods,
    FLEXObjectExplorerSectionSuperclasses,
    FLEXObjectExplorerSectionReferencingInstances
};

@interface FLEXTableViewSection : NSObject // FLEX 4+
@property (nonatomic, readonly, nullable) NSString *title;
@end

@interface FLEXSingleRowSection : FLEXTableViewSection // FLEX 4+
@end

@interface FLEXObjectExplorerViewController : UITableViewController
@property (nonatomic, readonly) FLEXTableViewSection *customSection; // FLEX 4+
@end

@interface NSObject (PrivateFLEXall)
-(id)safeValueForKey:(id)arg1;
@end

@interface UIWindow (PrivateFLEXall)
@property (nonatomic, strong) UILongPressGestureRecognizer *flexAllLongPress;
@end

@interface FLEXallGestureManager : NSObject
@property (nonatomic, assign) void *flexHandle;
+(instancetype)sharedManager;
-(void)show;
@end

// libflex symbols
static id (*GetFLXManager)();
static SEL (*GetFLXRevealSEL)();
static Class (*GetFLXWindowClass)();

#define kFLEXallWindowLevel 2050
#define kFLEXallLongPressType 1337
#define kFLEXallBlacklistPath @"/var/mobile/Library/Preferences/com.dgh0st.flexall.blacklist.plist"
#define kFLEXallObjectGraphSectionTitle @"Object Graph"
#define kFLEXallDisableIdleTimerReason @"FLEXallDisableIdle"

static UILongPressGestureRecognizer *RegisterLongPressGesture(UIWindow *window, NSUInteger fingers) {
	UILongPressGestureRecognizer *longPress = nil;
	Class flexWindowClass = GetFLXWindowClass();
	if (flexWindowClass == nil || ![window isKindOfClass:flexWindowClass]) {
		longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:[FLEXallGestureManager sharedManager] action:@selector(show)];
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
		[[FLEXallGestureManager sharedManager] show];
	} else {
		%orig(arg1);
	}
}
%end
%end

%group commonFLEXHooks
%hook UIViewController
-(BOOL)_canShowWhileLocked {
	UIViewController *currentViewController = self;
	while (currentViewController != nil) {
		if ([currentViewController isKindOfClass:%c(FLEXExplorerViewController)] || [currentViewController isKindOfClass:%c(FLEXNavigationController)]) {
			return YES;
		}

		if (currentViewController.presentingViewController != nil) {
			currentViewController = currentViewController.presentingViewController;
		} else {
			currentViewController = currentViewController.parentViewController;
		}
	}

	return %orig();
}
%end

%hook FLEXWindow
-(BOOL)_shouldCreateContextAsSecure {
	return YES;
}

-(id)initWithFrame:(CGRect)arg1 {
	self = %orig(arg1);
	if (self != nil) {
		[self setWindowLevel:kFLEXallWindowLevel]; // above springboard alert window but below flash window (and callout bar stuff)
	}
	return self;
}
%end

%hook FLEXObjectExplorerViewController
-(void)viewDidLoad {
	%orig();

	FLEXManager *manager = GetFLXManager();
	if (self.navigationItem.rightBarButtonItems.count == 0 && [manager.explorerViewController respondsToSelector:@selector(resignKeyAndDismissViewControllerAnimated:completion:)]) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDonePressed:)];
	}
}

-(NSArray<NSNumber *> *)possibleExplorerSections { // Pre-FLEX 4
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

-(NSArray<FLEXTableViewSection *> *)makeSections { // FLEX 4+
	NSArray<FLEXTableViewSection *> *sections = %orig();

	// FLEX should never add another one of thse but this should work even if it does
	NSArray<FLEXTableViewSection *> *singleRowSections = [sections filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(FLEXTableViewSection *evaluatedObject, NSDictionary<NSString *,id> *bindings) {
		if ([evaluatedObject isKindOfClass:%c(FLEXSingleRowSection)] && [evaluatedObject.title isEqualToString:kFLEXallObjectGraphSectionTitle]) {
			return YES;
		}
		return NO;
	}]];

	NSUInteger customSectionIndex = [sections indexOfObject:self.customSection];
	if (customSectionIndex != NSNotFound && singleRowSections.count > 0) {
		NSMutableArray<FLEXTableViewSection *> *newSections = [sections mutableCopy];
		[newSections removeObjectsInArray:singleRowSections];
		[newSections insertObjects:singleRowSections atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(customSectionIndex + 1, singleRowSections.count)]];
		sections = [newSections copy];
	}

	return sections;
}

%new
-(void)handleDonePressed:(id)arg1 {
	FLEXManager *manager = GetFLXManager();
	if ([manager.explorerViewController respondsToSelector:@selector(resignKeyAndDismissViewControllerAnimated:completion:)]) { // Pre-FLEX 4
		[manager.explorerViewController resignKeyAndDismissViewControllerAnimated:YES completion:nil];
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

	[GetDashBoardIdleTimerProvider() addDisabledIdleTimerAssertionReason:kFLEXallDisableIdleTimerReason];
}

-(void)hideExplorer {
	%orig();

	[GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:kFLEXallDisableIdleTimerReason];
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

static id FallbackFLXGetManager() {
	return [%c(FLEXManager) sharedManager];
}

static SEL FallbackFLXRevealSEL() {
	return @selector(showExplorer);
}

static Class FallbackFLXWindowClass() {
	return %c(FLEXWindow);
}

@implementation FLEXallGestureManager
+(instancetype)sharedManager {
	static FLEXallGestureManager *_sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedManager = [[self alloc] init];
	});
	return _sharedManager;
}

-(instancetype)init {
	self = [super init];
	self.flexHandle = NULL;
	return self;
}

-(void)_loadFLEXIfNeeded {
	@synchronized(self) {
		if (self.flexHandle == NULL) {
			self.flexHandle = dlopen("/Library/MobileSubstrate/DynamicLibraries/libFLEX.dylib", RTLD_LAZY);
			if (self.flexHandle != NULL) {
				GetFLXManager = (id(*)())dlsym(self.flexHandle, "FLXGetManager") ?: &FallbackFLXGetManager;
				GetFLXRevealSEL = (SEL(*)())dlsym(self.flexHandle, "FLXRevealSEL") ?: &FallbackFLXRevealSEL;
				GetFLXWindowClass = (Class(*)())dlsym(self.flexHandle, "FLXWindowClass") ?: &FallbackFLXWindowClass;

				if (%c(SBBacklightController) && [%c(SBBacklightController) instancesRespondToSelector:@selector(resetLockScreenIdleTimer)]) {
					%init(preiOS11ResetIdleTimer, FLEXWindow=GetFLXWindowClass());
				} else if (%c(SBCoverSheetPresentationManager)) {
					%init(iOS11plusDisableIdleTimer, FLEXManager=[GetFLXManager() class]);
				}

				%init(commonFLEXHooks, FLEXWindow=GetFLXWindowClass());
			} else {
				// TODO: potentially add alert with dlerror
			}
		}
	}
}

-(void)show {
	[self _loadFLEXIfNeeded];

	FLEXManager *manager = GetFLXManager();
	SEL showSelector = GetFLXRevealSEL();
	if (manager != nil && showSelector != NULL)
		[manager performSelector:showSelector];
}

-(void)dealloc {
	if (self.flexHandle != NULL)
		dlclose(self.flexHandle);
	self.flexHandle = NULL;
}
@end

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
		if (!isBlacklisted) {
			if ((isSpringBoard || isApplication)) {
				GetFLXManager = &FallbackFLXGetManager;
				GetFLXRevealSEL = &FallbackFLXRevealSEL;
				GetFLXWindowClass = &FallbackFLXWindowClass;

				if (%c(UIStatusBarManager)) {
					%init(iOS13plusStatusBar);
				}

				%init();
			}
		}
	}
}
