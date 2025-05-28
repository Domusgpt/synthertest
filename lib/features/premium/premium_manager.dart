import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../core/firebase_manager.dart';

/// Manages in-app purchases and premium subscriptions
class PremiumManager {
  static final PremiumManager _instance = PremiumManager._internal();
  factory PremiumManager() => _instance;
  PremiumManager._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Subscription Product IDs - REPLACE WITH YOUR ACTUAL PRODUCT IDS
  static const Map<String, String> _productIds = {
    'plus_monthly': 'com.domusgpt.synther.plus_monthly',      // $2.99/month
    'plus_yearly': 'com.domusgpt.synther.plus_yearly',        // $24.99/year (~$2.08/month)
    'pro_monthly': 'com.domusgpt.synther.pro_monthly',        // $9.99/month  
    'pro_yearly': 'com.domusgpt.synther.pro_yearly',          // $99/year (~$8.25/month)
    'studio_monthly': 'com.domusgpt.synther.studio_monthly',  // $19.99/month
    'studio_yearly': 'com.domusgpt.synther.studio_yearly',    // $199/year (~$16.58/month)
  };

  // Store product details
  final Map<String, ProductDetails> _products = {};
  final Map<String, PurchaseDetails> _purchases = {};
  
  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  // Callbacks
  Function(String)? _onPurchaseSuccess;
  Function(String)? _onPurchaseError;
  Function()? _onPurchaseRestored;

  /// Initialize the purchase system
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      // Check if billing is available
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        print('PremiumManager: In-app purchases not available');
        return;
      }

      // Set up purchase stream listener
      final purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: _onPurchaseStreamDone,
        onError: _onPurchaseStreamError,
      );

      // Load available products
      await _loadProducts();

      // Restore previous purchases
      await restorePurchases();

      _isInitialized = true;
      print('PremiumManager: Initialized successfully');
    } catch (e) {
      print('PremiumManager: Initialization failed: $e');
    }
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
        _productIds.values.toSet(),
      );

      if (response.error != null) {
        _queryProductError = response.error!.message;
        print('PremiumManager: Query products error: $_queryProductError');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        print('PremiumManager: Products not found: ${response.notFoundIDs}');
      }

      // Store product details
      for (final product in response.productDetails) {
        final key = _productIds.entries
            .firstWhere((entry) => entry.value == product.id,
                orElse: () => const MapEntry('', ''))
            .key;
        if (key.isNotEmpty) {
          _products[key] = product;
        }
      }

      print('PremiumManager: Loaded ${_products.length} products');
    } catch (e) {
      print('PremiumManager: Failed to load products: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      print('PremiumManager: Purchase update - ${purchase.productID}: ${purchase.status}');

      if (purchase.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        if (purchase.status == PurchaseStatus.error) {
          _handlePurchaseError(purchase);
        } else if (purchase.status == PurchaseStatus.purchased ||
                   purchase.status == PurchaseStatus.restored) {
          _handlePurchaseSuccess(purchase);
        }

        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }

        _purchasePending = false;
      }
    }
  }

  /// Handle successful purchase
  Future<void> _handlePurchaseSuccess(PurchaseDetails purchase) async {
    print('PremiumManager: Purchase successful - ${purchase.productID}');

    // Store purchase details
    _purchases[purchase.productID] = purchase;

    // Verify purchase with your backend (recommended for security)
    final isValid = await _verifyPurchase(purchase);
    if (!isValid) {
      print('PremiumManager: Purchase verification failed');
      _onPurchaseError?.call('Purchase verification failed');
      return;
    }

    // Update user's premium status in Firebase
    final tier = _getTierFromProductId(purchase.productID);
    if (tier != null) {
      await FirebaseManager().updateUserPremiumStatus(tier, purchase);
      _onPurchaseSuccess?.call(tier);
    }

    // Track purchase event
    FirebaseManager().trackPurchaseEvent(purchase.productID, {
      'verification_status': 'success',
      'purchase_time': purchase.transactionDate,
    });
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchase) {
    print('PremiumManager: Purchase error - ${purchase.error}');
    _onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed');
    
    FirebaseManager().trackPurchaseEvent(purchase.productID, {
      'error': purchase.error?.message,
      'error_code': purchase.error?.code,
    });
  }

  /// Verify purchase with backend (implement your own verification)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implement server-side receipt validation
    // For now, return true for testing
    // In production, send receipt to your backend for validation
    
    if (kDebugMode) {
      print('PremiumManager: Debug mode - skipping receipt validation');
      return true;
    }

    try {
      // Example backend verification
      // final response = await http.post(
      //   Uri.parse('https://your-backend.com/verify-purchase'),
      //   body: {
      //     'receipt': purchase.verificationData.serverVerificationData,
      //     'product_id': purchase.productID,
      //     'platform': Platform.operatingSystem,
      //   },
      // );
      // return response.statusCode == 200;
      
      return true; // Placeholder
    } catch (e) {
      print('PremiumManager: Verification error: $e');
      return false;
    }
  }

  /// Get premium tier from product ID
  String? _getTierFromProductId(String productId) {
    if (productId.contains('plus')) return 'plus';
    if (productId.contains('pro')) return 'pro';
    if (productId.contains('studio')) return 'studio';
    return null;
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(String tier, {bool isYearly = true}) async {
    if (!_isAvailable || _purchasePending) return false;

    final productKey = '${tier}_${isYearly ? 'yearly' : 'monthly'}';
    final product = _products[productKey];

    if (product == null) {
      print('PremiumManager: Product not found - $productKey');
      _onPurchaseError?.call('Product not available');
      return false;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      
      // Use the appropriate purchase method based on product type
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _onPurchaseError?.call('Purchase initiation failed');
      }

      return success;
    } catch (e) {
      print('PremiumManager: Purchase error: $e');
      _onPurchaseError?.call('Purchase failed: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _inAppPurchase.restorePurchases();
      _onPurchaseRestored?.call();
      print('PremiumManager: Restore purchases initiated');
    } catch (e) {
      print('PremiumManager: Restore purchases failed: $e');
      _onPurchaseError?.call('Failed to restore purchases');
    }
  }

  /// Get available products for display
  Map<String, SubscriptionOffer> getAvailableSubscriptions() {
    final Map<String, SubscriptionOffer> offers = {};

    // Plus tier
    final plusMonthly = _products['plus_monthly'];
    final plusYearly = _products['plus_yearly'];
    if (plusMonthly != null && plusYearly != null) {
      offers['plus'] = SubscriptionOffer(
        tier: 'plus',
        monthlyProduct: plusMonthly,
        yearlyProduct: plusYearly,
        features: [
          'No ads',
          '50 cloud presets',
          'Basic collaboration',
          'Export to WAV',
        ],
      );
    }

    // Pro tier
    final proMonthly = _products['pro_monthly'];
    final proYearly = _products['pro_yearly'];
    if (proMonthly != null && proYearly != null) {
      offers['pro'] = SubscriptionOffer(
        tier: 'pro',
        monthlyProduct: proMonthly,
        yearlyProduct: proYearly,
        features: [
          'Everything in Plus',
          '200 cloud presets',
          'Advanced collaboration',
          'MIDI export',
          'Cloud sync',
        ],
      );
    }

    // Studio tier
    final studioMonthly = _products['studio_monthly'];
    final studioYearly = _products['studio_yearly'];
    if (studioMonthly != null && studioYearly != null) {
      offers['studio'] = SubscriptionOffer(
        tier: 'studio',
        monthlyProduct: studioMonthly,
        yearlyProduct: studioYearly,
        features: [
          'Everything in Pro',
          'Unlimited presets',
          'Commercial license',
          'Priority support',
          'Beta features',
        ],
      );
    }

    return offers;
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    // Check local purchases first
    if (_purchases.isNotEmpty) {
      // Verify at least one purchase is still valid
      for (final purchase in _purchases.values) {
        if (purchase.status == PurchaseStatus.purchased) {
          return true;
        }
      }
    }

    // Fall back to Firebase check
    return await FirebaseManager().checkIfPremiumUser();
  }

  /// Get current subscription tier
  Future<String?> getCurrentTier() async {
    // Check active purchases
    for (final purchase in _purchases.values) {
      if (purchase.status == PurchaseStatus.purchased) {
        return _getTierFromProductId(purchase.productID);
      }
    }

    // Fall back to Firebase
    final userProfile = await FirebaseManager().getUserProfile();
    return userProfile?['premium_tier'];
  }

  /// Set callbacks for purchase events
  void setCallbacks({
    Function(String)? onPurchaseSuccess,
    Function(String)? onPurchaseError,
    Function()? onPurchaseRestored,
  }) {
    _onPurchaseSuccess = onPurchaseSuccess;
    _onPurchaseError = onPurchaseError;
    _onPurchaseRestored = onPurchaseRestored;
  }

  /// Clean up resources
  void dispose() {
    _subscription?.cancel();
  }

  /// Handle purchase stream done
  void _onPurchaseStreamDone() {
    _subscription?.cancel();
  }

  /// Handle purchase stream error
  void _onPurchaseStreamError(dynamic error) {
    print('PremiumManager: Purchase stream error: $error');
  }

  /// Get manager state for debugging
  Map<String, dynamic> getState() {
    return {
      'initialized': _isInitialized,
      'available': _isAvailable,
      'pending': _purchasePending,
      'products_loaded': _products.length,
      'active_purchases': _purchases.length,
      'query_error': _queryProductError,
    };
  }
}

/// Data model for subscription offers
class SubscriptionOffer {
  final String tier;
  final ProductDetails monthlyProduct;
  final ProductDetails yearlyProduct;
  final List<String> features;

  SubscriptionOffer({
    required this.tier,
    required this.monthlyProduct,
    required this.yearlyProduct,
    required this.features,
  });

  String get monthlyPrice => monthlyProduct.price;
  String get yearlyPrice => yearlyProduct.price;
  
  double get yearlySavingsPercent {
    // Calculate savings percentage
    // This is a simplified calculation - you may want to parse actual prices
    return 17.0; // Approximate 17% savings on yearly plans
  }
}