
import 'package:flutter/foundation.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../main.dart';

class ShopRepository {
  //get is shipping alloed  from supabase
  Future<bool> isShippingAllowed() async {
    try {
      final response =
          await supabase.from('shop').select('is_shipping_enable').single();

      return response['is_shipping_enable'] ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(e);
        TLoader.errorSnackBar(title: 'Error', message: e.toString());
      }
      return false;
    }
  }

  Future<int> maxAllowedQuantity() async {
    try {
      final response = await supabase
          .from('shop')
          .select('max_allowed_item_quantity')
          .single();
      final maxQuantity = response['max_allowed_item_quantity'];
      // Return 50 as default if null or 0, otherwise return the actual value
      return (maxQuantity != null && maxQuantity > 0) ? maxQuantity : 50;
    } catch (e) {
      if (kDebugMode) {
        print(e);
        TLoader.errorSnackBar(title: 'Error', message: e.toString());
      }
      return 50;
    }
  }
}
