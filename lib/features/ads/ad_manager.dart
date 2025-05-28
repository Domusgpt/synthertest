import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/firebase_manager.dart';

/// Manages all advertising functionality with smart placement and frequency capping
class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // Test Ad IDs - Replace with your real IDs when ready
  static const Map<String, String> _testAdIds = {
    'android_banner': 'ca-app-pub-3940256099942544/6300978111',
    'android_interstitial': 'ca-app-pub-3940256099942544/1033173712',
    'android_rewarded': 'ca-app-pub-3940256099942544/5224354917',
    'ios_banner': 'ca-app-pub-3940256099942544/2934735716',
    'ios_interstitial': 'ca-app-pub-3940256099942544/4411468910',
    'ios_rewarded': 'ca-app-pub-3940256099942544/1712485313',
  };

  // Production Ad IDs - ADD YOUR REAL IDS HERE
  static const Map<String, String> _productionAdIds = {
    'android_banner': 'YOUR_ANDROID_BANNER_ID',
    'android_interstitial': 'YOUR_ANDROID_INTERSTITIAL_ID',
    'android_rewarded': 'YOUR_ANDROID_REWARDED_ID',
    'ios_banner': 'YOUR_IOS_BANNER_ID',
    'ios_interstitial': 'YOUR_IOS_INTERSTITIAL_ID',
    'ios_rewarded': 'YOUR_IOS_REWARDED_ID',
  };

  // Ad state management
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isInitialized = false;
  bool _consentObtained = false;
  bool _bannerLoaded = false;
  bool _interstitialLoaded = false;
  bool _rewardedLoaded = false;

  // Frequency capping
  DateTime? _lastInterstitialShow;
  int _sessionAdCount = 0;
  static const int _maxAdsPerSession = 5;
  static const Duration _interstitialCooldown = Duration(minutes: 3);

  // Callbacks
  Function()? _onRewardEarned;
  Function()? _onAdDismissed;

  // Use test ads in debug mode
  bool get _useTestAds => kDebugMode || _productionAdIds['android_banner'] == 'YOUR_ANDROID_BANNER_ID';

  String _getAdId(String key) {
    final ids = _useTestAds ? _testAdIds : _productionAdIds;
    final platform = Platform.isAndroid ? 'android' : 'ios';
    return ids['${platform}_$key'] ?? '';
  }

  /// Initialize the ad system
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      // Configure settings
      final configuration = RequestConfiguration(
        testDeviceIds: kDebugMode ? ['YOUR_TEST_DEVICE_ID'] : [],
        maxAdContentRating: MaxAdContentRating.g,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      );
      await MobileAds.instance.updateRequestConfiguration(configuration);

      _isInitialized = true;
      print('AdManager: Initialized successfully');

      // Check consent status (implement your consent flow)
      _consentObtained = true; // TODO: Implement proper consent

      // Preload ads if user is not premium
      final isPremium = await FirebaseManager().checkIfPremiumUser();
      if (!isPremium && _consentObtained) {
        await _preloadAds();
      }
    } catch (e) {
      print('AdManager: Initialization failed: $e');
    }
  }

  /// Preload all ad types for better performance
  Future<void> _preloadAds() async {
    await Future.wait([
      _loadBannerAd(),
      _loadInterstitialAd(),
      _loadRewardedAd(),
    ]);
  }

  /// Load banner ad
  Future<void> _loadBannerAd() async {
    if (_bannerLoaded || !_isInitialized) return;

    _bannerAd = BannerAd(
      adUnitId: _getAdId('banner'),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerLoaded = true;
          print('AdManager: Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('AdManager: Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _bannerLoaded = false;
        },
        onAdOpened: (ad) => _trackAdEvent('banner_opened'),
        onAdClosed: (ad) => _trackAdEvent('banner_closed'),
      ),
    );

    await _bannerAd!.load();
  }

  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (_interstitialLoaded || !_isInitialized) return;

    await InterstitialAd.load(
      adUnitId: _getAdId('interstitial'),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoaded = true;
          print('AdManager: Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('AdManager: Interstitial ad failed to load: $error');
          _interstitialLoaded = false;
        },
      ),
    );
  }

  /// Load rewarded ad
  Future<void> _loadRewardedAd() async {
    if (_rewardedLoaded || !_isInitialized) return;

    await RewardedAd.load(
      adUnitId: _getAdId('rewarded'),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoaded = true;
          print('AdManager: Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('AdManager: Rewarded ad failed to load: $error');
          _rewardedLoaded = false;
        },
      ),
    );
  }

  /// Get banner ad widget (returns null for premium users)
  BannerAd? getBannerAd() {
    if (!_isInitialized || !_consentObtained || !_bannerLoaded) return null;
    return _bannerAd;
  }

  /// Show interstitial ad with frequency capping
  Future<bool> showInterstitialAd({Function()? onDismissed}) async {
    if (!_isInitialized || !_consentObtained || !_interstitialLoaded) return false;

    // Check if user is premium
    final isPremium = await FirebaseManager().checkIfPremiumUser();
    if (isPremium) return false;

    // Frequency capping
    if (_sessionAdCount >= _maxAdsPerSession) {
      print('AdManager: Session ad limit reached');
      return false;
    }

    if (_lastInterstitialShow != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialShow!);
      if (timeSinceLastAd < _interstitialCooldown) {
        print('AdManager: Interstitial cooldown active');
        return false;
      }
    }

    // Show the ad
    if (_interstitialAd != null) {
      _onAdDismissed = onDismissed;
      
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _interstitialLoaded = false;
          _onAdDismissed?.call();
          _loadInterstitialAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('AdManager: Failed to show interstitial: $error');
          ad.dispose();
          _interstitialAd = null;
          _interstitialLoaded = false;
        },
      );

      await _interstitialAd!.show();
      _lastInterstitialShow = DateTime.now();
      _sessionAdCount++;
      _trackAdEvent('interstitial_shown');
      return true;
    }
    
    return false;
  }

  /// Show rewarded ad for temporary premium features
  Future<bool> showRewardedAd({
    required Function() onRewarded,
    Function()? onDismissed,
  }) async {
    if (!_isInitialized || !_consentObtained || !_rewardedLoaded) return false;

    if (_rewardedAd != null) {
      _onRewardEarned = onRewarded;
      _onAdDismissed = onDismissed;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _rewardedLoaded = false;
          _onAdDismissed?.call();
          _loadRewardedAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('AdManager: Failed to show rewarded ad: $error');
          ad.dispose();
          _rewardedAd = null;
          _rewardedLoaded = false;
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('AdManager: User earned reward: ${reward.amount} ${reward.type}');
          _onRewardEarned?.call();
          _trackAdEvent('reward_earned');
        },
      );

      _trackAdEvent('rewarded_shown');
      return true;
    }

    return false;
  }

  /// Track ad events for analytics
  void _trackAdEvent(String event) {
    FirebaseManager().trackAdEvent(event, {
      'session_ad_count': _sessionAdCount,
      'test_mode': _useTestAds,
    });
  }

  /// Clean up ads when no longer needed
  Future<void> dispose() async {
    await _bannerAd?.dispose();
    await _interstitialAd?.dispose();
    await _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _bannerLoaded = false;
    _interstitialLoaded = false;
    _rewardedLoaded = false;
  }

  /// Reset session counters
  void resetSession() {
    _sessionAdCount = 0;
    _lastInterstitialShow = null;
  }

  /// Check if ads should be shown based on user status
  Future<bool> shouldShowAds() async {
    if (!_isInitialized || !_consentObtained) return false;
    return !(await FirebaseManager().checkIfPremiumUser());
  }

  /// Smart ad placement logic
  Future<bool> shouldShowInterstitialNow() async {
    if (!await shouldShowAds()) return false;
    
    // Don't show on first app launch
    final launchCount = await FirebaseManager().getLaunchCount();
    if (launchCount < 2) return false;

    // Random chance with intelligence
    final random = Random();
    final chance = random.nextDouble();
    
    // 30% chance after meaningful interactions
    return chance < 0.3 && _sessionAdCount < _maxAdsPerSession;
  }

  /// Get current ad state for debugging
  Map<String, dynamic> getAdState() {
    return {
      'initialized': _isInitialized,
      'consent': _consentObtained,
      'banner_loaded': _bannerLoaded,
      'interstitial_loaded': _interstitialLoaded,
      'rewarded_loaded': _rewardedLoaded,
      'session_count': _sessionAdCount,
      'test_mode': _useTestAds,
    };
  }
}

/// Widget to display banner ads with automatic premium checking
class BannerAdWidget extends StatefulWidget {
  final EdgeInsets padding;
  
  const BannerAdWidget({
    Key? key,
    this.padding = const EdgeInsets.only(bottom: 8),
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdManager _adManager = AdManager();
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await FirebaseManager().checkIfPremiumUser();
    if (mounted) {
      setState(() => _isPremium = isPremium);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium || kIsWeb) return const SizedBox.shrink();

    final bannerAd = _adManager.getBannerAd();
    if (bannerAd == null) return const SizedBox.shrink();

    return Container(
      padding: widget.padding,
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}