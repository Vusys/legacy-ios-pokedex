# Writing Legacy Apps for iOS 6 on a Jailbroken iPad

A guide to building native iOS 6 applications on jailbroken hardware, without Xcode or a Mac.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Setting Up the iPad](#setting-up-the-ipad)
3. [Setting Up the Host Machine](#setting-up-the-host-machine)
4. [Project Structure](#project-structure)
5. [The Build Pipeline](#the-build-pipeline)
6. [Writing iOS 6 UI Code](#writing-ios-6-ui-code)
7. [Skeuomorphic Design Techniques](#skeuomorphic-design-techniques)
8. [iOS 6 API Reference](#ios-6-api-reference)
9. [Debugging and Troubleshooting](#debugging-and-troubleshooting)
10. [Tips and Gotchas](#tips-and-gotchas)

---

## Introduction

iOS 6 was the last version of iOS designed by Scott Forstall's team — the peak of Apple's skeuomorphic design era. Rich leather textures, green felt, torn paper edges, and wood grain shelves defined the platform's visual identity before Jony Ive's flat redesign in iOS 7.

This guide documents how to build native Objective-C apps for iOS 6, compiled entirely on a jailbroken iPad. No Mac required. No Xcode required. The entire toolchain runs on the device itself, driven from any machine with SSH access.

**What you'll need:**

- An iPad 2 (A5, ARMv7) running iOS 6.1.x, jailbroken
- Any computer with SSH (Linux, Mac, Windows with WSL)
- The iPhoneOS6.1.sdk (available from the Theos SDK archive)

**Why do this:**

- Software preservation — keeping a dying platform alive
- Learning Objective-C and UIKit fundamentals without modern abstractions
- Appreciating skeuomorphic design by building it from scratch
- The challenge and satisfaction of working within tight constraints

---

## Setting Up the iPad

### Jailbreaking

iOS 6.1.x can be jailbroken with **p0sixspwn** (untethered). Download it, connect the iPad via USB, and follow the on-screen instructions. Once complete, the Cydia app will appear on the home screen.

### Cydia Packages

Open Cydia and install the following packages:

| Package | Identifier | Purpose |
|---------|-----------|---------|
| iOS Toolchain (Coolstar) | `org.coolstar.iostoolchain` | LLVM + Clang 3.7.1, ld64, CC tools |
| LLVM + Clang | `org.coolstar.llvm-clang` | The compiler itself |
| ldid | `ldid` | Pseudo-codesigner for jailbroken devices |
| make | `make` | Build tool (optional, for Makefile-based projects) |
| zip | `zip` | IPA packaging |
| coreutils | `coreutils` | GNU sort, head, tail, etc. |
| AppSync | `us.hackulo.appsync50plus` | Allows installing unsigned/self-signed apps |
| ipainstaller | `com.slugrail.ipainstaller` | CLI IPA installer |
| OpenSSH | `openssh` | SSH server (usually pre-installed by jailbreak) |

### Installing the SDK

The iOS 6.1 SDK provides headers and linker stubs. The actual framework binaries live in the iPad's dyld shared cache and are used at runtime — the SDK just tells the compiler what exists.

Transfer the SDK from a Theos installation (or download it from the Theos SDK archive):

```bash
# On the host machine
ssh mobile@<IPAD_IP> "mkdir -p /var/mobile/sdks"
cd ~/theos/sdks
tar cf - iPhoneOS6.1.sdk | ssh mobile@<IPAD_IP> "cd /var/mobile/sdks && tar xf -"
```

The SDK will live at `/var/mobile/sdks/iPhoneOS6.1.sdk` on the device.

### SSH Access

The default credentials after jailbreaking are:

- User: `mobile` / Password: `alpine`
- Root: `root` / Password: `alpine`

**Change these passwords.** Anyone on your network can access your iPad otherwise:

```bash
ssh root@<IPAD_IP>
passwd          # change root password
passwd mobile   # change mobile password
```

Find your iPad's IP address in Settings > Wi-Fi > tap the connected network.

---

## Setting Up the Host Machine

The host machine is where you edit source code and trigger builds. Any OS with SSH works.

### Prerequisites

Install `sshpass` for non-interactive SSH password authentication:

```bash
# Arch Linux
sudo pacman -S sshpass

# Ubuntu/Debian
sudo apt install sshpass

# macOS (via Homebrew)
brew install sshpass
```

### The Scripts Toolchain

Create a `scripts/` directory with five shell scripts that automate the entire workflow.

**`scripts/config.sh`** — Shared environment variables:

```bash
#!/bin/bash
IPAD_HOST="192.168.1.147"
IPAD_USER="mobile"
IPAD_PASS="alpine"
IPAD_PROJECT="/var/mobile/HelloWorld"
IPAD_SDK="/var/mobile/sdks/iPhoneOS6.1.sdk"
APP_NAME="HelloWorld"
BUNDLE_ID="com.test.helloworld"

SSH_CMD="sshpass -p $IPAD_PASS ssh -o StrictHostKeyChecking=no"
SCP_CMD="sshpass -p $IPAD_PASS scp -o StrictHostKeyChecking=no"
SSH="$SSH_CMD ${IPAD_USER}@${IPAD_HOST}"
SSH_ROOT="$SSH_CMD root@${IPAD_HOST}"
```

**`scripts/sync.sh`** — Transfer source to the iPad:

```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "==> Syncing source to iPad..."
$SSH "rm -rf $IPAD_PROJECT/*.m $IPAD_PROJECT/*.plist"
cd "$SCRIPT_DIR/../src"
tar cf - . | $SSH "mkdir -p $IPAD_PROJECT && cd $IPAD_PROJECT && tar xf -"
echo "==> Sync complete."
```

**`scripts/build.sh`** — Compile on the iPad:

```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "==> Building on device..."
$SSH "cd $IPAD_PROJECT && clang -arch armv7 \
  -isysroot $IPAD_SDK \
  -miphoneos-version-min=6.0 \
  -fobjc-arc \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -framework QuartzCore \
  -o $APP_NAME \
  *.m 2>&1"
echo "==> Build complete."
```

**`scripts/install.sh`** — Sign, package, and install:

```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Auto-increment build number
BUILDNUM_FILE="$SCRIPT_DIR/../.buildnum"
if [ -f "$BUILDNUM_FILE" ]; then
    BUILD=$(cat "$BUILDNUM_FILE")
else
    BUILD=1
fi
BUILD=$((BUILD + 1))
echo "$BUILD" > "$BUILDNUM_FILE"
echo "==> Build #${BUILD}"

echo "==> Packaging IPA..."
$SSH "cd $IPAD_PROJECT && \
  ldid -S $APP_NAME && \
  rm -rf Payload ${APP_NAME}.ipa && \
  mkdir -p Payload/${APP_NAME}.app && \
  cp $APP_NAME Payload/${APP_NAME}.app/ && \
  cp Info.plist Payload/${APP_NAME}.app/ && \
  cp icons/*.png Payload/${APP_NAME}.app/ 2>/dev/null; \
  cd $IPAD_PROJECT && \
  zip -qr ${APP_NAME}.ipa Payload/ && \
  rm -rf Payload"

echo "==> Installing..."
$SSH "ipainstaller -f $IPAD_PROJECT/${APP_NAME}.ipa 2>&1 || true"
echo "==> Done. Build #${BUILD} installed."
```

**`scripts/deploy.sh`** — Full cycle:

```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/sync.sh"
"$SCRIPT_DIR/build.sh"
"$SCRIPT_DIR/install.sh"
```

Make them executable:

```bash
chmod +x scripts/*.sh
```

---

## Project Structure

An iOS 6 project is remarkably simple. No `.xcodeproj`, no storyboards, no `Package.swift`. Just Objective-C source files and a property list.

### Minimal Project

```
src/
  main.m           App entry point + AppDelegate
  MyViewController.h/.m   Your view controller
  Info.plist       Bundle metadata
```

### `main.m` — The Entry Point

Every iOS app starts here. `UIApplicationMain` creates the application, instantiates your AppDelegate, and starts the run loop:

```objc
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    MyViewController *vc = [[MyViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:vc];

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
            NSStringFromClass([AppDelegate class]));
    }
}
```

### `Info.plist` — Bundle Metadata

The bare minimum Info.plist for an iPad-only app:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HelloWorld</string>
    <key>CFBundleIdentifier</key>
    <string>com.test.helloworld</string>
    <key>CFBundleName</key>
    <string>HelloWorld</string>
    <key>CFBundleDisplayName</key>
    <string>HelloWorld</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>MinimumOSVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
    <key>UIDeviceFamily</key>
    <array>
        <integer>2</integer>
    </array>
    <key>CFBundleIconFiles</key>
    <array>
        <string>Icon-72</string>
        <string>Icon-72@2x</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
```

Key fields:

| Field | Value | Notes |
|-------|-------|-------|
| `CFBundleExecutable` | Your binary name | Must match the clang `-o` output |
| `MinimumOSVersion` | `6.0` | Required — app won't launch without it |
| `UIDeviceFamily` | `[2]` | 1 = iPhone, 2 = iPad, [1,2] = Universal |
| `CFBundleIconFiles` | Icon filenames | 72x72 for iPad, 144x144 for Retina iPad |

### Header Files

Each view controller gets a `.h` and `.m` pair. The header declares the interface:

```objc
// MyViewController.h
#import <UIKit/UIKit.h>

@interface MyViewController : UIViewController
@end
```

The implementation goes in the `.m` file. The build script compiles all `*.m` files together, so you don't need to list them individually.

---

## The Build Pipeline

### Step 1: Sync Source

The sync script clears old source from the iPad and copies fresh files via tar over SSH:

```bash
./scripts/sync.sh
```

This removes stale `.m` and `.plist` files on the device, then pipes the entire `src/` directory through `tar` to unpack on the iPad at `/var/mobile/HelloWorld/`.

### Step 2: Compile on Device

The build script SSHes into the iPad and runs `clang` directly:

```bash
./scripts/build.sh
```

The compiler invocation:

```bash
clang -arch armv7 \
  -isysroot /var/mobile/sdks/iPhoneOS6.1.sdk \
  -miphoneos-version-min=6.0 \
  -fobjc-arc \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -framework QuartzCore \
  -o HelloWorld \
  *.m
```

**Flag reference:**

| Flag | Purpose |
|------|---------|
| `-arch armv7` | Target the iPad 2's ARMv7 processor |
| `-isysroot <path>` | Point to the SDK for headers and linker stubs |
| `-miphoneos-version-min=6.0` | Deployment target — minimum iOS version |
| `-fobjc-arc` | Enable Automatic Reference Counting |
| `-framework <name>` | Link against a system framework |
| `-o <name>` | Output binary name |
| `*.m` | Compile all Objective-C source files |

Add more frameworks as needed:

```bash
-framework MapKit \
-framework CoreLocation \
```

### Step 3: Sign, Package, Install

```bash
./scripts/install.sh
```

This step does three things:

**Pseudo-codesigning with `ldid`:**

```bash
ldid -S HelloWorld
```

On jailbroken devices with AppSync, `ldid -S` applies a self-signed ad-hoc signature. This is enough to launch the app — no Apple developer certificate needed.

**IPA packaging:**

An IPA file is just a zip archive with a specific structure:

```
HelloWorld.ipa
  └── Payload/
      └── HelloWorld.app/
          ├── HelloWorld        (the binary)
          ├── Info.plist
          ├── Icon-72.png
          └── Icon-72@2x.png
```

```bash
mkdir -p Payload/HelloWorld.app
cp HelloWorld Payload/HelloWorld.app/
cp Info.plist Payload/HelloWorld.app/
cp icons/*.png Payload/HelloWorld.app/
zip -qr HelloWorld.ipa Payload/
```

**Installing:**

```bash
ipainstaller -f HelloWorld.ipa
```

The `-f` flag forces reinstallation even if the same bundle ID exists. The build number must change between installs for the app to update on the home screen.

### Full Cycle

```bash
./scripts/deploy.sh    # sync → build → install
```

After `deploy.sh` completes, the app appears on the iPad's home screen. Tap to launch.

---

## Writing iOS 6 UI Code

### No Auto Layout, No Storyboards

iOS 6 apps can use Auto Layout, but the programmatic constraint API is verbose and painful. Manual frame layout is simpler, more predictable, and what most iOS 6 apps actually used.

Everything is programmatic. No Interface Builder, no storyboards, no XIBs.

### The Basic Pattern

```objc
@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"My Screen";
    self.view.backgroundColor = [UIColor whiteColor];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 280, 40)];
    label.text = @"Hello, iOS 6";
    label.font = [UIFont boldSystemFontOfSize:24];
    label.textColor = [UIColor darkTextColor];
    label.backgroundColor = [UIColor clearColor];
    [self.view addSubview:label];
}

@end
```

### Handling Rotation

Use autoresizing masks to handle orientation changes:

```objc
label.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                         UIViewAutoresizingFlexibleBottomMargin;
```

Common masks:

| Mask | Behavior |
|------|----------|
| `UIViewAutoresizingFlexibleWidth` | Stretches horizontally |
| `UIViewAutoresizingFlexibleHeight` | Stretches vertically |
| `UIViewAutoresizingFlexibleLeftMargin` | Floats to the right |
| `UIViewAutoresizingFlexibleRightMargin` | Floats to the left |
| `UIViewAutoresizingFlexibleTopMargin` | Floats to the bottom |
| `UIViewAutoresizingFlexibleBottomMargin` | Floats to the top |

### The `lastBuiltWidth` Pattern

For complex layouts that need complete rebuilding on rotation, use a width guard to avoid redundant work:

```objc
@interface MyViewController ()
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastBuiltWidth = 0;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    if (w > 0 && w != self.lastBuiltWidth) {
        self.lastBuiltWidth = w;
        [self rebuildLayout];
    }
}

- (void)rebuildLayout {
    // Remove old subviews, build new layout based on current width
    for (UIView *sub in [self.view.subviews copy]) [sub removeFromSupview];
    CGFloat width = self.view.bounds.size.width;
    // ... lay out views using width ...
}

@end
```

`viewDidLayoutSubviews` is called on every rotation, but the guard ensures you only rebuild when the width actually changes.

### UISplitViewController (iPad)

The iPad's signature UI element. A master-detail split view with a sidebar:

```objc
// In AppDelegate
UISplitViewController *split = [[UISplitViewController alloc] init];
split.viewControllers = @[masterNav, detailNav];
split.delegate = self;
self.window.rootViewController = split;

// Always show sidebar (iOS 6 delegate method)
- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}
```

To swap the detail view when a row is tapped:

```objc
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *vc = [[MyDetailVC alloc] init];
    UINavigationController *detailNav = [[UINavigationController alloc]
        initWithRootViewController:vc];
    self.splitVC.viewControllers = @[self.splitVC.viewControllers[0], detailNav];
}
```

### UITableView

The workhorse of iOS UI. Every list, menu, and settings screen is a table view:

```objc
@interface MyListVC : UITableViewController
@end

@implementation MyListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"My List";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"Cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"Row %d", indexPath.row];
    cell.detailTextLabel.text = @"Subtitle text";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

@end
```

iOS 6 has four cell styles: `Default`, `Value1`, `Value2`, and `Subtitle`.

---

## Skeuomorphic Design Techniques

The heart of iOS 6's visual identity. These techniques recreate real-world textures and materials entirely in code.

### Generating Textures with `drawRect:`

Subclass `UIView` and override `drawRect:` to paint custom textures. Here's a green felt texture (like Game Center):

```objc
@interface FeltView : UIView
@end

@implementation FeltView

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Base green fill
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithRed:0.2 green:0.55 blue:0.2 alpha:1].CGColor);
    CGContextFillRect(ctx, rect);

    // Deterministic seed so dots don't change on redraw
    NSUInteger state = (NSUInteger)(rect.size.width * 1000 + rect.size.height);

    // 4000 tiny dots simulate felt fiber
    for (int i = 0; i < 4000; i++) {
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;  // LCG PRNG
        CGFloat x = (state % (NSUInteger)rect.size.width);
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat y = (state % (NSUInteger)rect.size.height);
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat green = 0.45 + (CGFloat)(state % 20) / 100.0;
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat size = 1.0 + (CGFloat)(state % 2);

        CGContextSetFillColorWithColor(ctx,
            [UIColor colorWithRed:0.18 green:green blue:0.18 alpha:0.3].CGColor);
        CGContextFillEllipseInRect(ctx, CGRectMake(x, y, size, size));
    }
}

@end
```

**Key insight:** Use a deterministic PRNG (linear congruential generator) seeded from the view dimensions. This ensures the texture looks the same on every redraw, unlike `arc4random` which would produce a different pattern each time `drawRect:` is called.

### Linen Texture (Calendar App)

A crosshatch pattern of tiny strokes:

```objc
// Draw ~6000 random short strokes (horizontal + vertical)
for (int i = 0; i < 6000; i++) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    CGFloat x = (state % (NSUInteger)rect.size.width);
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    CGFloat y = (state % (NSUInteger)rect.size.height);
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    BOOL horiz = (state % 2 == 0);
    CGFloat len = 2.0 + (state % 3);

    CGContextSetStrokeColorWithColor(ctx,
        [UIColor colorWithWhite:0.65 alpha:0.12].CGColor);
    CGContextSetLineWidth(ctx, 0.5);

    if (horiz) {
        CGContextMoveToPoint(ctx, x, y);
        CGContextAddLineToPoint(ctx, x + len, y);
    } else {
        CGContextMoveToPoint(ctx, x, y);
        CGContextAddLineToPoint(ctx, x, y + len);
    }
    CGContextStrokePath(ctx);
}
```

### Torn Paper Edge (Notes App)

A jagged path along the bottom of a view, simulating torn paper:

```objc
- (void)drawRect:(CGRect)rect {
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(W, 0)];
    [path addLineToPoint:CGPointMake(W, H - 4)];

    // Jagged torn edge
    CGFloat x = W;
    while (x > 0) {
        CGFloat step = 4 + (arc4random_uniform(6));   // 4-9px wide teeth
        CGFloat depth = 3 + (arc4random_uniform(6));   // 3-8px deep
        x -= step;
        if (x < 0) x = 0;
        [path addLineToPoint:CGPointMake(x, H - depth)];
        x -= step;
        if (x < 0) x = 0;
        [path addLineToPoint:CGPointMake(x, H - 1)];
    }

    [path closePath];
    [[UIColor colorWithRed:1.0 green:0.95 blue:0.7 alpha:1.0] setFill];
    [path fill];
}
```

### Custom Navigation Bar Backgrounds

Generate a 1px-wide gradient image and set it as the nav bar background:

```objc
// Purple gradient (Game Center style)
CGSize navSize = CGSizeMake(1, 44);
UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
CGContextRef ctx = UIGraphicsGetCurrentContext();

CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
CGFloat colors[] = {
    0.28, 0.15, 0.45, 1.0,  // dark purple top
    0.35, 0.20, 0.55, 1.0   // lighter purple bottom
};
CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
CGContextDrawLinearGradient(ctx, gradient,
    CGPointMake(0, 0), CGPointMake(0, navSize.height), 0);
CGGradientRelease(gradient);
CGColorSpaceRelease(colorSpace);

UIImage *navImage = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();

[self.navigationController.navigationBar setBackgroundImage:navImage
    forBarMetrics:UIBarMetricsDefault];
```

Customize the title text to match:

```objc
self.navigationController.navigationBar.titleTextAttributes = @{
    UITextAttributeTextColor: [UIColor whiteColor],
    UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
    UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
    UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
};
```

**Important:** Reset the nav bar in `viewWillDisappear:` so it doesn't bleed into other screens:

```objc
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:nil
        forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = nil;
}
```

### Tiled Pattern Backgrounds

Use `colorWithPatternImage:` for repeating textures like wood grain:

```objc
UIImage *wood = [UIImage imageNamed:@"wood_texture.png"];
self.view.backgroundColor = [UIColor colorWithPatternImage:wood];
```

The image tiles automatically to fill the view.

### CALayer Effects

`#import <QuartzCore/QuartzCore.h>` to access layer properties:

```objc
// Drop shadow
view.layer.shadowColor = [[UIColor blackColor] CGColor];
view.layer.shadowOffset = CGSizeMake(2, 3);
view.layer.shadowOpacity = 0.5;
view.layer.shadowRadius = 3;

// Rounded corners
view.layer.cornerRadius = 6;

// Border
view.layer.borderWidth = 0.5;
view.layer.borderColor = [[UIColor grayColor] CGColor];
```

Gradient overlays using `CAGradientLayer`:

```objc
CAGradientLayer *shadow = [CAGradientLayer layer];
shadow.frame = CGRectMake(0, 0, width, 8);
shadow.colors = @[
    (id)[UIColor colorWithWhite:0 alpha:0.35].CGColor,
    (id)[UIColor clearColor].CGColor
];
[someView.layer addSublayer:shadow];
```

### Ruled Lines (Notes App)

Draw horizontal rules at a fixed interval:

```objc
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat lineSpacing = 28.0;

    CGContextSetStrokeColorWithColor(ctx,
        [UIColor colorWithRed:0.6 green:0.75 blue:0.9 alpha:0.4].CGColor);
    CGContextSetLineWidth(ctx, 0.5);

    for (CGFloat y = lineSpacing; y < self.bounds.size.height; y += lineSpacing) {
        CGContextMoveToPoint(ctx, 0, y);
        CGContextAddLineToPoint(ctx, self.bounds.size.width, y);
    }
    CGContextStrokePath(ctx);

    // Red margin line
    CGContextSetStrokeColorWithColor(ctx,
        [UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:0.3].CGColor);
    CGContextMoveToPoint(ctx, 60, 0);
    CGContextAddLineToPoint(ctx, 60, self.bounds.size.height);
    CGContextStrokePath(ctx);
}
```

---

## iOS 6 API Reference

These APIs were the standard way to do things in iOS 6. Most were deprecated or removed in iOS 7-9.

### Alerts and Action Sheets

iOS 6 uses `UIAlertView` and `UIActionSheet`, not `UIAlertController` (which arrived in iOS 8):

```objc
// Simple alert
UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Title"
    message:@"Message" delegate:self cancelButtonTitle:@"OK"
    otherButtonTitles:@"Action", nil];
[alert show];

// Alert with text field
UIAlertView *login = [[UIAlertView alloc] initWithTitle:@"Login"
    message:@"Enter password" delegate:self cancelButtonTitle:@"Cancel"
    otherButtonTitles:@"OK", nil];
login.alertViewStyle = UIAlertViewStyleSecureTextInput;
[login show];

// Action sheet
UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Options"
    delegate:self cancelButtonTitle:@"Cancel"
    destructiveButtonTitle:@"Delete"
    otherButtonTitles:@"Copy", @"Share", nil];
[sheet showInView:self.view];
```

Alert view styles: `UIAlertViewStyleDefault`, `UIAlertViewStyleSecureTextInput`, `UIAlertViewStylePlainTextInput`, `UIAlertViewStyleLoginAndPasswordInput`.

### Popovers (iPad Only)

`UIPopoverController` is an iPad-exclusive API, removed in iOS 9:

```objc
UIViewController *content = [[UIViewController alloc] init];
content.contentSizeForViewInPopover = CGSizeMake(300, 200);

UIPopoverController *popover = [[UIPopoverController alloc]
    initWithContentViewController:content];

// From a bar button item
[popover presentPopoverFromBarButtonItem:sender
    permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

// From a rect
[popover presentPopoverFromRect:button.frame inView:self.view
    permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
```

### UIWebView

The original web view, replaced by `WKWebView` in iOS 8:

```objc
UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
webView.delegate = self;
[webView loadRequest:[NSURLRequest requestWithURL:
    [NSURL URLWithString:@"https://example.com"]]];
[self.view addSubview:webView];

// JavaScript evaluation
NSString *title = [webView stringByEvaluatingJavaScriptFromString:
    @"document.title"];
```

### UISearchDisplayController

The iOS 6 search controller, replaced by `UISearchController` in iOS 8:

```objc
UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:
    CGRectMake(0, 0, 320, 44)];
self.tableView.tableHeaderView = searchBar;

UISearchDisplayController *searchDC = [[UISearchDisplayController alloc]
    initWithSearchBar:searchBar contentsController:self];
searchDC.delegate = self;
searchDC.searchResultsDataSource = self;
searchDC.searchResultsDelegate = self;
```

### Map Overlays

iOS 6 uses `MKOverlayView` and the `viewForOverlay:` delegate, not the `rendererForOverlay:` method from iOS 7+:

```objc
// Add a circle overlay
MKCircle *circle = [MKCircle circleWithCenterCoordinate:coord radius:500];
[mapView addOverlay:circle];

// Delegate method
- (MKOverlayView *)mapView:(MKMapView *)mapView
            viewForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleView *circleView = [[MKCircleView alloc]
            initWithCircle:(MKCircle *)overlay];
        circleView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
        circleView.strokeColor = [UIColor blueColor];
        circleView.lineWidth = 2;
        return circleView;
    }
    return nil;
}
```

### String Drawing

iOS 6 uses direct `NSString` category methods for drawing text into graphics contexts:

```objc
[@"Hello" drawInRect:CGRectMake(10, 10, 200, 30)
             withFont:[UIFont boldSystemFontOfSize:16]
        lineBreakMode:NSLineBreakByTruncatingTail
            alignment:NSTextAlignmentLeft];
```

These were deprecated in iOS 7 in favor of `NSAttributedString` and `drawInRect:withAttributes:`.

### Navigation Bar Title Attributes

iOS 6 uses string-keyed dictionaries, not the typed `NSAttributedString` keys:

```objc
// iOS 6 style
navBar.titleTextAttributes = @{
    UITextAttributeTextColor: [UIColor whiteColor],
    UITextAttributeTextShadowColor: [UIColor blackColor],
    UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
    UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
};
```

---

## Debugging and Troubleshooting

### Build Errors

**"framework not found"** — Add the missing `-framework` flag to `build.sh`:

```bash
-framework MapKit \
-framework CoreLocation \
```

Common framework pairs: `MapKit` requires `CoreLocation`. `QuartzCore` is needed for any `CALayer` usage.

**"file not found"** for headers — Check that the SDK path in `config.sh` is correct and the SDK actually exists at `/var/mobile/sdks/iPhoneOS6.1.sdk`. Verify with:

```bash
ssh mobile@<IPAD_IP> "ls /var/mobile/sdks/iPhoneOS6.1.sdk/usr/include/UIKit/"
```

**"unknown type name"** — You probably forgot to `#import` a header. Every `.m` file that uses UIKit classes needs `#import <UIKit/UIKit.h>`. For layer operations: `#import <QuartzCore/QuartzCore.h>`.

### App Won't Launch

**Crashes immediately:** Check that `MinimumOSVersion` is set to `6.0` in Info.plist. Without it, the system may refuse to run the app.

**"code signature invalid":** Make sure AppSync is installed and `ldid -S` ran successfully. Try:

```bash
ssh mobile@<IPAD_IP> "ldid -S /var/mobile/HelloWorld/HelloWorld"
```

**Black screen:** Your `CFBundleExecutable` in Info.plist doesn't match the binary name, or you forgot to set the window's `rootViewController`.

### SSH Issues

**Connection refused:** Make sure OpenSSH is installed on the iPad via Cydia.

**Connection timeout:** The iPad might have a different IP. Check Settings > Wi-Fi on the iPad, or try:

```bash
ping 192.168.1.147
```

**Password denied:** The default is `alpine`. If you changed it, update `config.sh`.

### App Not Updating

`ipainstaller` sometimes ignores installs if the build number hasn't changed. The auto-incrementing `.buildnum` file handles this, but if you're packaging manually, make sure to change `CFBundleVersion` in Info.plist between installs.

---

## Tips and Gotchas

1. **Always use `-fobjc-arc`.** Clang 3.7.1 fully supports ARC. Manual retain/release is unnecessary pain.

2. **Everything is programmatic.** No storyboards, no XIBs, no Interface Builder. Every view, every constraint, every layout — all in code. This is actually liberating: what you see in the source is what runs.

3. **iPad-only apps need `UIDeviceFamily: [2]`.** Without this, the system treats your app as an iPhone app running in 2x mode.

4. **The SDK is just stubs.** Framework binaries live in the device's dyld shared cache. The SDK provides headers for compilation and linker stubs for symbol resolution. At runtime, the real frameworks are loaded from the cache.

5. **`QuartzCore` is not automatically linked.** Any use of `CALayer` properties (shadow, cornerRadius, etc.) requires `-framework QuartzCore` in the build command and `#import <QuartzCore/QuartzCore.h>` in the source.

6. **Build numbers must change.** `ipainstaller` won't update an app if the `CFBundleVersion` is the same. Use the auto-incrementing `.buildnum` pattern.

7. **Icons are simple PNGs.** No asset catalogs. Just put PNG files in the app bundle and list them in `CFBundleIconFiles`. For iPad: `Icon-72.png` (72x72) and `Icon-72@2x.png` (144x144).

8. **`drawRect:` performance.** Generating 4000+ random dots is fine on an iPad 2 — Core Graphics is hardware-accelerated. But cache the result if the view doesn't change. Set `self.contentMode = UIViewContentModeRedraw` if you want `drawRect:` called on every resize.

9. **Test all four orientations.** iPad apps are expected to support portrait, landscape, and both upside-down variants. The `UISupportedInterfaceOrientations~ipad` key in Info.plist controls this.

10. **No app thinning, no bitcode.** The binary you compile is the binary that runs. What you see in the IPA is what's on disk. Simple.

11. **The `~ipad` suffix matters.** Some iOS resources and plist keys use the `~ipad` suffix for iPad-specific variants (e.g., `UISupportedInterfaceOrientations~ipad`, image filenames like `background~ipad.png`).

12. **Clean rebuilds are easy.** Since `clang *.m` compiles everything from scratch each time, there's no incremental compilation state to corrupt. Every build is clean.
