# Monetization Setup Guide for Synther

## Overview
The monetization system is now fully implemented with AdMob ads and In-App Purchases. Here's what you need to do to set it up with real credentials.

## 1. Firebase Setup

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project called "Synther"
3. Enable these services:
   - Authentication (Email/Password + Anonymous)
   - Firestore Database
   - Analytics
   - Cloud Storage

### Add Firebase to Your App
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init

# Download config files
# Android: google-services.json → android/app/
# iOS: GoogleService-Info.plist → ios/Runner/
```

## 2. AdMob Setup

### Create AdMob Account
1. Go to [AdMob](https://admob.google.com)
2. Create an app for Android and iOS
3. Create ad units for each platform:
   - Banner Ad
   - Interstitial Ad
   - Rewarded Ad

### Update Ad IDs
Edit `lib/features/ads/ad_manager.dart`:
```dart
static const Map<String, String> _productionAdIds = {
  'android_banner': 'ca-app-pub-XXXXX/XXXXX',
  'android_interstitial': 'ca-app-pub-XXXXX/XXXXX',
  'android_rewarded': 'ca-app-pub-XXXXX/XXXXX',
  'ios_banner': 'ca-app-pub-XXXXX/XXXXX',
  'ios_interstitial': 'ca-app-pub-XXXXX/XXXXX',
  'ios_rewarded': 'ca-app-pub-XXXXX/XXXXX',
};
```

### Configure Mediation (Optional)
- Add Meta Audience Network adapter
- Configure waterfall mediation in AdMob dashboard

## 3. In-App Purchase Setup

### Google Play Console
1. Create app in [Google Play Console](https://play.google.com/console)
2. Navigate to Monetize → Products → Subscriptions
3. Create 6 subscription products:
   - `com.domusgpt.synther.plus_monthly` - $2.99
   - `com.domusgpt.synther.plus_yearly` - $24.99
   - `com.domusgpt.synther.pro_monthly` - $9.99
   - `com.domusgpt.synther.pro_yearly` - $99
   - `com.domusgpt.synther.studio_monthly` - $19.99
   - `com.domusgpt.synther.studio_yearly` - $199

### App Store Connect
1. Create app in [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to Monetization → Subscriptions
3. Create subscription group "Synther Premium"
4. Add same 6 products with matching IDs

### Update Product IDs (if needed)
The product IDs in `lib/features/premium/premium_manager.dart` should match exactly.

## 4. Platform Configuration

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING" />

<!-- Inside <application> tag -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXX~XXXXXXXXXX</string>
<key>SKAdNetworkItems</key>
<array>
  <!-- Add SKAdNetwork identifiers -->
</array>
```

## 5. Testing

### Test Ads
- The app currently uses test ad IDs in debug mode
- Add test devices in AdMob dashboard
- Update test device IDs in `ad_manager.dart`

### Test Purchases
- Use test accounts in Google Play Console
- Use sandbox testers in App Store Connect
- Test all subscription flows:
  - Purchase
  - Restore
  - Cancellation
  - Expiration

## 6. Revenue Optimization

### Ad Placement Strategy
- Banner ads: Bottom of screen, always visible for free users
- Interstitial ads: 
  - After 30 seconds of use
  - When returning from background
  - Max 5 per session
  - 3-minute cooldown
- Rewarded ads: Unlock temporary premium features

### Subscription Pricing
- **Plus ($25/year)**: Basic premium, targets casual users
- **Pro ($99/year)**: Full features, targets serious musicians  
- **Studio ($199/year)**: Commercial license, targets professionals

### Conversion Tactics
- Free tier is functional but limited
- Show upgrade prompts at strategic moments
- Highlight savings on yearly plans (17% off)
- A/B test pricing and features

## 7. Analytics Setup

### Track Key Metrics
- Ad impressions and revenue
- Subscription conversions
- Feature usage by tier
- Session duration
- Retention rates

### Set Up Dashboards
- Firebase Analytics for user behavior
- AdMob for ad performance
- Play Console / App Store Connect for IAP metrics

## 8. Launch Checklist

- [ ] Firebase project configured
- [ ] Real AdMob IDs added
- [ ] IAP products created in stores
- [ ] Privacy policy URL added
- [ ] App store listings complete
- [ ] Beta testing completed
- [ ] Revenue tracking verified
- [ ] Crash reporting enabled

## 9. Post-Launch Optimization

1. **Week 1-2**: Monitor crash rates and fix critical issues
2. **Week 3-4**: Analyze conversion funnel and optimize
3. **Month 2**: A/B test ad frequency and placement
4. **Month 3**: Consider adding more premium features
5. **Ongoing**: Update content, run promotions, engage users

## Target Metrics (Year 1)
- 100,000 Monthly Active Users
- 3-5% Premium Conversion Rate
- $100,000+ Total Revenue
- 4.5+ Star Rating
- <2% Crash Rate

## Support Contacts
- AdMob Support: https://support.google.com/admob
- Play Console: https://support.google.com/googleplay/android-developer
- App Store Connect: https://developer.apple.com/contact/
- Firebase Support: https://firebase.google.com/support