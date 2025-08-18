import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


import '../../../features/customer/model/customer_model.dart';
import '../../../main.dart';

class CustomerRepository {
  /// Fetch customer details based on customer email
  Future<CustomerModel?> fetchCustomerDetails(String customerEmail) async {
    try {
      final List<Map<String, dynamic>> customerData =
          await supabase.from('customers').select().eq('email', customerEmail);

      if (customerData.isEmpty) {
        return null;
      }

      return CustomerModel.fromJson(customerData.first);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Platform exception in fetchCustomerDetails: ${e.code}");
      }
      throw 'Failed to fetch customer details: ${e.message}';
    } catch (e) {
      if (kDebugMode) {
        print("Error in fetchCustomerDetails: $e");
      }
      throw 'Something went wrong. Please try again';
    }
  }

  /// Save customer record to Supabase
  Future<void> saveCustomerRecord(CustomerModel customer) async {
    try {
      await supabase
          .from('customers')
          .insert([customer.toJson(isInsert: true)]);
    } on PlatformException catch (e) {
      throw 'Failed to save customer: ${e.message}';
    } catch (e) {
      if (kDebugMode) {
        print("Error saving customer: $e");
      }
      throw 'Failed to save customer record';
    }
  }

  /// Get customer name by customer ID
  Future<String> getCustomerName(int customerId) async {
    try {
      final List<Map<String, dynamic>> customerData = await supabase
          .from('customers')
          .select()
          .eq('customer_id', customerId);

      if (customerData.isEmpty) {
        return "Anonymous";
      }

      return CustomerModel.fromJson(customerData.first).fullName;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting customer name: $e");
      }
      return "Anonymous";
    }
  }
}
