# Quick Test Guide - Sequential Variant Selection

## 🚀 Quick Start

### 1. Run App in Debug Mode

```bash
flutter run --debug
```

### 2. Test Command

In the chat, type:

```
add lux and rice to cart
```

(Or use any 2 products that have multiple variants)

### 3. Watch Console

You should see logs starting with:

- `========== SENDING AI COMMAND ==========`
- `========== SEQUENTIAL VARIANT DETECTED ==========`
- `========== VARIANT SELECTED ==========`
- `====== VARIANT CONFIRMATION REQUEST ======`
- `====== VARIANT CONFIRMATION RESPONSE ======`

---

## ✅ Success Indicators

### In Console:

```
====== VARIANT CONFIRMATION RESPONSE ======
Response success: true
Response message: Lux added! Now select variant for Rice
Has more items: true
============================================
```

### In App:

1. First variant selection appears (Lux)
2. After selection, second variant selection appears (Rice)
3. After second selection, success message appears
4. Both items added to cart

---

## ❌ Error Indicators

### In Console:

```
====== VARIANT CONFIRMATION RESPONSE ======
Response success: false
Response message: no active queue found
Status code: 404
============================================
```

### In App:

Error message:

```
Session expired or queue not found. This usually happens when:
• The backend restarted
• Too much time passed between selections
• The session was cleared

Please try your command again from the start.
```

---

## 🔍 What to Check

### 1. Session ID Consistency

Look for `Session ID:` in these places and verify they are IDENTICAL:

- Initial command: `ChatController: Session ID: kiosk-XXXXXXXXX`
- Variant detection: `Session ID will be: kiosk-XXXXXXXXX`
- Confirmation: `AiCommandService: Session ID: kiosk-XXXXXXXXX`

### 2. Queue Info Present

Check for:

```
Queue position: 1/2
Product: lux
Remaining: rice
```

### 3. Request Has All Fields

```
Full Request Body: {
  action: variant_selection,
  status: success,
  product_name: lux,
  variant_id: 123,
  session_id: kiosk-XXXXXXXXX
}
```

---

## 📋 Decision Tree

```
Is session_id CONSISTENT across all requests?
├─ NO → Frontend Issue (rare)
└─ YES → Continue

Is queue_info present in initial response?
├─ NO → Backend not sending queue_info
└─ YES → Continue

Does confirmation request have all fields?
├─ NO → Frontend Issue (rare)
└─ YES → Continue

Does backend respond with "no active queue found"?
├─ YES → BACKEND ISSUE (queue not maintained)
└─ NO → Check other errors
```

---

## 💡 Quick Fixes

### If session_id changes:

→ Check `chat_controller.dart` initialization → Verify `_currentSessionId` is
not being reset

### If queue_info missing:

→ Backend is not sending sequential queue format → Check backend response
structure

### If "no active queue found":

→ **BACKEND ISSUE** → Backend is not creating/maintaining queue → Share logs
with backend team

---

## 📸 Screenshot Checklist

When reporting issues, capture:

1. Console output from start to error
2. App UI showing the error message
3. Network tab showing the API request/response (if possible)

---

## 🎯 Test Scenarios

### Scenario 1: Two Products with Variants

```
Command: add lux and rice to cart
Expected: 2 sequential variant selections
```

### Scenario 2: Three Products with Variants

```
Command: add lux, rice and soap to cart
Expected: 3 sequential variant selections
```

### Scenario 3: Mixed (Some with variants, some without)

```
Command: add cola and lux to cart
Expected: Cola added directly, Lux shows variant selection
```

### Scenario 4: Cancel Sequential Selection

```
1. Start: add lux and rice to cart
2. Select Lux variant
3. Close Rice variant selection
Expected: Entire queue cancelled
```

---

## 📞 Support Information

If the error persists after this fix:

1. **Capture full console logs** from app start to error
2. **Note the timestamp** of each step
3. **Verify session_id consistency** in the logs
4. **Share with backend team** if session_id is consistent but backend returns
   error

---

## ⚡ Expected Timeline

| Action               | Expected Time |
| -------------------- | ------------- |
| User sends command   | 0s            |
| Backend processes    | 1-2s          |
| Variant UI appears   | 0.5s          |
| User selects variant | Variable      |
| Confirmation sent    | 0.1s          |
| Backend confirms     | 1-2s          |
| Next variant appears | 0.5s          |

**Total: ~5-10 seconds for 2 products**

If any step takes longer or fails, check the console logs for that specific
step.

---

## 🏁 Done!

You're now ready to test the sequential variant selection flow with
comprehensive debugging enabled!
