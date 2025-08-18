import 'package:flutter/services.dart';



import '../../../features/categories/models/category_model.dart';
import '../../../main.dart';
import '../../../utils/exceptions/TFormatException.dart';

class CategoroyRepostirory {
//Get all cateogires
  Future<List<CategoryModel>> getAllCategories() async {
    try {
   

     
      // fetching entire table of categoreis
      final List<dynamic> response = await supabase.from('categories').select();

      // Convert each JSON object to CategoryModel
      final List<CategoryModel> categories =
          response.map((json) => CategoryModel.fromJson(json)).toList();

      // Sort categories to ensure "More" category always comes at the end
      categories.sort((a, b) {
        // If category name is "More", it should come last
        if (a.categoryName.toLowerCase() == 'more') return 1;
        if (b.categoryName.toLowerCase() == 'more') return -1;

        // For other categories, maintain alphabetical order
        return a.categoryName.compareTo(b.categoryName);
      });

      return categories;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}
