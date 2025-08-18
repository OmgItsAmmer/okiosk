import 'package:flutter/material.dart';

class TProductPriceText extends StatelessWidget {
  const TProductPriceText({
    super.key,
    this.currencySign = "Rs",
    this.isSign = true,
    required this.price,
    this.maxLines=1,
    this.isLarge = false,
    this.lineThrough =false,
  });

  final String currencySign, price;
  final int maxLines;
  final bool isLarge;
  final bool lineThrough;
  final bool isSign;
  @override
  Widget build(BuildContext context) {
    //for overflow use ellipsis
    return Text(
        isSign ? "$currencySign $price" :  price,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: isLarge ? Theme.of(context).textTheme.headlineMedium!.apply(decoration: lineThrough ? TextDecoration.lineThrough : null) :
        Theme.of(context).textTheme.titleLarge!.apply(decoration: lineThrough ? TextDecoration.lineThrough : null),
        textAlign: TextAlign.center,
    );
  }
}
