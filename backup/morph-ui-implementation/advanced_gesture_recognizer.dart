import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

/// Advanced gesture types for Morph-UI
enum GestureType {
  swipeFromEdge,
  pinchToCollapse,
  doubleTapHold,
  rotateToSwitch,
  multiFingerSwipe,
  pressAndDrag,
  flickDismiss,
  longPressReveal,
}

/// Gesture event data
class MorphGestureEvent {
  final GestureType type;
  final Offset position;
  final Offset? delta;
  final double? scale;
  final double? rotation;
  final int pointerCount;
  final Duration? duration;
  final double? velocity;
  final Map<String, dynamic> metadata;

  MorphGestureEvent({
    required this.type,
    required this.position,
    this.delta,
    this.scale,
    this.rotation,
    this.pointerCount = 1,
    this.duration,
    this.velocity,
    this.metadata = const {},
  });
}

/// Advanced gesture recognizer for Morph-UI
class AdvancedGestureRecognizer extends StatefulWidget {
  final Widget child;
  final Function(MorphGestureEvent)? onGesture;
  final bool enableEdgeSwipes;
  final bool enablePinchGestures;
  final bool enableRotationGestures;
  final bool enableMultiTouch;
  final double edgeThreshold;
  final Duration longPressDelay;

  const AdvancedGestureRecognizer({
    Key? key,
    required this.child,
    this.onGesture,
    this.enableEdgeSwipes = true,
    this.enablePinchGestures = true,
    this.enableRotationGestures = true,
    this.enableMultiTouch = true,
    this.edgeThreshold = 20.0,
    this.longPressDelay = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<AdvancedGestureRecognizer> createState() => _AdvancedGestureRecognizerState();
}

class _AdvancedGestureRecognizerState extends State<AdvancedGestureRecognizer> {
  // Gesture tracking
  final Map<int, Offset> _pointers = {};
  Offset? _initialFocalPoint;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;
  
  // Edge detection
  EdgeInsets _screenEdges = EdgeInsets.zero;
  Size _screenSize = Size.zero;
  
  // Timing
  DateTime? _gestureStartTime;
  Timer? _longPressTimer;
  
  // Gesture state
  bool _isScaling = false;
  bool _isRotating = false;
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScreenDimensions();
    });
  }
  
  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }
  
  void _updateScreenDimensions() {
    final mediaQuery = MediaQuery.of(context);
    _screenSize = mediaQuery.size;
    _screenEdges = EdgeInsets.only(
      left: widget.edgeThreshold,
      top: widget.edgeThreshold + mediaQuery.padding.top,
      right: _screenSize.width - widget.edgeThreshold,
      bottom: _screenSize.height - widget.edgeThreshold - mediaQuery.padding.bottom,
    );
  }
  
  void _handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    _gestureStartTime = DateTime.now();
    
    // Start long press timer
    _longPressTimer?.cancel();
    _longPressTimer = Timer(widget.longPressDelay, () {
      if (_pointers.length == 1) {
        _triggerGesture(MorphGestureEvent(
          type: GestureType.longPressReveal,
          position: event.position,
          pointerCount: 1,
          duration: widget.longPressDelay,
        ));
        HapticFeedback.mediumImpact();
      }
    });
    
    // Check for edge press
    if (widget.enableEdgeSwipes) {
      _checkEdgePress(event.position);
    }
  }
  
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    
    final previousPosition = _pointers[event.pointer]!;
    _pointers[event.pointer] = event.position;
    
    if (_pointers.length == 1 && !_isScaling && !_isRotating) {
      // Single finger drag
      _handleDrag(event.position, event.delta);
    } else if (_pointers.length >= 2 && widget.enableMultiTouch) {
      // Multi-touch gestures
      _handleMultiTouch();
    }
  }
  
  void _handlePointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    
    if (_pointers.length == 1) {
      // Calculate gesture duration and velocity
      final duration = _gestureStartTime != null
          ? DateTime.now().difference(_gestureStartTime!)
          : Duration.zero;
      
      // Check for flick gesture
      if (duration.inMilliseconds < 300 && event.distance > 50) {
        _triggerGesture(MorphGestureEvent(
          type: GestureType.flickDismiss,
          position: event.position,
          velocity: event.distance / duration.inMilliseconds,
          duration: duration,
        ));
      }
    }
    
    _pointers.remove(event.pointer);
    
    if (_pointers.isEmpty) {
      _resetGestureState();
    }
  }
  
  void _handleDrag(Offset position, Offset delta) {
    _isDragging = true;
    
    // Check for edge swipe
    if (widget.enableEdgeSwipes) {
      if (position.dx <= _screenEdges.left && delta.dx > 5) {
        _triggerGesture(MorphGestureEvent(
          type: GestureType.swipeFromEdge,
          position: position,
          delta: delta,
          metadata: {'edge': 'left'},
        ));
      } else if (position.dx >= _screenEdges.right && delta.dx < -5) {
        _triggerGesture(MorphGestureEvent(
          type: GestureType.swipeFromEdge,
          position: position,
          delta: delta,
          metadata: {'edge': 'right'},
        ));
      } else if (position.dy <= _screenEdges.top && delta.dy > 5) {
        _triggerGesture(MorphGestureEvent(
          type: GestureType.swipeFromEdge,
          position: position,
          delta: delta,
          metadata: {'edge': 'top'},
        ));
      } else if (position.dy >= _screenEdges.bottom && delta.dy < -5) {
        _triggerGesture(MorphGestureEvent(
          type: GestureType.swipeFromEdge,
          position: position,
          delta: delta,
          metadata: {'edge': 'bottom'},
        ));
      }
    }
  }
  
  void _handleMultiTouch() {
    if (_pointers.length < 2) return;
    
    // Calculate focal point
    final positions = _pointers.values.toList();
    final focalPoint = positions.reduce((a, b) => a + b) / positions.length.toDouble();
    
    if (_initialFocalPoint == null) {
      _initialFocalPoint = focalPoint;
      _initialScale = _calculateScale();
      _initialRotation = _calculateRotation();
      return;
    }
    
    // Pinch/zoom detection
    if (widget.enablePinchGestures) {
      final currentScale = _calculateScale();
      final scaleChange = currentScale / _initialScale;
      
      if ((scaleChange < 0.8 || scaleChange > 1.2) && !_isRotating) {
        _isScaling = true;
        _triggerGesture(MorphGestureEvent(
          type: GestureType.pinchToCollapse,
          position: focalPoint,
          scale: scaleChange,
          pointerCount: _pointers.length,
        ));
      }
    }
    
    // Rotation detection
    if (widget.enableRotationGestures && _pointers.length == 2) {
      final currentRotation = _calculateRotation();
      final rotationDelta = currentRotation - _initialRotation;
      
      if (rotationDelta.abs() > 0.3 && !_isScaling) {
        _isRotating = true;
        _triggerGesture(MorphGestureEvent(
          type: GestureType.rotateToSwitch,
          position: focalPoint,
          rotation: rotationDelta,
          pointerCount: 2,
        ));
      }
    }
    
    // Multi-finger swipe
    if (_pointers.length >= 3) {
      final delta = focalPoint - _initialFocalPoint!;
      if (delta.distance > 50) {
        _triggerGesture(MorphGestureEvent(
          type: GestureType.multiFingerSwipe,
          position: focalPoint,
          delta: delta,
          pointerCount: _pointers.length,
        ));
      }
    }
  }
  
  double _calculateScale() {
    if (_pointers.length < 2) return 1.0;
    
    final positions = _pointers.values.toList();
    double totalDistance = 0;
    int count = 0;
    
    for (int i = 0; i < positions.length - 1; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        totalDistance += (positions[i] - positions[j]).distance;
        count++;
      }
    }
    
    return count > 0 ? totalDistance / count : 1.0;
  }
  
  double _calculateRotation() {
    if (_pointers.length != 2) return 0.0;
    
    final positions = _pointers.values.toList();
    final delta = positions[1] - positions[0];
    return math.atan2(delta.dy, delta.dx);
  }
  
  void _checkEdgePress(Offset position) {
    String? edge;
    
    if (position.dx <= _screenEdges.left) {
      edge = 'left';
    } else if (position.dx >= _screenEdges.right) {
      edge = 'right';
    } else if (position.dy <= _screenEdges.top) {
      edge = 'top';
    } else if (position.dy >= _screenEdges.bottom) {
      edge = 'bottom';
    }
    
    if (edge != null) {
      HapticFeedback.selectionClick();
    }
  }
  
  void _triggerGesture(MorphGestureEvent event) {
    widget.onGesture?.call(event);
  }
  
  void _resetGestureState() {
    _initialFocalPoint = null;
    _initialScale = 1.0;
    _initialRotation = 0.0;
    _isScaling = false;
    _isRotating = false;
    _isDragging = false;
    _gestureStartTime = null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: GestureDetector(
        onDoubleTap: () {
          final center = Offset(_screenSize.width / 2, _screenSize.height / 2);
          _triggerGesture(MorphGestureEvent(
            type: GestureType.doubleTapHold,
            position: center,
            pointerCount: 1,
          ));
          HapticFeedback.lightImpact();
        },
        child: widget.child,
      ),
    );
  }
}

/// Gesture handler mixin for easy integration
mixin AdvancedGestureHandler {
  void handleMorphGesture(MorphGestureEvent event) {
    switch (event.type) {
      case GestureType.swipeFromEdge:
        final edge = event.metadata['edge'] as String?;
        onEdgeSwipe(edge ?? '', event.delta ?? Offset.zero);
        break;
        
      case GestureType.pinchToCollapse:
        onPinchGesture(event.scale ?? 1.0);
        break;
        
      case GestureType.doubleTapHold:
        onDoubleTapHold(event.position);
        break;
        
      case GestureType.rotateToSwitch:
        onRotateGesture(event.rotation ?? 0.0);
        break;
        
      case GestureType.multiFingerSwipe:
        onMultiFingerSwipe(event.pointerCount, event.delta ?? Offset.zero);
        break;
        
      case GestureType.pressAndDrag:
        onPressAndDrag(event.position, event.delta ?? Offset.zero);
        break;
        
      case GestureType.flickDismiss:
        onFlickDismiss(event.velocity ?? 0.0);
        break;
        
      case GestureType.longPressReveal:
        onLongPressReveal(event.position);
        break;
    }
  }
  
  // Override these methods in implementing classes
  void onEdgeSwipe(String edge, Offset delta) {}
  void onPinchGesture(double scale) {}
  void onDoubleTapHold(Offset position) {}
  void onRotateGesture(double rotation) {}
  void onMultiFingerSwipe(int fingerCount, Offset delta) {}
  void onPressAndDrag(Offset position, Offset delta) {}
  void onFlickDismiss(double velocity) {}
  void onLongPressReveal(Offset position) {}
}