import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/common/widgets/chips/choice_chip.dart';
import 'package:okiosk/utils/layouts/template.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/sizes.dart';

import '../../../utils/helpers/helper_functions.dart';
import '../../categories/controller/category_controller.dart';

/// Category Selector Widget for POS Kiosk
///
/// Displays categories in either a wrappable layout for large screens
/// or a horizontal scrollable layout for smaller screens
class CategorySelector extends GetView<CategoryController> {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      //  height: context.categoryBarHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace / 2),
      decoration: BoxDecoration(
        color: dark ? TColors.black : TColors.white,
        boxShadow: [
          BoxShadow(
            color: dark
                ? TColors.darkGrey.withValues(alpha: 0.1)
                : TColors.lightGrey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: context.shouldUseCategoryWrap
          ? _buildWrappableCategories(controller, context)
          : _buildScrollableCategories(controller, context),
    );
  }

  /// Build wrappable category layout for large screens
  Widget _buildWrappableCategories(
      CategoryController controller, BuildContext context) {
    return Obx(() {
      final categories = controller.allCategories;

      return SingleChildScrollView(
        child: Wrap(
          spacing: PosLayoutTemplate.getResponsiveSpacing(context, 8.0),
          runSpacing: PosLayoutTemplate.getResponsiveSpacing(context, 8.0),
          alignment: WrapAlignment.start,
          children: [
            // "All" category chip
            _buildCategoryChip(
              context: context,
              controller: controller,
              categoryId: null,
              categoryName: 'All Products',
              isSelected: controller.selectedCategoryId == null,
            ),
            // Individual category chips
            ...categories.map((category) => _buildCategoryChip(
                  context: context,
                  controller: controller,
                  categoryId: category.categoryId,
                  categoryName: category.categoryName,
                  isSelected:
                      controller.selectedCategoryId == category.categoryId,
                )),
          ],
        ),
      );
    });
  }

  /// Build horizontal scrollable category layout for smaller screens
  Widget _buildScrollableCategories(
      CategoryController controller, BuildContext context) {
    return Obx(() {
      final categories = controller.allCategories;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" category chip
            Padding(
              padding: EdgeInsets.only(
                right: PosLayoutTemplate.getResponsiveSpacing(context, 8.0),
              ),
              child: _buildCategoryChip(
                context: context,
                controller: controller,
                categoryId: null,
                categoryName: 'All Products',
                isSelected: controller.selectedCategoryId == null,
              ),
            ),
            // Individual category chips
            ...categories.map((category) => Padding(
                  padding: EdgeInsets.only(
                    right: PosLayoutTemplate.getResponsiveSpacing(context, 8.0),
                  ),
                  child: _buildCategoryChip(
                    context: context,
                    controller: controller,
                    categoryId: category.categoryId,
                    categoryName: category.categoryName,
                    isSelected:
                        controller.selectedCategoryId == category.categoryId,
                  ),
                )),
          ],
        ),
      );
    });
  }

  /// Build individual category chip
  Widget _buildCategoryChip({
    required BuildContext context,
    required CategoryController controller,
    required int? categoryId,
    required String categoryName,
    required bool isSelected,
  }) {
    return SizedBox(
      height: context.touchTargetSize,
      child: TChoiceChip(
        
        text: categoryName,
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            controller.selectCategory(categoryId);
          }
        },
        showCheckmark: false,
      ),
    );
  }
}

/// Category Header with count information
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      final selectedCategory = controller.selectedCategory;

      final productCount = controller.filteredProducts.length;

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsivePadding.horizontal / 2,
          vertical: TSizes.sm,
        ),
        child: Row(
          children: [
            Text(
              selectedCategory?.categoryName ?? 'All Products',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize:
                        PosLayoutTemplate.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    color:
                        dark ? TColors.primary : TColors.lightModePrimaryText,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.sm,
                vertical: TSizes.xs,
              ),
              decoration: BoxDecoration(
                color: TColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius,
                ),
                border: Border.all(
                  color: TColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '$productCount Products',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize:
                          PosLayoutTemplate.getResponsiveFontSize(context, 14),
                      color: TColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
