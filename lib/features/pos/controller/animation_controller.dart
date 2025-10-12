import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Animation controller for POS kiosk screen transitions
/// Handles the smooth transition when AI agent is clicked
class PosAnimationController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Animation values
  late Animation<double> _headerOpacity;
  late Animation<double> _productGridOpacity;
  late Animation<double> _cartSidebarExpansion;
  late Animation<double> _aiScreenOpacity;

  // Animation state
  final RxBool _isAnimating = false.obs;
  final RxBool _isAiScreenVisible = false.obs;

  // Animation durations
  static const Duration _animationDuration = Duration(milliseconds: 800);

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  /// Initialize all animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    // Header and product grid fade out animation
    _headerOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _productGridOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    // Cart sidebar expansion animation (to left half)
    _cartSidebarExpansion = Tween<double>(
      begin: 0.35, // Original width (35%)
      end: 0.5, // Expanded width (50%)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    // AI screen fade in animation
    _aiScreenOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
  }

  /// Start the transition to AI screen
  Future<void> showAiScreen() async {
    if (_isAnimating.value) {
      print('Already animating, skipping showAiScreen');
      return;
    }

    print('Starting showAiScreen animation');
    _isAnimating.value = true;
    _isAiScreenVisible.value = true;
    print('AI screen visible set to: ${_isAiScreenVisible.value}');

    try {
      await _animationController.forward();
      print('Animation forward completed');
    } finally {
      _isAnimating.value = false;
      if (kDebugMode) {
        print('Animation finished');
      }
    }
  }

  /// Reverse the transition back to normal POS screen
  Future<void> hideAiScreen() async {
    if (_isAnimating.value) return;

    _isAnimating.value = true;

    try {
      await _animationController.reverse();
    } finally {
      _isAnimating.value = false;
      _isAiScreenVisible.value = false;
    }
  }

  /// Get animation controller for AnimatedBuilder
  AnimationController get animationController => _animationController;

  /// Get animation values
  Animation<double> get headerOpacity => _headerOpacity;
  Animation<double> get productGridOpacity => _productGridOpacity;
  Animation<double> get cartSidebarExpansion => _cartSidebarExpansion;
  Animation<double> get aiScreenOpacity => _aiScreenOpacity;

  /// Get state values
  bool get isAnimating => _isAnimating.value;
  bool get isAiScreenVisible => _isAiScreenVisible.value;

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }
}
