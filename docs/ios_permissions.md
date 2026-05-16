# iOS Permission Strings Required

Add these to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>FreshBasket needs your location to find nearby sellers and auto-fill your delivery address.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>FreshBasket drivers need location access to navigate to delivery addresses.</string>

<key>NSCameraUsageDescription</key>
<string>FreshBasket needs camera access to let sellers photograph their products.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>FreshBasket needs photo library access to let sellers upload product images.</string>
```
