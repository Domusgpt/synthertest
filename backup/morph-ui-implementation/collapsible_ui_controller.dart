import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Controller for managing collapsible UI elements with gesture support
class CollapsibleUIController extends ChangeNotifier {
  // UI element visibility states
  final Map<String, bool> _elementVisibility = {};
  final Map<String, double> _elementOpacity = {};
  final Map<String, Offset> _elementPositions = {};
  final Map<String, Size> _elementSizes = {};
  
  // Collapse animation controllers
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};
  
  // Auto-hide configuration
  bool _autoHideEnabled = false;
  Duration _autoHideDelay = const Duration(seconds: 3);
  Timer? _autoHideTimer;
  
  // Gesture thresholds
  double _swipeThreshold = 50.0;
  double _pinchThreshold = 0.2;
  
  // Edge detection zones
  final double _edgeZoneSize = 20.0;
  EdgeInsets _safeArea = EdgeInsets.zero;
  
  // Active gestures
  final Set<String> _activeGestures = {};
  
  CollapsibleUIController() {
    _initializeDefaults();
  }
  
  void _initializeDefaults() {
    // Default UI elements
    final elements = [
      'topBar',
      'bottomBar',
      'leftPanel',
      'rightPanel',
      'floatingControls',
      'miniMap',
      'performanceStats',
    ];
    
    for (final element in elements) {
      _elementVisibility[element] = true;
      _elementOpacity[element] = 1.0;
      _elementPositions[element] = Offset.zero;
      _elementSizes[element] = Size.zero;
    }
  }
  
  /// Register an animation controller for an element
  void registerAnimationController(
    String elementId,
    AnimationController controller, {
    Curve curve = Curves.easeOutCubic,
  }) {
    _animationControllers[elementId] = controller;
    _animations[elementId] = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    
    // Sync with current visibility
    if (_elementVisibility[elementId] == true) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }
  
  /// Toggle visibility of a UI element
  Future<void> toggleElement(String elementId) async {
    final isVisible = _elementVisibility[elementId] ?? true;
    await setElementVisibility(elementId, !isVisible);
  }
  
  /// Set visibility of a UI element with animation
  Future<void> setElementVisibility(String elementId, bool visible) async {
    if (_elementVisibility[elementId] == visible) return;
    
    _elementVisibility[elementId] = visible;
    
    // Animate if controller exists
    final controller = _animationControllers[elementId];
    if (controller != null) {
      if (visible) {
        await controller.forward();
      } else {
        await controller.reverse();
      }
    }
    
    // Update opacity
    _elementOpacity[elementId] = visible ? 1.0 : 0.0;
    
    notifyListeners();
    _resetAutoHideTimer();
  }
  
  /// Collapse all UI elements
  Future<void> collapseAll() async {
    final futures = <Future>[];
    
    for (final elementId in _elementVisibility.keys) {
      if (elementId != 'floatingControls') { // Keep some elements visible
        futures.add(setElementVisibility(elementId, false));
      }
    }
    
    await Future.wait(futures);
    HapticFeedback.lightImpact();
  }
  
  /// Expand all UI elements
  Future<void> expandAll() async {
    final futures = <Future>[];
    
    for (final elementId in _elementVisibility.keys) {
      futures.add(setElementVisibility(elementId, true));
    }
    
    await Future.wait(futures);
    HapticFeedback.lightImpact();
  }
  
  /// Handle swipe gesture for collapsing UI
  void handleSwipeGesture(DragEndDetails details, Size screenSize) {
    final velocity = details.velocity.pixelsPerSecond;
    final position = details.localPosition;
    
    // Detect edge swipes
    if (position.dx < _edgeZoneSize) {
      // Left edge swipe
      if (velocity.dx < -_swipeThreshold) {
        setElementVisibility('leftPanel', false);
      } else if (velocity.dx > _swipeThreshold) {
        setElementVisibility('leftPanel', true);
      }
    } else if (position.dx > screenSize.width - _edgeZoneSize) {
      // Right edge swipe
      if (velocity.dx > _swipeThreshold) {
        setElementVisibility('rightPanel', false);
      } else if (velocity.dx < -_swipeThreshold) {
        setElementVisibility('rightPanel', true);
      }
    } else if (position.dy < _edgeZoneSize) {
      // Top edge swipe
      if (velocity.dy < -_swipeThreshold) {
        setElementVisibility('topBar', false);
      } else if (velocity.dy > _swipeThreshold) {
        setElementVisibility('topBar', true);
      }
    } else if (position.dy > screenSize.height - _edgeZoneSize) {
      // Bottom edge swipe
      if (velocity.dy > _swipeThreshold) {
        setElementVisibility('bottomBar', false);
      } else if (velocity.dy < -_swipeThreshold) {
        setElementVisibility('bottomBar', true);
      }
    }
  }
  
  /// Handle pinch gesture for global UI collapse
  void handlePinchGesture(double scale) {
    if (scale < 1.0 - _pinchThreshold) {
      // Pinch in - collapse UI
      collapseAll();
    } else if (scale > 1.0 + _pinchThreshold) {
      // Pinch out - expand UI
      expandAll();
    }
  }
  
  /// Handle double tap for quick toggle
  void handleDoubleTap(Offset position, Size screenSize) {
    // Center area toggles all
    final center = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: screenSize.width * 0.3,
      height: screenSize.height * 0.3,
    );
    
    if (center.contains(position)) {
      // Toggle all UI elements
      final anyVisible = _elementVisibility.values.any((v) => v);
      if (anyVisible) {
        collapseAll();
      } else {
        expandAll();
      }
    }
  }
  
  /// Enable auto-hide functionality
  void enableAutoHide({Duration delay = const Duration(seconds: 3)}) {
    _autoHideEnabled = true;
    _autoHideDelay = delay;
    _resetAutoHideTimer();
    notifyListeners();
  }
  
  /// Disable auto-hide functionality
  void disableAutoHide() {
    _autoHideEnabled = false;
    _autoHideTimer?.cancel();
    notifyListeners();
  }
  
  /// Reset auto-hide timer
  void _resetAutoHideTimer() {
    _autoHideTimer?.cancel();
    
    if (_autoHideEnabled) {
      _autoHideTimer = Timer(_autoHideDelay, () {
        // Auto-hide non-essential UI elements
        setElementVisibility('topBar', false);
        setElementVisibility('bottomBar', false);
        setElementVisibility('leftPanel', false);
        setElementVisibility('rightPanel', false);
      });
    }
  }
  
  /// Handle user interaction to reset auto-hide
  void handleUserInteraction() {
    if (_autoHideEnabled) {
      // Show UI elements on interaction
      expandAll();
      _resetAutoHideTimer();
    }
  }
  
  /// Get visibility state for an element
  bool isElementVisible(String elementId) {
    return _elementVisibility[elementId] ?? true;
  }
  
  /// Get opacity for an element
  double getElementOpacity(String elementId) {
    return _elementOpacity[elementId] ?? 1.0;
  }
  
  /// Get animation for an element
  Animation<double>? getElementAnimation(String elementId) {
    return _animations[elementId];
  }
  
  /// Update safe area for edge detection
  void updateSafeArea(EdgeInsets safeArea) {
    _safeArea = safeArea;
    notifyListeners();
  }
  
  /// Create preset configurations
  Map<String, Map<String, bool>> getPresetConfigurations() {
    return {
      'full': {
        'topBar': true,
        'bottomBar': true,
        'leftPanel': true,
        'rightPanel': true,
        'floatingControls': true,
        'miniMap': true,
        'performanceStats': true,
      },
      'performance': {
        'topBar': false,
        'bottomBar': true,
        'leftPanel': false,
        'rightPanel': false,
        'floatingControls': true,
        'miniMap': false,
        'performanceStats': false,
      },
      'minimal': {
        'topBar': false,
        'bottomBar': false,
        'leftPanel': false,
        'rightPanel': false,
        'floatingControls': true,
        'miniMap': false,
        'performanceStats': false,
      },
      'visualizer': {
        'topBar': false,
        'bottomBar': false,
        'leftPanel': false,
        'rightPanel': false,
        'floatingControls': false,
        'miniMap': false,
        'performanceStats': false,
      },
    };
  }
  
  /// Apply preset configuration
  Future<void> applyPreset(String presetName) async {
    final presets = getPresetConfigurations();
    final config = presets[presetName];
    
    if (config != null) {
      final futures = <Future>[];
      
      config.forEach((elementId, visible) {
        futures.add(setElementVisibility(elementId, visible));
      });
      
      await Future.wait(futures);
    }
  }
  
  @override
  void dispose() {
    _autoHideTimer?.cancel();
    
    // Dispose animation controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
}

/// Helper widget for gesture detection
class CollapsibleUIGestureDetector extends StatelessWidget {
  final Widget child;
  final CollapsibleUIController controller;
  
  const CollapsibleUIGestureDetector({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        // Use center position for double tap
        controller.handleDoubleTap(
          Offset(size.width / 2, size.height / 2),
          size,
        );
      },
      onPanEnd: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        controller.handleSwipeGesture(details, size);
      },
      onScaleUpdate: (details) {
        if (details.pointerCount == 2) {
          controller.handlePinchGesture(details.scale);
        }
      },
      onTap: () {
        controller.handleUserInteraction();
      },
      child: child,
    );
  }
}