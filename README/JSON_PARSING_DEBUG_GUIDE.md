# JSON Parsing Debug Guide

## Overview

This guide explains the fixes applied to resolve "unable to parse" errors in the
AI command service and provides debugging steps for JSON parsing issues.

## Issues Fixed

### 1. Enhanced AiCommandResponse.fromJson Method

**Problem**: The original method had limited error handling and didn't properly
handle different response formats from the backend.

**Solution**:

- Added comprehensive type checking for all response fields
- Enhanced handling of `actions_executed` field that can be either strings or
  objects
- Added detailed debug logging for each parsing step
- Improved error messages with specific failure reasons

**Key Improvements**:

```dart
// Before: Simple type checking
actionsExecutedRaw: jsonMap['actions_executed'] != null
    ? (jsonMap['actions_executed'] as List)
        .map((action) => action.toString())
        .toList()
    : [],

// After: Comprehensive type handling
if (actionsExecuted is List) {
  for (int i = 0; i < actionsExecuted.length; i++) {
    final action = actionsExecuted[i];
    if (action is String) {
      actionsList.add(action);
    } else if (action is Map<String, dynamic>) {
      try {
        final jsonString = jsonEncode(action);
        actionsList.add(jsonString);
      } catch (e) {
        actionsList.add(action.toString());
      }
    } else {
      actionsList.add(action.toString());
    }
  }
}
```

### 2. Improved AiAction.fromJsonString Method

**Problem**: Limited error handling when parsing individual action JSON strings.

**Solution**:

- Added empty string validation
- Enhanced JSON parsing with detailed error reporting
- Added type validation after JSON decoding
- Comprehensive debug logging for troubleshooting

**Key Improvements**:

```dart
// Before: Basic try-catch
try {
  final Map<String, dynamic> json = jsonDecode(jsonString);
  return AiAction.fromJson(json);
} catch (e) {
  return AiAction(/* error action */);
}

// After: Comprehensive validation
if (jsonString.isEmpty) {
  return AiAction(/* empty string error */);
}

try {
  final dynamic json = jsonDecode(jsonString);
  if (json is! Map<String, dynamic>) {
    return AiAction(/* type error */);
  }
  return AiAction.fromJson(json);
} catch (e, stackTrace) {
  // Detailed error logging and reporting
}
```

### 3. Enhanced Debugging in AI Command Service

**Problem**: Insufficient debugging information when JSON parsing failures
occurred.

**Solution**:

- Added detailed request/response logging
- Enhanced error categorization (FormatException, SocketException, etc.)
- Added response format validation
- Improved error messages for different failure types

### 4. Response Format Validation

**Problem**: No validation of backend response format compatibility.

**Solution**:

- Added `isValidFormat` property to validate response structure
- Added `validationErrors` property to get specific error details
- Integrated validation into the command processing flow

## Expected Backend Response Formats

### Standard Response Format

```json
{
    "success": true,
    "message": "Ready to add 2 Large Pizza to cart",
    "actions_executed": [
        "{\"action_type\":\"add_to_cart\",\"success\":true,\"message\":\"Ready to add 2 Large Pizza to cart\",\"data\":{\"variant_id\":123,\"product_name\":\"Large Pizza\",\"variant_name\":\"Large\",\"quantity\":2,\"available_stock\":50,\"sell_price\":15.99,\"session_id\":\"session-uuid\",\"customer_id\":null},\"error\":null}"
    ],
    "error": null
}
```

### Alternative Response Format (Actions as Objects)

```json
{
    "success": true,
    "message": "Ready to add 2 Large Pizza to cart",
    "actions_executed": [
        {
            "action_type": "add_to_cart",
            "success": true,
            "message": "Ready to add 2 Large Pizza to cart",
            "data": {
                "variant_id": 123,
                "product_name": "Large Pizza",
                "variant_name": "Large",
                "quantity": 2,
                "available_stock": 50,
                "sell_price": 15.99,
                "session_id": "session-uuid",
                "customer_id": null
            },
            "error": null
        }
    ],
    "error": null
}
```

### String Response Format

```json
"Product added successfully"
```

## Debugging Steps

### 1. Enable Debug Mode

Ensure debug mode is enabled in your Flutter app:

```dart
// In main.dart or your debug configuration
import 'package:flutter/foundation.dart';

void main() {
  // Debug mode should be enabled by default in debug builds
  runApp(MyApp());
}
```

### 2. Check Terminal Output

When JSON parsing issues occur, look for these debug sections in the terminal:

```
========== AI COMMAND REQUEST ==========
AiCommandService: Sending AI command
AiCommandService: Prompt: add 2 large pizzas to cart
AiCommandService: Session ID: kiosk-session-123
AiCommandService: Customer ID: null
AiCommandService: Request body: {prompt: add 2 large pizzas to cart, session_id: kiosk-session-123}
AiCommandService: Endpoint: POST /api/ai/command
========================================

========== AI COMMAND RESPONSE ==========
AiCommandService: Response success: true
AiCommandService: Response message: Ready to add 2 Large Pizza to cart
AiCommandService: Status code: 200
AiCommandService: Has data: true
AiCommandService: Actions count: 1
AiCommandService: AI response message: Ready to add 2 Large Pizza to cart
AiCommandService: AI response success: true
AiCommandService: Format valid: true
AiCommandService: Action 0: {"action_type":"add_to_cart",...}
=========================================
```

### 3. Check for Validation Errors

Look for validation error messages:

```
AiCommandService: Validation errors:
AiCommandService: - Action 0 has invalid JSON: FormatException: Unexpected character
```

### 4. Check JSON String Parsing

Look for individual action parsing details:

```
========== AI ACTION JSON STRING PARSING ==========
AiAction: Parsing JSON string: {"action_type":"add_to_cart",...}
AiAction: String length: 245
AiAction: Successfully decoded JSON
AiAction: Decoded type: _Map<String, dynamic>
AiAction: Decoded content: {action_type: add_to_cart, success: true, ...}
AiAction: Successfully parsed action
AiAction: Action type: add_to_cart
AiAction: Action success: true
AiAction: Action message: Ready to add 2 Large Pizza to cart
AiAction: Has data: true
AiAction: Error: null
===============================================
```

## Common Issues and Solutions

### 1. Backend Returns Invalid JSON

**Symptoms**: `FormatException: Unexpected character` errors

**Debug Steps**:

1. Check the raw response in terminal output
2. Look for malformed JSON strings in `actions_executed`
3. Verify backend is returning properly escaped JSON strings

**Solution**: Fix backend JSON serialization or add proper escaping

### 2. Backend Returns Wrong Data Types

**Symptoms**: `Expected Map<String, dynamic>, got String` errors

**Debug Steps**:

1. Check the response structure in terminal output
2. Look for `actions_executed` field type validation messages

**Solution**: Ensure backend returns consistent data types

### 3. Empty or Null Response Fields

**Symptoms**: Validation errors about empty fields

**Debug Steps**:

1. Check validation error messages
2. Look for empty string or null field reports

**Solution**: Ensure backend returns all required fields with valid values

### 4. Network or Server Issues

**Symptoms**: `SocketException` or `TimeoutException` errors

**Debug Steps**:

1. Check network connectivity
2. Verify backend server is running
3. Check server response time

**Solution**: Fix network issues or server problems

## Testing the Fixes

### 1. Test with Valid Response

```dart
final result = await aiService.processCommandAndExecute(
  prompt: "add 2 large pizzas to cart",
  sessionId: "test-session-123",
);

if (result.success) {
  print('Success: ${result.message}');
} else {
  print('Error: ${result.message}');
}
```

### 2. Test with Invalid Response

The enhanced error handling will now provide specific error messages for
different types of failures, making it easier to identify and fix backend
issues.

## Backend Compatibility

The fixes ensure compatibility with multiple response formats:

1. **JSON strings in actions_executed** (primary format)
2. **JSON objects in actions_executed** (converted to strings)
3. **String responses** (message-only responses)
4. **Mixed formats** (handled gracefully)

## Performance Impact

The enhanced validation and debugging:

- Adds minimal overhead in production (debug logging is conditional)
- Improves error detection and reporting
- Reduces time spent debugging JSON parsing issues
- Provides better user experience with specific error messages

## Next Steps

If you continue to experience parsing issues:

1. Check the terminal output for specific error messages
2. Verify your backend is returning the expected format
3. Test with a simple command first (e.g., "show menu")
4. Check network connectivity and server status
5. Verify session ID and customer ID are being passed correctly

The enhanced debugging will now provide detailed information about exactly where
the parsing is failing, making it much easier to identify and resolve issues.

