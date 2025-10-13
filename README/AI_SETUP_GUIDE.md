# AI Module Setup Guide

## Quick Start

### 1. Get Google Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Get API Key" or "Create API Key"
4. Copy your API key

### 2. Configure Environment Variables

Add the following to your `.env` file:

```bash
# Google Gemini Pro API Key (Required for AI features)
GEMINI_API_KEY=your-api-key-here

# Existing configuration
DATABASE_URL=your-database-url
PORT=3000
HOST=0.0.0.0
```

### 3. Install Dependencies

The AI module requires the following Rust crates (already added to
`Cargo.toml`):

```toml
reqwest = { version = "0.11", features = ["json", "rustls-tls"] }
async-trait = "0.1"
```

Run:

```bash
cargo build
```

### 4. Start the Server

```bash
cargo run
```

You should see:

```
✅ Configuration loaded successfully
✅ Database connected successfully
✅ AI Service initialized successfully
🚀 Server starting on 0.0.0.0:3000
```

## Testing the AI Module

### Using cURL

#### Example 1: Add items to cart

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "add 2 zinger burger to cart",
    "session_id": "test-session-123"
  }'
```

#### Example 2: Add items and checkout (Urdu + English)

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "3 pizza aur 2 coke add karo aur bill bana do",
    "session_id": "test-session-123"
  }'
```

#### Example 3: View cart

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "cart dikha do",
    "session_id": "test-session-123"
  }'
```

#### Example 4: Clear cart

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "cart khali kar do",
    "session_id": "test-session-123"
  }'
```

### Using Postman

1. Create a new POST request
2. URL: `http://localhost:3000/api/ai/command`
3. Headers:
   - `Content-Type: application/json`
4. Body (raw JSON):

```json
{
    "prompt": "add 2 burger and show cart",
    "session_id": "postman-test-123"
}
```

5. Click "Send"

### Expected Response

**Success:**

```json
{
    "success": true,
    "message": "Added 2 Burgers to your cart and displayed the cart.",
    "actions_executed": [
        "Added 2 burger to cart",
        "Cart contains 2 items"
    ],
    "error": null
}
```

**Error:**

```json
{
    "success": false,
    "message": "Product 'xyz' not found",
    "actions_executed": [],
    "error": "Product 'xyz' not found"
}
```

## Supported Commands

### English Commands

| Command          | Example                   | Action                 |
| ---------------- | ------------------------- | ---------------------- |
| Add to cart      | "add 2 burger to cart"    | Adds item to cart      |
| Remove from cart | "remove burger from cart" | Removes item from cart |
| Clear cart       | "clear cart"              | Empties the cart       |
| Generate bill    | "generate bill"           | Shows bill/checkout    |
| Show menu        | "show menu"               | Displays menu          |
| Search product   | "find pizza"              | Searches for products  |
| View cart        | "show cart"               | Shows cart contents    |

### Urdu/Mixed Commands

| Command       | Example               | Action         |
| ------------- | --------------------- | -------------- |
| Add karo      | "2 burger add karo"   | Adds to cart   |
| Bill bana do  | "bill bana do"        | Generate bill  |
| Cart dikha do | "cart dikha do"       | Show cart      |
| Khali kar do  | "cart khali kar do"   | Clear cart     |
| Menu dikhao   | "menu dikhao"         | Show menu      |
| Search karo   | "burger search karo"  | Search product |
| Aur (and)     | "2 burger aur 1 coke" | Multiple items |

## Client Integration Examples

### Flutter

```dart
// See AI_MODULE.md for complete Flutter integration example
class AiCommandService {
  Future<AiCommandResponse> processCommand({
    required String prompt,
    String? sessionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'session_id': sessionId,
      }),
    );
    return AiCommandResponse.fromJson(jsonDecode(response.body));
  }
}
```

### React/JavaScript

```javascript
// See AI_MODULE.md for complete JavaScript integration example
async function processCommand(prompt, sessionId) {
    const response = await fetch("/api/ai/command", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt, session_id: sessionId }),
    });
    return await response.json();
}
```

## Troubleshooting

### Error: "GEMINI_API_KEY must be set"

**Solution:**

1. Make sure you have a `.env` file in the project root
2. Add `GEMINI_API_KEY=your-key` to the `.env` file
3. Restart the server

### Error: "Failed to call Gemini API"

**Possible causes:**

1. Invalid API key
2. No internet connection
3. API quota exceeded
4. API service is down

**Solution:**

1. Verify your API key is correct
2. Check internet connection
3. Check [API quota limits](https://ai.google.dev/pricing)
4. Check [Google AI status](https://status.cloud.google.com/)

### Error: "Product not found"

**Cause:** The product name doesn't match any products in your database.

**Solution:**

1. Use exact or similar product names
2. Check your product database
3. The AI will search for close matches

### Commands not working in Urdu

**Solution:**

1. Ensure your HTTP client supports UTF-8 encoding
2. Use proper Urdu transliteration
3. Supported words: karo, kar do, bana do, dikha do, dikhao, aur, se, etc.

## API Rate Limits

Google Gemini Pro API has the following limits (as of 2024):

- **Free tier:** 60 requests per minute
- **Rate limit errors:** HTTP 429 Too Many Requests

**Recommendations:**

1. Implement client-side throttling (1 request per second)
2. Cache common responses
3. Provide quick-action buttons for common commands
4. Consider upgrading to paid tier for production

## Security Best Practices

1. ✅ Never expose `GEMINI_API_KEY` to the client
2. ✅ The API key is only used server-side
3. ✅ All database operations use existing security measures
4. ✅ Validate and sanitize user inputs
5. ✅ Consider implementing rate limiting on your API endpoint

## Architecture Overview

```
User Input (Voice/Text)
    ↓
Frontend (Flutter/React/etc.)
    ↓
POST /api/ai/command
    ↓
AI Handler (ai_handlers.rs)
    ↓
AI Service (ai_service.rs)
    ↓
Google Gemini Pro API
    ↓
Structured JSON Commands
    ↓
Command Executor (command_executor.rs)
    ↓
Database Operations
    ↓
Response to User
```

## Files Structure

```
src/
├── models/
│   └── ai.rs                    # AI data models
├── services/
│   ├── ai_service.rs            # Gemini API communication
│   └── command_executor.rs      # Command execution logic
├── handlers/
│   └── ai_handlers.rs           # HTTP endpoint handler
└── main.rs                      # AI router setup

AI_MODULE.md                     # Complete documentation
AI_SETUP_GUIDE.md               # This file
```

## Performance Considerations

- **Gemini API latency:** ~1-3 seconds per request
- **Recommendation:** Show loading indicator to users
- **Optimization:** Cache product searches for better UX
- **Fallback:** Provide quick-action buttons alongside voice input

## Next Steps

1. ✅ Configure `GEMINI_API_KEY` in `.env`
2. ✅ Test with cURL or Postman
3. ✅ Integrate with your frontend (Flutter/React/etc.)
4. ✅ Add voice input (Speech-to-Text) on client side
5. ✅ Implement rate limiting for production
6. ✅ Monitor API usage and costs

## Support

- **Documentation:** See `AI_MODULE.md` for complete API reference
- **Examples:** Check `AI_MODULE.md` for client integration examples
- **Issues:** Review server logs for detailed error messages

## Production Checklist

- [ ] Add `GEMINI_API_KEY` to production environment variables
- [ ] Implement rate limiting on `/api/ai/command` endpoint
- [ ] Add monitoring and logging for AI requests
- [ ] Set up alerts for API errors
- [ ] Consider caching for common queries
- [ ] Test with real product names from your database
- [ ] Implement fallback UI for when AI is unavailable
- [ ] Monitor API costs and usage

---

**Version:** 1.0.0\
**Last Updated:** October 2025
