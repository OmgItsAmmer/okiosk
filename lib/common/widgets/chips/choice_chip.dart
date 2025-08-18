import 'package:okiosk/common/widgets/custom_shapes/containers/circular_container.dart';
import 'package:okiosk/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

class TChoiceChip extends StatelessWidget {
  const TChoiceChip({
    super.key,
    required this.text,
    required this.selected,
    this.onSelected,
    this.isOutOfStock = false,
    this.showCheckmark = true,
  });
  final String text;
  final bool selected;
  final void Function(bool)? onSelected;
  final bool isOutOfStock;
  final bool showCheckmark;
  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: ChoiceChip(
        label: THelperFunctions.getColor(text) != null
            ? const SizedBox()
            : Text(
                text,
                style: TextStyle(
                  color: isOutOfStock
                      ? (dark ? TColors.grey : TColors.black)
                      : (selected
                          ? TColors.white
                          : (dark ? TColors.white : TColors.black)),
                  decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                ),
              ),
        selected: selected && !isOutOfStock,
        onSelected: isOutOfStock ? null : onSelected,
        showCheckmark: showCheckmark,
        labelStyle: TextStyle(
          color: isOutOfStock
              ? (dark ? TColors.grey : TColors.black)
              : (selected
                  ? TColors.white
                  : (dark ? TColors.white : TColors.black)),
          decoration: isOutOfStock ? TextDecoration.lineThrough : null,
        ),
        avatar: THelperFunctions.getColor(text) != null
            ? TCircularContainer(
                width: 50,
                height: 50,
                backgroundColor: isOutOfStock
                    ? TColors.grey.withValues(alpha: 0.5)
                    : THelperFunctions.getColor(text)!,
                child: isOutOfStock
                    ? Icon(
                        Icons.close,
                        color: (dark) ? TColors.white : TColors.black,
                        size: 20,
                      )
                    : null,
              )
            : isOutOfStock
                ? Icon(
                    Icons.close,
                    color: (dark) ? TColors.white : TColors.black,
                    size: 16,
                  )
                : null,
        shape: THelperFunctions.getColor(text) != null ? CircleBorder() : null,
        backgroundColor: isOutOfStock
            ? TColors.grey.withValues(alpha: 0.5)
            : (THelperFunctions.getColor(text)),
        labelPadding: THelperFunctions.getColor(text) != null
            ? const EdgeInsets.all(0)
            : null,
        padding:
            THelperFunctions.getColor(text) != null ? EdgeInsets.all(0) : null,
        selectedColor: isOutOfStock
            ? TColors.grey.withValues(alpha: 0.5)
            : (THelperFunctions.getColor(text) != null
                ? THelperFunctions.getColor(text)!
                : TColors.primary),
        disabledColor: (dark)
            ? TColors.white.withValues(alpha: 0.5)
            : TColors.black.withValues(alpha: 0.5),
      ),
    );
  }
}
