#import <dlfcn.h>
#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>

#define NSLog1(...)

static BOOL isLaunched;

//extern "C" id SBSUIWallpaperGetCurrentHomeScreenImage();

@interface SBDisplayItem : NSObject
+(id)homeScreenDisplayItem;
@end

@interface SBAppLayout : NSObject
@property (assign,nonatomic) long long configuration; 
@property (nonatomic,copy) NSDictionary * rolesToLayoutItemsMap;
+ (id)homeScreenAppLayout;
@end

@interface SBIconController : UIViewController
+(id)sharedInstance;
@end

@interface SBFluidSwitcherItemContainer : UIView
@property (nonatomic,copy) UIView * contentView;
@end

@interface SBMainSwitcherViewController : UIViewController
+(id)sharedInstance;
-(void)_removeCardForDisplayIdentifier:(id)arg1 ;
-(void)_removeAppLayout:(id)arg1 forReason:(long long)arg2 modelMutationBlock:(/*^block*/id)arg3 completion:(/*^block*/id)arg4 ;
-(NSArray*)appLayouts;
-(void)_quitAppsRepresentedByAppLayout:(id)arg1 forReason:(long long)arg2 ;
-(BOOL)dismissSwitcherNoninteractively;
@end

static UIImage * imageWithView(NSArray* views, CGSize size)
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
	for(UIView* vNow in views) {
		[vNow.layer renderInContext:UIGraphicsGetCurrentContext()];
	}
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

UIImageView* snapshotHS = [[UIImageView alloc] init];

%hook SBFluidSwitcherViewController
- (SBFluidSwitcherItemContainer*)_itemContainerForAppLayoutIfExists:(id)arg1
{
	SBFluidSwitcherItemContainer* ret = %orig;
	@try {
		if(isLaunched && arg1 == [%c(SBAppLayout) homeScreenAppLayout] && ret) {
			[snapshotHS removeFromSuperview];
			snapshotHS.frame = ret.bounds;
			[[ret contentView] addSubview:snapshotHS];
			[ret contentView].layer.masksToBounds = YES;
		}
	} @catch(NSException* ex) {
	}
	return ret;
}
%end

%hook SBAppLayout
+ (id)homeScreenAppLayout
{
	SBAppLayout* ret = %orig;
	@try {
		static SBDisplayItem* HS = [%c(SBDisplayItem) homeScreenDisplayItem];
		ret.configuration = 1;
		ret.rolesToLayoutItemsMap = @{@"0":HS,};
		MSHookIvar<long long>(ret, "_cachedAppLayoutType") = 0;
	} @catch(NSException* ex) {
	}
	return ret;
}
%end

%hook SBMainSwitcherViewController
-(void)_removeAppLayout:(id)arg1 forReason:(long long)arg2 modelMutationBlock:(/*^block*/id)arg3 completion:(/*^block*/id)arg4 
{
	%orig;
	@try {
		if(arg1 == [%c(SBAppLayout) homeScreenAppLayout]) {
			for(id appLayoutNow in [self appLayouts]) {
				if(appLayoutNow!=[%c(SBAppLayout) homeScreenAppLayout]) {
					[self _quitAppsRepresentedByAppLayout:appLayoutNow forReason:1];
				}
			}
			[self dismissSwitcherNoninteractively];
		}
	} @catch(NSException* ex) {
	}
}
-(void)viewWillAppear:(BOOL)arg1
{
	%orig;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
		@try {
			UIWindow* wallpaperWin = nil;
			for(UIWindow* winNow in [[UIApplication sharedApplication] windows]) {
				if([winNow isKindOfClass:%c(_SBWallpaperWindow)]) {
					wallpaperWin = winNow;
				}
			}
			[[%c(SBIconController) sharedInstance] view].alpha = 1.0f;
			snapshotHS.image = imageWithView(@[wallpaperWin, [[%c(SBIconController) sharedInstance] view]], [[%c(SBIconController) sharedInstance] view].bounds.size);
			/*if(isLaunched) {
				id(*CurrentHomeScreenImage)() = (id(*)())dlsym(RTLD_DEFAULT, "SBSUIWallpaperGetCurrentHomeScreenImage");
				if(dlsym(RTLD_DEFAULT, "SBSUIWallpaperGetCurrentHomeScreenImage")!= NULL) {
					NSLog(@"CurrentHomeScreenImage: %p", &CurrentHomeScreenImage);
					snapshotHS.image = CurrentHomeScreenImage();
					//snapshotHS.image = SBSUIWallpaperGetCurrentHomeScreenImage();
				}
			}*/
		} @catch(NSException* ex) {
		}
	});
}
- (id)appLayouts
{
	NSArray* ret = %orig;
	@try {
		BOOL hasHS = NO;
		for(SBAppLayout* appLnow in ret) {
			if(appLnow == [%c(SBAppLayout) homeScreenAppLayout]) {
				hasHS = YES;
				break;
			}
		}
		if(!hasHS) {
			[(NSMutableArray*)ret insertObject:[%c(SBAppLayout) homeScreenAppLayout] atIndex:0];
		}
	} @catch(NSException* ex) {
	}
	return ret;
}
%end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application
{
	%orig;
	isLaunched = YES;
}
%end