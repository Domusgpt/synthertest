import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'synth_parameters.dart';

/// Premium tier definitions matching the monetization strategy
enum PremiumTier {
  free,
  plus,    // $25/year - Extended presets, collaboration
  pro,     // $99/year - All features, cloud sync
  studio,  // $199/year - Commercial use, priority support
}

/// User profile model for Firebase
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final PremiumTier premiumTier;
  final DateTime? premiumExpiryDate;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;
  final int presetCount;
  final int sessionCount;
  final double totalUsageHours;
  
  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.premiumTier = PremiumTier.free,
    this.premiumExpiryDate,
    required this.createdAt,
    this.preferences = const {},
    this.presetCount = 0,
    this.sessionCount = 0,
    this.totalUsageHours = 0.0,
  });
  
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'premiumTier': premiumTier.name,
    'premiumExpiryDate': premiumExpiryDate?.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'preferences': preferences,
    'presetCount': presetCount,
    'sessionCount': sessionCount,
    'totalUsageHours': totalUsageHours,
  };
  
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] ?? '',
    email: json['email'] ?? '',
    displayName: json['displayName'],
    premiumTier: PremiumTier.values.firstWhere(
      (tier) => tier.name == json['premiumTier'],
      orElse: () => PremiumTier.free,
    ),
    premiumExpiryDate: json['premiumExpiryDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['premiumExpiryDate'])
        : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
    preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    presetCount: json['presetCount'] ?? 0,
    sessionCount: json['sessionCount'] ?? 0,
    totalUsageHours: (json['totalUsageHours'] ?? 0.0).toDouble(),
  );
}

/// Cloud preset model
class CloudPreset {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final String ownerId;
  final String? ownerDisplayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final List<String> tags;
  final int likeCount;
  final int downloadCount;
  
  CloudPreset({
    required this.id,
    required this.name,
    this.description = '',
    required this.parameters,
    required this.ownerId,
    this.ownerDisplayName,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.tags = const [],
    this.likeCount = 0,
    this.downloadCount = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'parameters': parameters,
    'ownerId': ownerId,
    'ownerDisplayName': ownerDisplayName,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'isPublic': isPublic,
    'tags': tags,
    'likeCount': likeCount,
    'downloadCount': downloadCount,
  };
  
  factory CloudPreset.fromJson(Map<String, dynamic> json) => CloudPreset(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    ownerId: json['ownerId'] ?? '',
    ownerDisplayName: json['ownerDisplayName'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    isPublic: json['isPublic'] ?? false,
    tags: List<String>.from(json['tags'] ?? []),
    likeCount: json['likeCount'] ?? 0,
    downloadCount: json['downloadCount'] ?? 0,
  );
}

/// Comprehensive Firebase manager for Synther
class FirebaseManager with ChangeNotifier {
  static final FirebaseManager _instance = FirebaseManager._internal();
  factory FirebaseManager() => _instance;
  FirebaseManager._internal();
  
  // Firebase services
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  
  // Current user state
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isInitialized = false;
  bool _initialized = false; // Add this field for backward compatibility
  
  // Getters
  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isInitialized => _isInitialized;
  bool get isSignedIn => _currentUser != null;
  bool get isPremiumUser => _userProfile?.premiumTier != PremiumTier.free;
  
  /// Initialize Firebase services
  Future<bool> initialize() async {
    try {
      if (!_isInitialized) {
        await Firebase.initializeApp();
        _isInitialized = true;
        _initialized = true; // Keep both flags in sync
        
        // Listen to auth state changes
        _auth.authStateChanges().listen(_onAuthStateChanged);
        
        // Load current user if signed in
        if (_auth.currentUser != null) {
          await _loadUserProfile();
        }
        
        await _analytics.logAppOpen();
        print('Firebase initialized successfully');
      }
      return true;
    } catch (e) {
      print('Failed to initialize Firebase: $e');
      return false;
    }
  }
  
  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    
    if (user != null) {
      await _loadUserProfile();
      await _analytics.setUserId(id: user.uid);
    } else {
      _userProfile = null;
      await _analytics.setUserId(id: null);
    }
    
    notifyListeners();
  }
  
  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      
      if (doc.exists) {
        _userProfile = UserProfile.fromJson(doc.data()!);
      } else {
        // Create new user profile
        _userProfile = UserProfile(
          uid: _currentUser!.uid,
          email: _currentUser!.email ?? '',
          displayName: _currentUser!.displayName,
          createdAt: DateTime.now(),
        );
        await _saveUserProfile();
      }
      
      notifyListeners();
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }
  
  /// Save user profile to Firestore
  Future<void> _saveUserProfile() async {
    if (_currentUser == null || _userProfile == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .set(_userProfile!.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('Failed to save user profile: $e');
    }
  }
  
  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _analytics.logLogin(loginMethod: 'email');
      return true;
    } catch (e) {
      print('Failed to sign in: $e');
      return false;
    }
  }
  
  /// Create account with email and password
  Future<bool> createUserWithEmailAndPassword(String email, String password, {String? displayName}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }
      
      await _analytics.logSignUp(signUpMethod: 'email');
      return true;
    } catch (e) {
      print('Failed to create account: $e');
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      print('Failed to sign out: $e');
    }
  }
  
  /// Update premium tier
  Future<bool> updatePremiumTier(PremiumTier tier, DateTime? expiryDate) async {
    if (_userProfile == null) return false;
    
    try {
      _userProfile = UserProfile(
        uid: _userProfile!.uid,
        email: _userProfile!.email,
        displayName: _userProfile!.displayName,
        premiumTier: tier,
        premiumExpiryDate: expiryDate,
        createdAt: _userProfile!.createdAt,
        preferences: _userProfile!.preferences,
        presetCount: _userProfile!.presetCount,
        sessionCount: _userProfile!.sessionCount,
        totalUsageHours: _userProfile!.totalUsageHours,
      );
      
      await _saveUserProfile();
      await _analytics.logEvent(name: 'premium_upgrade', parameters: {
        'tier': tier.name,
        'user_id': _userProfile!.uid,
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to update premium tier: $e');
      return false;
    }
  }
  
  /// Save preset to cloud
  Future<String?> savePresetToCloud(
    String name,
    String description,
    SynthParametersModel parameters, {
    bool isPublic = false,
    List<String> tags = const [],
  }) async {
    if (_currentUser == null) return null;
    
    try {
      final presetId = _firestore.collection('presets').doc().id;
      final preset = CloudPreset(
        id: presetId,
        name: name,
        description: description,
        parameters: parameters.toJson(),
        ownerId: _currentUser!.uid,
        ownerDisplayName: _userProfile?.displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: isPublic,
        tags: tags,
      );
      
      await _firestore
          .collection('presets')
          .doc(presetId)
          .set(preset.toJson());
      
      // Update user preset count
      if (_userProfile != null) {
        _userProfile = UserProfile(
          uid: _userProfile!.uid,
          email: _userProfile!.email,
          displayName: _userProfile!.displayName,
          premiumTier: _userProfile!.premiumTier,
          premiumExpiryDate: _userProfile!.premiumExpiryDate,
          createdAt: _userProfile!.createdAt,
          preferences: _userProfile!.preferences,
          presetCount: _userProfile!.presetCount + 1,
          sessionCount: _userProfile!.sessionCount,
          totalUsageHours: _userProfile!.totalUsageHours,
        );
        await _saveUserProfile();
      }
      
      await _analytics.logEvent(name: 'preset_saved', parameters: {
        'preset_id': presetId,
        'is_public': isPublic,
        'user_id': _currentUser!.uid,
      });
      
      return presetId;
    } catch (e) {
      print('Failed to save preset: $e');
      return null;
    }
  }
  
  /// Load user's presets
  Future<List<CloudPreset>> loadUserPresets() async {
    if (_currentUser == null) return [];
    
    try {
      final query = await _firestore
          .collection('presets')
          .where('ownerId', isEqualTo: _currentUser!.uid)
          .orderBy('updatedAt', descending: true)
          .get();
      
      return query.docs
          .map((doc) => CloudPreset.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to load user presets: $e');
      return [];
    }
  }
  
  /// Browse public presets
  Future<List<CloudPreset>> browsePublicPresets({
    String? tag,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('presets')
          .where('isPublic', isEqualTo: true);
      
      if (tag != null) {
        query = query.where('tags', arrayContains: tag);
      }
      
      final result = await query
          .orderBy('likeCount', descending: true)
          .limit(limit)
          .get();
      
      return result.docs
          .map((doc) => CloudPreset.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to browse public presets: $e');
      return [];
    }
  }
  
  /// Track session start
  Future<void> trackSessionStart() async {
    if (_userProfile == null) return;
    
    try {
      await _analytics.logEvent(name: 'session_start', parameters: {
        'user_id': _userProfile!.uid,
        'premium_tier': _userProfile!.premiumTier.name,
      });
      
      // Update session count
      _userProfile = UserProfile(
        uid: _userProfile!.uid,
        email: _userProfile!.email,
        displayName: _userProfile!.displayName,
        premiumTier: _userProfile!.premiumTier,
        premiumExpiryDate: _userProfile!.premiumExpiryDate,
        createdAt: _userProfile!.createdAt,
        preferences: _userProfile!.preferences,
        presetCount: _userProfile!.presetCount,
        sessionCount: _userProfile!.sessionCount + 1,
        totalUsageHours: _userProfile!.totalUsageHours,
      );
      
      await _saveUserProfile();
    } catch (e) {
      print('Failed to track session start: $e');
    }
  }
  
  /// Track session end with usage time
  Future<void> trackSessionEnd(Duration sessionDuration) async {
    if (_userProfile == null) return;
    
    try {
      final hours = sessionDuration.inMilliseconds / (1000 * 60 * 60);
      
      await _analytics.logEvent(name: 'session_end', parameters: {
        'user_id': _userProfile!.uid,
        'duration_minutes': sessionDuration.inMinutes,
        'premium_tier': _userProfile!.premiumTier.name,
      });
      
      // Update total usage hours
      _userProfile = UserProfile(
        uid: _userProfile!.uid,
        email: _userProfile!.email,
        displayName: _userProfile!.displayName,
        premiumTier: _userProfile!.premiumTier,
        premiumExpiryDate: _userProfile!.premiumExpiryDate,
        createdAt: _userProfile!.createdAt,
        preferences: _userProfile!.preferences,
        presetCount: _userProfile!.presetCount,
        sessionCount: _userProfile!.sessionCount,
        totalUsageHours: _userProfile!.totalUsageHours + hours,
      );
      
      await _saveUserProfile();
    } catch (e) {
      print('Failed to track session end: $e');
    }
  }
  
  /// Check premium status and update if expired
  bool checkPremiumStatus() {
    if (_userProfile == null) return false;
    
    final now = DateTime.now();
    if (_userProfile!.premiumExpiryDate != null && 
        _userProfile!.premiumExpiryDate!.isBefore(now)) {
      // Premium expired, downgrade to free
      updatePremiumTier(PremiumTier.free, null);
      return false;
    }
    
    return _userProfile!.premiumTier != PremiumTier.free;
  }
  
  /// Get feature limits based on premium tier
  Map<String, int> getFeatureLimits() {
    switch (_userProfile?.premiumTier ?? PremiumTier.free) {
      case PremiumTier.free:
        return {
          'maxPresets': 10,
          'maxCloudPresets': 3,
          'maxExports': 5,
          'llmGenerationsPerDay': 5,
        };
      case PremiumTier.plus:
        return {
          'maxPresets': 50,
          'maxCloudPresets': 20,
          'maxExports': 25,
          'llmGenerationsPerDay': 50,
        };
      case PremiumTier.pro:
        return {
          'maxPresets': 200,
          'maxCloudPresets': 100,
          'maxExports': 100,
          'llmGenerationsPerDay': 200,
        };
      case PremiumTier.studio:
        return {
          'maxPresets': -1, // Unlimited
          'maxCloudPresets': -1,
          'maxExports': -1,
          'llmGenerationsPerDay': -1,
        };
    }
  }
  
  // Additional methods for AdManager and PremiumManager integration
  
  /// Check if user is premium (for AdManager) - async version
  Future<bool> checkIfPremiumUser() async {
    await _ensureInitialized();
    return checkPremiumStatus();
  }
  
  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    await _ensureInitialized();
    return _userProfile?.toJson();
  }
  
  /// Track ad events
  Future<void> trackAdEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      await _analytics.logEvent(
        name: 'ad_$eventName',
        parameters: {
          ...parameters,
          'user_id': _currentUser?.uid ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track ad event: $e');
    }
  }
  
  /// Track purchase events
  Future<void> trackPurchaseEvent(String productId, Map<String, dynamic> parameters) async {
    try {
      await _analytics.logEvent(
        name: 'purchase_event',
        parameters: {
          'product_id': productId,
          ...parameters,
          'user_id': _currentUser?.uid ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track purchase event: $e');
    }
  }
  
  /// Get launch count for ad logic
  Future<int> getLaunchCount() async {
    await _ensureInitialized();
    return _userProfile?.sessionCount ?? 0;
  }
  
  /// Update user premium status from IAP
  Future<void> updateUserPremiumStatus(String tierName, dynamic purchaseDetails) async {
    PremiumTier tier;
    DateTime? expiryDate;
    
    switch (tierName.toLowerCase()) {
      case 'plus':
        tier = PremiumTier.plus;
        expiryDate = DateTime.now().add(const Duration(days: 365)); // Adjust based on actual subscription
        break;
      case 'pro':
        tier = PremiumTier.pro;
        expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      case 'studio':
        tier = PremiumTier.studio;
        expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      default:
        tier = PremiumTier.free;
        expiryDate = null;
    }
    
    await updatePremiumTier(tier, expiryDate);
    
    // Store purchase receipt for verification
    if (purchaseDetails != null && _currentUser != null) {
      try {
        await _firestore
            .collection('purchases')
            .doc(_currentUser!.uid)
            .collection('receipts')
            .add({
              'productId': purchaseDetails.productID,
              'purchaseTime': DateTime.now().toIso8601String(),
              'tier': tierName,
              'platform': purchaseDetails.verificationData?.source ?? 'unknown',
            });
      } catch (e) {
        print('Failed to store purchase receipt: $e');
      }
    }
  }
  
  /// Ensure Firebase is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}