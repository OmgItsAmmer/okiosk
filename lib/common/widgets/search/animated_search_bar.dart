import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/features/products/controller/product_controller.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/layouts/template.dart';
import '../custom_shapes/containers/rounded_container.dart';
import 'typewriter_hint_text.dart';

/// Animated Search Bar Widget for Kiosk Header
///
/// Features:
/// - Animated hint text that cycles through different search suggestions
/// - Smooth upward/downward transitions between hint texts
/// - Integration with ProductController for search functionality
/// - Debounced search to avoid excessive API calls
class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({super.key});

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Controllers
  late ProductController _productController;

  // Search hints that will cycle through with typewriter effect
  final List<String> _searchHints = [
    'Search products...',
    'Find electronics...',
    'Browse categories...',
    'Discover deals...',
  ];

  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    try {
      _productController = Get.find<ProductController>();
    } catch (e) {
      // Controllers might not be initialized yet
      print('Error finding controllers: $e');
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous search timer
    _searchTimer?.cancel();

    // Start new search timer (debounced)
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    try {
      _productController.searchProducts(query);
    } catch (e) {
      print('Error performing search: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      height: PosLayoutTemplate.getResponsiveSpacing(context, 40),
      padding: EdgeInsets.symmetric(
        horizontal: PosLayoutTemplate.getResponsiveSpacing(context, 12),
      ),
      backgroundColor: TColors.primaryBackground.withValues(alpha: 0.1),
      borderColor: TColors.borderPrimary,
      shadowBorder: true,
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: PosLayoutTemplate.getResponsiveFontSize(context, 18),
            color: TColors.lightModePrimaryText,
          ),
          SizedBox(
            width: PosLayoutTemplate.getResponsiveSpacing(context, 8),
          ),
          Expanded(
            child: Stack(
              children: [
                // TextField
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TColors.lightModePrimaryText,
                      ),
                ),
                // Typewriter hint text overlay
                if (_textController.text.isEmpty)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TypewriterHintText(
                        hintTexts: _searchHints,
                        textStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: TColors.lightModeSecondaryText,
                                ),
                        typingSpeed: const Duration(milliseconds: 80),
                        pauseBetweenLines: const Duration(milliseconds: 2000),
                        pauseBetweenCycles: const Duration(milliseconds: 3000),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
