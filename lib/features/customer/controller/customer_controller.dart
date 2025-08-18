import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/repositories/customer/customer_repository.dart';
import '../model/customer_model.dart';

class CustomerController extends GetxController {
  static CustomerController get instance => Get.find();

  final CustomerRepository customerRepository = Get.put(CustomerRepository());

  // Reactive state
  final RxBool isLoading = false.obs;
  Rx<CustomerModel> currentCustomer = CustomerModel.empty().obs;

  /// Fetch customer details by email
  Future<bool> fetchCustomerDetails(String email) async {
    try {
      isLoading.value = true;

      final customerData = await customerRepository.fetchCustomerDetails(email);

      if (customerData != null) {
        currentCustomer.value = customerData;
        if (kDebugMode) {
          print("Customer data loaded: ${currentCustomer.value.fullName}");
        }
        return true;
      } else {
        if (kDebugMode) {
          print("Customer not found for email: $email");
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching customer details: $e");
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Save customer record
  Future<bool> saveCustomer(CustomerModel customer) async {
    try {
      isLoading.value = true;

      await customerRepository.saveCustomerRecord(customer);

      // Update current customer if successful
      currentCustomer.value = customer;

      if (kDebugMode) {
        print("Customer saved successfully: ${customer.fullName}");
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Error saving customer: $e");
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get customer name by ID
  Future<String> getCustomerName(int customerId) async {
    try {
      return await customerRepository.getCustomerName(customerId);
    } catch (e) {
      if (kDebugMode) {
        print("Error getting customer name: $e");
      }
      return "Anonymous";
    }
  }

  /// Clear current customer data
  void clearCustomerData() {
    currentCustomer.value = CustomerModel.empty();
  }
}
