import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controller/chat_controller.dart';

/// Quick Actions Bar Widget
///
/// Provides quick action buttons for common AI commands
class QuickActionsBar extends StatelessWidget {
  final VoidCallback? onActionSelected;

  const QuickActionsBar({
    super.key,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.defaultSpace,
        vertical: TSizes.sm,
      ),
      decoration: BoxDecoration(
        color: TColors.lightContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: TColors.borderPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions label
          Padding(
            padding: const EdgeInsets.only(bottom: TSizes.sm),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: TSizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: TColors.lightModeSecondaryText,
              ),
            ),
          ),

          // Quick action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _buildQuickActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick action buttons
  List<Widget> _buildQuickActionButtons() {
    final actions = [
      QuickAction(
        icon: Iconsax.menu_1,
        label: 'Show Menu',
        command: 'Show menu',
        color: TColors.primary,
      ),
      QuickAction(
        icon: Iconsax.shopping_cart,
        label: 'Show Cart',
        command: 'Show cart',
        color: TColors.secondary,
      ),
      QuickAction(
        icon: Iconsax.add_circle,
        label: 'Add Burger',
        command: 'Add 2 burger to cart',
        color: TColors.accent,
      ),
      QuickAction(
        icon: Iconsax.receipt_2,
        label: 'Generate Bill',
        command: 'Bill bana do',
        color: TColors.success,
      ),
      QuickAction(
        icon: Iconsax.trash,
        label: 'Clear Cart',
        command: 'Clear cart',
        color: TColors.error,
      ),
    ];

    return actions.map((action) => _buildQuickActionButton(action)).toList();
  }

  /// Build individual quick action button
  Widget _buildQuickActionButton(QuickAction action) {
    return Container(
      margin: const EdgeInsets.only(right: TSizes.sm),
      child: Obx(() {
        final chatController = Get.find<ChatController>();
        final isLoading = chatController.isLoading;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            onTap: isLoading ? null : () => _handleQuickAction(action),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm,
              ),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                border: Border.all(
                  color: action.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    action.icon,
                    size: 16,
                    color: action.color,
                  ),
                  const SizedBox(width: TSizes.xs),
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: TSizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: action.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Handle quick action selection
  void _handleQuickAction(QuickAction action) {
    final chatController = Get.find<ChatController>();
    chatController.sendQuickCommand(action.command);

    // Call callback if provided
    onActionSelected?.call();
  }
}

/// Quick Action Model
class QuickAction {
  final IconData icon;
  final String label;
  final String command;
  final Color color;

  QuickAction({
    required this.icon,
    required this.label,
    required this.command,
    required this.color,
  });
}
