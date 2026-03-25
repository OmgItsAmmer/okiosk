# Voice Assistant Module - Quick Start

## Overview

The Voice Assistant module provides real-time voice-to-text transcription for
your Flutter app using AssemblyAI.

## Quick Setup (5 minutes)

### 1. Install Dependencies

```bash
flutter pub get
```

Dependencies are already added to `pubspec.yaml`:

- `flutter_sound: ^9.2.13`
- `permission_handler: ^11.0.0`
- `web_socket_channel: ^2.0.1`

### 2. Add Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice commands</string>
```

### 3. Start Backend

Make sure your Rust backend is running:

```bash
cd kks_online_backend
cargo run --release
```

Ensure `.env` contains:

```env
ASSEMBLYAI_API_KEY=your_key_here
```

### 4. Use in Your App

**Simple Usage:**

```dart
import 'package:get/get.dart';
import 'package:okiosk/features/voice_assistant/voice_assistant.dart';

// Initialize controller
final voiceController = Get.put(VoiceController());

// Use the widget
VoiceAssistantWidget(
  onTranscriptionComplete: () {
    final text = voiceController.getTranscriptionForAI();
    print('User said: $text');
  },
)
```

**Just a Button:**

```dart
VoiceButton(
  size: 64,
  onTranscriptionComplete: () {
    // Handle transcription
  },
)
```

## File Structure

```
lib/features/voice_assistant/
├── models/
│   ├── audio_config.dart          # Audio configuration
│   ├── transcription_response.dart # Response models
│   └── voice_state.dart           # State enum
├── services/
│   ├── voice_recording_service.dart # Audio recording
│   └── voice_websocket_service.dart # WebSocket communication
├── controller/
│   └── voice_controller.dart      # State management
├── widgets/
│   ├── voice_assistant_widget.dart # Full UI
│   └── voice_button.dart          # Simple button
├── voice_assistant.dart           # Module exports
└── example_usage.dart             # Examples
```

## Key Features

- ✅ **Real-time transcription** - See text as you speak
- ✅ **16kHz PCM audio** - Optimized for voice
- ✅ **WebSocket streaming** - Low latency
- ✅ **GetX state management** - Reactive UI
- ✅ **Error handling** - Automatic reconnection
- ✅ **Mute/unmute** - Control recording
- ✅ **Permission handling** - Automatic requests

## Common Use Cases

### 1. Add to Chat Interface

```dart
import 'package:okiosk/features/voice_assistant/voice_assistant.dart';

Row(
  children: [
    VoiceButton(onTranscriptionComplete: () {
      final text = Get.find<VoiceController>().getTranscriptionForAI();
      chatController.sendMessage(text);
    }),
    Expanded(child: TextField(...)),
    IconButton(icon: Icon(Icons.send)),
  ],
)
```

### 2. Add to POS System

```dart
Container(
  width: 300,
  child: VoiceAssistantWidget(
    onTranscriptionComplete: () {
      final command = voiceController.getTranscriptionForAI();
      _processVoiceCommand(command);
    },
  ),
)
```

### 3. Standalone Voice Screen

```dart
Scaffold(
  body: Center(
    child: VoiceAssistantWidget(
      showTranscription: true,
      compactMode: false,
    ),
  ),
)
```

## State Management

```dart
final controller = Get.find<VoiceController>();

// Observe state
Obx(() => Text(controller.voiceStateObs.value.toString()));

// Check if recording
if (controller.isRecording) { ... }

// Get transcription
String text = controller.currentTranscription;  // Live
String final = controller.finalTranscription;   // Complete
String forAI = controller.getTranscriptionForAI(); // Best
```

## Configuration

### Custom WebSocket URL

```dart
voiceController.setWebSocketUrl('ws://your-server:8080/ws/voice');
```

### Audio Settings

Edit `lib/features/voice_assistant/models/audio_config.dart`:

```dart
const AudioConfig({
  sampleRate: 16000,    // Hz
  numChannels: 1,       // Mono
  bitDepth: 16,         // 16-bit
  codec: 'pcm16',       // PCM
  bufferSize: 4096,     // Bytes
});
```

## Troubleshooting

### ❌ "Microphone permission denied"

- Check device settings → App permissions → Microphone
- On iOS, verify Info.plist has NSMicrophoneUsageDescription

### ❌ "WebSocket connection failed"

- Ensure backend is running: `cargo run`
- Check WebSocket URL: `ws://localhost:8080/ws/voice`
- Verify firewall allows connections

### ❌ "No audio recorded"

- Check microphone is working (test in other apps)
- Verify flutter_sound initialization
- Check device volume is not muted

### ❌ "Transcription not appearing"

- Check AssemblyAI API key in backend `.env`
- Verify internet connection
- Check backend logs for errors

## Examples

See `example_usage.dart` for complete examples:

- Basic voice assistant
- Simple voice button
- Voice-enabled chat
- POS integration
- Custom configuration

Run examples:

```dart
import 'package:okiosk/features/voice_assistant/example_usage.dart';

void main() {
  runApp(VoiceAssistantExampleApp());
}
```

## API Reference

### VoiceController

**Methods:**

- `startRecording()` - Start audio capture
- `stopRecording()` - Stop and finalize
- `toggleMute()` - Mute/unmute mic
- `clearTranscription()` - Clear text
- `getTranscriptionForAI()` - Get best text

**Properties:**

- `voiceState` - Current state
- `isRecording` - Boolean
- `currentTranscription` - Live text
- `finalTranscription` - Complete text
- `errorMessage` - Error if any
- `recordingDuration` - Seconds

### VoiceAssistantWidget

**Parameters:**

- `controller` - Optional controller
- `onTranscriptionComplete` - Callback
- `showTranscription` - Show text (default: true)
- `compactMode` - Minimal UI (default: false)

### VoiceButton

**Parameters:**

- `controller` - Optional controller
- `size` - Button size (default: 64)
- `activeColor` - Recording color
- `inactiveColor` - Idle color
- `onTranscriptionComplete` - Callback

## Performance Tips

1. **Lower latency**: Reduce `bufferSize` in `AudioConfig`
2. **Save bandwidth**: Only send audio when speaking (VAD)
3. **Cache controller**: Use `Get.find()` instead of creating new instances
4. **Close sessions**: Always stop recording when done

## Cost Optimization

AssemblyAI charges ~$0.01/minute. To reduce costs:

- Implement silence detection
- Set session timeouts
- Add usage limits
- Close inactive sessions

## Security

- ✅ API keys stored in backend only
- ✅ WebSocket over TLS in production
- ✅ Permission checks before recording
- ✅ No audio data logged

## Next Steps

1. ✅ Test basic functionality
2. ✅ Integrate with your AI system
3. ✅ Add voice commands parsing
4. ✅ Implement UI customization
5. ✅ Add error handling
6. ✅ Test on physical devices

## Support

- 📖 See `VOICE_TO_TEXT_INTEGRATION.md` for detailed docs
- 🔧 Check backend logs for debugging
- 🎯 Review `example_usage.dart` for patterns
- 📊 Monitor AssemblyAI usage in dashboard

---

**Quick Links:**

- AssemblyAI Dashboard: https://www.assemblyai.com/app
- Flutter Sound Docs: https://pub.dev/packages/flutter_sound
- GetX Docs: https://pub.dev/packages/get

**Made with ❤️ for AI Kiosk System**


| ?column?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CREATE TABLE realtime.messages_2026_01_08 (
  private boolean,
  extension text NOT NULL,
  payload jsonb,
  inserted_at timestamp without time zone NOT NULL,
  event text,
  topic text NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  id uuid NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE realtime.subscription (
  id bigint NOT NULL,
  filters ARRAY NOT NULL,
  created_at timestamp without time zone NOT NULL,
  entity regclass NOT NULL,
  action_filter text,
  claims_role regrole NOT NULL,
  claims jsonb NOT NULL,
  subscription_id uuid NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CREATE TABLE public.monthly_account_summary (
  entity_type character varying(20),
  total_amount numeric,
  transaction_type character varying(10),
  transaction_count bigint,
  month timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE auth.sessions (
  updated_at timestamp with time zone,
  id uuid NOT NULL,
  created_at timestamp with time zone,
  refresh_token_counter bigint,
  user_agent text,
  not_after timestamp with time zone,
  refreshed_at timestamp without time zone,
  aal USER-DEFINED,
  scopes text,
  refresh_token_hmac_key text,
  factor_id uuid,
  tag text,
  ip inet,
  oauth_client_id uuid,
  user_id uuid NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CREATE TABLE public.security_audit_log (
  log_id integer NOT NULL,
  timestamp timestamp with time zone,
  customer_id integer,
  event_data jsonb,
  severity character varying(20),
  user_agent text,
  ip_address inet,
  event_type character varying(100) NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE auth.flow_state (
  id uuid NOT NULL,
  linking_target_id uuid,
  code_challenge_method USER-DEFINED,
  created_at timestamp with time zone,
  provider_access_token text,
  auth_code text,
  referrer text,
  provider_refresh_token text,
  provider_type text NOT NULL,
  invite_token text,
  code_challenge text,
  oauth_client_state_id uuid,
  updated_at timestamp with time zone,
  auth_code_issued_at timestamp with time zone,
  user_id uuid,
  authentication_method text NOT NULL,
  email_optional boolean NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CREATE TABLE auth.sso_providers (
  disabled boolean,
  resource_id text,
  created_at timestamp with time zone,
  id uuid NOT NULL,
  updated_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CREATE TABLE extensions.pg_stat_statements (
  min_plan_time double precision,
  blk_write_time double precision,
  temp_blks_written bigint,
  jit_emission_count bigint,
  jit_optimization_time double precision,
  blk_read_time double precision,
  plans bigint,
  mean_exec_time double precision,
  local_blks_hit bigint,
  queryid bigint,
  jit_functions bigint,
  shared_blks_written bigint,
  userid oid,
  toplevel boolean,
  jit_emission_time double precision,
  wal_bytes numeric,
  min_exec_time double precision,
  max_plan_time double precision,
  total_plan_time double precision,
  shared_blks_read bigint,
  local_blks_written bigint,
  local_blks_dirtied bigint,
  temp_blks_read bigint,
  jit_inlining_time double precision,
  stddev_plan_time double precision,
  temp_blk_read_time double precision,
  wal_records bigint,
  stddev_exec_time double precision,
  rows bigint,
  calls bigint,
  mean_plan_time double precision,
  wal_fpi bigint,
  dbid oid,
  jit_optimization_count bigint,
  max_exec_time double precision,
  total_exec_time double precision,
  query text,
  shared_blks_dirtied bigint,
  jit_generation_time double precision,
  shared_blks_hit bigint,
  local_blks_read bigint,
  temp_blk_write_time double precision,
  jit_inlining_count bigint
);                                                                                         |
| CREATE TABLE extensions.pg_stat_statements_info (
  dealloc bigint,
  stats_reset timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CREATE TABLE public.customers (
  customer_id integer NOT NULL,
  cnic text,
  phone_number text,
  token_version integer,
  auth_uid character varying(255),
  fcm_token text,
  last_name text,
  created_at timestamp with time zone,
  gender USER-DEFINED,
  first_name text NOT NULL,
  dob timestamp with time zone,
  email text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE public.collection_items (
  collection_id integer NOT NULL,
  sort_order integer,
  created_at timestamp with time zone,
  variant_id integer NOT NULL,
  default_quantity integer NOT NULL,
  collection_item_id integer NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CREATE TABLE auth.audit_log_entries (
  ip_address character varying(64) NOT NULL,
  id uuid NOT NULL,
  payload json,
  created_at timestamp with time zone,
  instance_id uuid
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CREATE TABLE realtime.messages_2026_01_04 (
  topic text NOT NULL,
  event text,
  inserted_at timestamp without time zone NOT NULL,
  payload jsonb,
  id uuid NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  private boolean,
  extension text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE public.account_book (
  transaction_type character varying(10) NOT NULL,
  created_at timestamp with time zone,
  entity_type character varying(20) NOT NULL,
  updated_at timestamp with time zone,
  transaction_date date NOT NULL,
  description text NOT NULL,
  entity_id bigint NOT NULL,
  account_book_id bigint NOT NULL,
  entity_name character varying(255) NOT NULL,
  amount numeric NOT NULL,
  reference character varying(100)
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CREATE TABLE public.guarantors (
  guarantor_id integer NOT NULL,
  pfp text,
  last_name text,
  cnic text NOT NULL,
  first_name text NOT NULL,
  phone_number text,
  email text NOT NULL,
  address text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CREATE TABLE public.security_dashboard (
  unique_customers bigint,
  event_type character varying(100),
  severity character varying(20),
  date date,
  event_count bigint
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CREATE TABLE public.categories (
  category_id integer NOT NULL,
  created_at timestamp with time zone,
  isFeatured boolean,
  product_count integer,
  category_name text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CREATE TABLE auth.identities (
  user_id uuid NOT NULL,
  last_sign_in_at timestamp with time zone,
  created_at timestamp with time zone,
  email text,
  updated_at timestamp with time zone,
  id uuid NOT NULL,
  identity_data jsonb NOT NULL,
  provider_id text NOT NULL,
  provider text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE public.salesman (
  salesman_id integer NOT NULL,
  created_at timestamp with time zone,
  email text NOT NULL,
  comission integer,
  city text NOT NULL,
  area text NOT NULL,
  first_name text NOT NULL,
  phone_number text,
  cnic text NOT NULL,
  pfp text,
  last_name text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE public.cart (
  cart_id integer NOT NULL,
  quantity text NOT NULL,
  variant_id integer,
  customer_id integer
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CREATE TABLE public.product_variants (
  alert_stock bigint NOT NULL,
  sell_price numeric NOT NULL,
  stock integer,
  variant_name text NOT NULL,
  product_id integer NOT NULL,
  is_visible boolean,
  variant_id integer NOT NULL,
  buy_price numeric NOT NULL,
  sku character varying(255),
  created_at timestamp with time zone,
  updated_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CREATE TABLE auth.schema_migrations (
  version character varying(255) NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CREATE TABLE public.inventory_reservations (
  quantity integer NOT NULL,
  reservation_id character varying(255) NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  variant_id integer NOT NULL,
  created_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CREATE TABLE public.installment_payments (
  created_at timestamp without time zone,
  due_date timestamp with time zone NOT NULL,
  paid_date timestamp with time zone,
  sequence_no integer NOT NULL,
  is_paid boolean,
  amount_due text NOT NULL,
  status text,
  paid_amount text,
  installment_plan_id integer NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE public.order_items (
  price numeric NOT NULL,
  unit character varying(255),
  variant_id integer NOT NULL,
  total_buy_price numeric,
  product_id integer NOT NULL,
  order_id integer NOT NULL,
  created_at timestamp with time zone,
  quantity integer NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CREATE TABLE public.kiosk_cart (
  created_at timestamp without time zone,
  kiosk_session_id uuid NOT NULL,
  variant_id integer NOT NULL,
  kiosk_id integer NOT NULL,
  quantity integer NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CREATE TABLE auth.instances (
  uuid uuid,
  updated_at timestamp with time zone,
  raw_base_config text,
  created_at timestamp with time zone,
  id uuid NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CREATE TABLE public.reviews (
  review_id bigint NOT NULL,
  customer_id integer,
  review text,
  sent_at timestamp with time zone NOT NULL,
  product_id integer,
  rating numeric
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CREATE TABLE public.shop (
  shop_id integer NOT NULL,
  taxrate numeric NOT NULL,
  max_allowed_item_quantity bigint NOT NULL,
  shipping_price numeric NOT NULL,
  software_website_link text,
  software_contact_no text,
  software_company_name text,
  shopname text NOT NULL,
  is_shipping_enable boolean NOT NULL,
  threshold_free_shipping numeric
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CREATE TABLE public.invoice_coupons (
  amount numeric NOT NULL,
  title text NOT NULL,
  is_active boolean NOT NULL,
  created_at timestamp with time zone NOT NULL,
  used_count integer NOT NULL,
  end_date timestamp with time zone NOT NULL,
  coupon_code text NOT NULL,
  coupon_id integer NOT NULL,
  discount_type text NOT NULL,
  usage_limit integer,
  start_date timestamp with time zone NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CREATE TABLE public.products (
  sale_price text,
  isVisible boolean,
  base_price text,
  product_id integer NOT NULL,
  description text,
  alert_stock integer,
  category_id integer,
  stock_quantity integer,
  tag USER-DEFINED,
  ispopular boolean,
  created_at timestamp with time zone,
  name text NOT NULL,
  brandID integer,
  price_range text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CREATE TABLE realtime.schema_migrations (
  inserted_at timestamp without time zone,
  version bigint NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CREATE TABLE realtime.messages_2026_01_06 (
  extension text NOT NULL,
  private boolean,
  id uuid NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  topic text NOT NULL,
  event text,
  inserted_at timestamp without time zone NOT NULL,
  payload jsonb
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE public.installment_plans (
  installment_plans_id integer NOT NULL,
  total_amount text NOT NULL,
  number_of_installments text NOT NULL,
  duration text,
  order_id integer NOT NULL,
  guarantor1_id integer,
  created_at timestamp with time zone,
  status text,
  guarantor2_id integer,
  down_payment text NOT NULL,
  first_installment_date timestamp with time zone,
  other_charges text,
  note text,
  frequency_in_month text,
  document_charges text,
  margin text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CREATE TABLE vault.decrypted_secrets (
  decrypted_secret text,
  name text,
  description text,
  updated_at timestamp with time zone,
  nonce bytea,
  secret text,
  id uuid,
  key_id uuid,
  created_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CREATE TABLE auth.users (
  reauthentication_token character varying(255),
  raw_app_meta_data jsonb,
  is_sso_user boolean NOT NULL,
  recovery_token character varying(255),
  id uuid NOT NULL,
  deleted_at timestamp with time zone,
  confirmation_sent_at timestamp with time zone,
  recovery_sent_at timestamp with time zone,
  raw_user_meta_data jsonb,
  created_at timestamp with time zone,
  confirmed_at timestamp with time zone,
  phone_change_token character varying(255),
  phone_change_sent_at timestamp with time zone,
  is_super_admin boolean,
  phone_change text,
  reauthentication_sent_at timestamp with time zone,
  email_change_sent_at timestamp with time zone,
  updated_at timestamp with time zone,
  email character varying(255),
  email_change_token_new character varying(255),
  encrypted_password character varying(255),
  email_change_confirm_status smallint,
  email_change_token_current character varying(255),
  banned_until timestamp with time zone,
  invited_at timestamp with time zone,
  is_anonymous boolean NOT NULL,
  email_change character varying(255),
  aud character varying(255),
  email_confirmed_at timestamp with time zone,
  confirmation_token character varying(255),
  phone_confirmed_at timestamp with time zone,
  role character varying(255),
  last_sign_in_at timestamp with time zone,
  phone text,
  instance_id uuid
); |
| CREATE TABLE vault.secrets (
  secret text NOT NULL,
  id uuid NOT NULL,
  description text NOT NULL,
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  nonce bytea,
  key_id uuid,
  name text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CREATE TABLE realtime.messages_2026_01_05 (
  extension text NOT NULL,
  private boolean,
  id uuid NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  event text,
  topic text NOT NULL,
  payload jsonb,
  inserted_at timestamp without time zone NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE storage.migrations (
  name character varying(100) NOT NULL,
  executed_at timestamp without time zone,
  id integer NOT NULL,
  hash character varying(40) NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE public.app_versions (
  version text NOT NULL,
  description text,
  created_at timestamp with time zone,
  app_locked boolean NOT NULL,
  force_update boolean NOT NULL,
  id bigint NOT NULL,
  redirect_url text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE public.orders (
  paid_amount numeric,
  address_id integer,
  order_id integer NOT NULL,
  payment_method USER-DEFINED,
  status USER-DEFINED NOT NULL,
  buying_price numeric,
  sub_total numeric NOT NULL,
  customer_id integer,
  discount numeric,
  shipping_fee numeric,
  salesman_comission integer,
  order_date date NOT NULL,
  tax numeric,
  salesman_id integer,
  user_id integer,
  saletype text,
  idempotency_key character varying(255),
  shipping_method text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CREATE TABLE public.order_addresses (
  order_address_id integer NOT NULL,
  place_id text,
  city text,
  latitude numeric,
  user_id integer,
  shipping_address text,
  salesman_id integer,
  address_id integer,
  postal_code text,
  formatted_address text,
  longitude numeric,
  phone_number text,
  full_name text NOT NULL,
  vendor_id integer,
  customer_id integer,
  country text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CREATE TABLE pgsodium.mask_columns (
  key_id_column text,
  attname name,
  key_id text,
  format_type text,
  nonce_column text,
  associated_columns text,
  attrelid oid
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| CREATE TABLE public.image_entity (
  image_entity_id integer NOT NULL,
  created_at timestamp with time zone NOT NULL,
  image_id integer,
  entity_category text,
  entity_id integer,
  updated_at timestamp with time zone,
  isFeatured boolean
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CREATE TABLE public.collection_cart (
  collection_id integer NOT NULL,
  created_at timestamp with time zone,
  collection_cart_id integer NOT NULL,
  customer_id integer NOT NULL,
  updated_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CREATE TABLE auth.mfa_challenges (
  factor_id uuid NOT NULL,
  ip_address inet NOT NULL,
  otp_code text,
  created_at timestamp with time zone NOT NULL,
  web_authn_session_data jsonb,
  verified_at timestamp with time zone,
  id uuid NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CREATE TABLE net._http_response (
  headers jsonb,
  id bigint,
  content_type text,
  error_msg text,
  created timestamp with time zone NOT NULL,
  timed_out boolean,
  content text,
  status_code integer
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CREATE TABLE auth.saml_providers (
  entity_id text NOT NULL,
  created_at timestamp with time zone,
  name_id_format text,
  metadata_xml text NOT NULL,
  id uuid NOT NULL,
  attribute_mapping jsonb,
  updated_at timestamp with time zone,
  metadata_url text,
  sso_provider_id uuid NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| CREATE TABLE public.collections_summary (
  description text,
  created_at timestamp with time zone,
  is_premium boolean,
  image_url text,
  collection_id integer,
  is_featured boolean,
  display_order integer,
  is_active boolean,
  item_count bigint,
  updated_at timestamp with time zone,
  total_price numeric,
  name text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE public.expenses (
  expense_id integer NOT NULL,
  description text NOT NULL,
  created_at timestamp with time zone NOT NULL,
  amount numeric
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CREATE TABLE public.vendors (
  vendor_id integer NOT NULL,
  cnic text,
  phone_number text,
  first_name text NOT NULL,
  created_at timestamp with time zone,
  last_name text,
  email text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CREATE TABLE public.addresses (
  address_id integer NOT NULL,
  latitude numeric,
  shipping_address text,
  longitude numeric,
  full_name text NOT NULL,
  formatted_address text,
  place_id text,
  salesman_id integer,
  postal_code text,
  customer_id integer,
  city text,
  country text,
  vendor_id integer,
  phone_number text,
  user_id integer
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE storage.s3_multipart_uploads (
  id text NOT NULL,
  bucket_id text NOT NULL,
  user_metadata jsonb,
  owner_id text,
  upload_signature text NOT NULL,
  created_at timestamp with time zone NOT NULL,
  version text NOT NULL,
  key text NOT NULL,
  in_progress_size bigint NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CREATE TABLE auth.one_time_tokens (
  created_at timestamp without time zone NOT NULL,
  id uuid NOT NULL,
  token_hash text NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  token_type USER-DEFINED NOT NULL,
  user_id uuid NOT NULL,
  relates_to text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE supabase_migrations.schema_migrations (
  version text NOT NULL,
  created_by text,
  name text,
  rollback ARRAY,
  idempotency_key text,
  statements ARRAY
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CREATE TABLE storage.buckets_vectors (
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  id text NOT NULL,
  type USER-DEFINED NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CREATE TABLE auth.oauth_clients (
  client_uri text,
  grant_types text NOT NULL,
  registration_type USER-DEFINED NOT NULL,
  id uuid NOT NULL,
  token_endpoint_auth_method text NOT NULL,
  client_secret_hash text,
  client_name text,
  logo_uri text,
  updated_at timestamp with time zone NOT NULL,
  created_at timestamp with time zone NOT NULL,
  deleted_at timestamp with time zone,
  redirect_uris text NOT NULL,
  client_type USER-DEFINED NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CREATE TABLE auth.refresh_tokens (
  revoked boolean,
  id bigint NOT NULL,
  instance_id uuid,
  user_id character varying(255),
  session_id uuid,
  updated_at timestamp with time zone,
  token character varying(255),
  parent character varying(255),
  created_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| CREATE TABLE storage.buckets_analytics (
  id uuid NOT NULL,
  format text NOT NULL,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL,
  name text NOT NULL,
  type USER-DEFINED NOT NULL,
  updated_at timestamp with time zone NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CREATE TABLE auth.oauth_authorizations (
  approved_at timestamp with time zone,
  user_id uuid,
  id uuid NOT NULL,
  client_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL,
  code_challenge text,
  state text,
  resource text,
  scope text NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  authorization_code text,
  redirect_uri text NOT NULL,
  response_type USER-DEFINED NOT NULL,
  nonce text,
  code_challenge_method USER-DEFINED,
  status USER-DEFINED NOT NULL,
  authorization_id text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE realtime.messages_2026_01_07 (
  topic text NOT NULL,
  event text,
  inserted_at timestamp without time zone NOT NULL,
  payload jsonb,
  id uuid NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  private boolean,
  extension text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE public.purchase_items (
  price numeric NOT NULL,
  purchase_id bigint NOT NULL,
  purchase_item_id bigint NOT NULL,
  variant_id bigint,
  unit character varying(50),
  product_id bigint NOT NULL,
  created_at timestamp with time zone,
  quantity integer NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CREATE TABLE auth.oauth_consents (
  granted_at timestamp with time zone NOT NULL,
  user_id uuid NOT NULL,
  id uuid NOT NULL,
  scopes text NOT NULL,
  client_id uuid NOT NULL,
  revoked_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CREATE TABLE public.users (
  user_id integer NOT NULL,
  email text NOT NULL,
  first_name text NOT NULL,
  auth_uid character varying(255),
  last_name text,
  dob timestamp with time zone,
  gender USER-DEFINED,
  phone_number text,
  created_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE public.purchases (
  user_id integer,
  sub_total numeric NOT NULL,
  paid_amount numeric,
  discount numeric,
  status character varying(20) NOT NULL,
  purchase_id bigint NOT NULL,
  vendor_id bigint,
  address_id bigint,
  updated_at timestamp with time zone,
  shipping_fee numeric,
  purchase_date date NOT NULL,
  tax numeric,
  created_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CREATE TABLE storage.objects (
  metadata jsonb,
  updated_at timestamp with time zone,
  id uuid NOT NULL,
  owner uuid,
  path_tokens ARRAY,
  last_accessed_at timestamp with time zone,
  name text,
  user_metadata jsonb,
  version text,
  bucket_id text,
  owner_id text,
  created_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CREATE TABLE public.collections (
  collection_id integer NOT NULL,
  image_url text,
  display_order integer,
  updated_at timestamp with time zone,
  description text,
  created_at timestamp with time zone,
  is_featured boolean,
  is_active boolean,
  name text NOT NULL,
  is_premium boolean
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CREATE TABLE pgsodium.key (
  raw_key_nonce bytea,
  raw_key bytea,
  parent_key uuid,
  status USER-DEFINED,
  comment text,
  key_type USER-DEFINED,
  name text,
  key_id bigint,
  expires timestamp with time zone,
  id uuid NOT NULL,
  created timestamp with time zone NOT NULL,
  user_data text,
  associated_data text,
  key_context bytea
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CREATE TABLE net.http_request_queue (
  method text NOT NULL,
  body bytea,
  timeout_milliseconds integer NOT NULL,
  id bigint NOT NULL,
  headers jsonb NOT NULL,
  url text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CREATE TABLE auth.oauth_client_states (
  code_verifier text,
  created_at timestamp with time zone NOT NULL,
  id uuid NOT NULL,
  provider_type text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CREATE TABLE public.collection_items_detail (
  image_url text,
  sku character varying(255),
  sort_order integer,
  stock integer,
  sell_price numeric,
  is_visible boolean,
  collection_id integer,
  default_quantity integer,
  collection_item_id integer,
  variant_id integer,
  featured_image_id integer,
  variant_name text,
  product_name text,
  product_description text,
  product_id integer
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| CREATE TABLE public.account_book_summary (
  earliest_transaction date,
  min_amount numeric,
  total_amount numeric,
  entity_type character varying(20),
  transaction_count bigint,
  latest_transaction date,
  max_amount numeric,
  transaction_type character varying(10),
  average_amount numeric
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| CREATE TABLE auth.mfa_amr_claims (
  id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  authentication_method text NOT NULL,
  session_id uuid NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CREATE TABLE public.brands (
  brandID integer NOT NULL,
  product_count bigint NOT NULL,
  isVerified boolean,
  isFeatured boolean,
  brandname text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| CREATE TABLE storage.buckets (
  file_size_limit bigint,
  public boolean,
  created_at timestamp with time zone,
  id text NOT NULL,
  owner uuid,
  avif_autodetection boolean,
  allowed_mime_types ARRAY,
  type USER-DEFINED NOT NULL,
  name text NOT NULL,
  owner_id text,
  updated_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CREATE TABLE realtime.messages_2026_01_03 (
  updated_at timestamp without time zone NOT NULL,
  id uuid NOT NULL,
  inserted_at timestamp without time zone NOT NULL,
  payload jsonb,
  topic text NOT NULL,
  event text,
  extension text NOT NULL,
  private boolean
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE auth.sso_domains (
  updated_at timestamp with time zone,
  sso_provider_id uuid NOT NULL,
  domain text NOT NULL,
  id uuid NOT NULL,
  created_at timestamp with time zone
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE auth.saml_relay_states (
  created_at timestamp with time zone,
  flow_state_id uuid,
  request_id text NOT NULL,
  updated_at timestamp with time zone,
  for_email text,
  id uuid NOT NULL,
  sso_provider_id uuid NOT NULL,
  redirect_to text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CREATE TABLE public.customer_public_info (
  first_name text,
  last_name text,
  customer_id integer
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CREATE TABLE public.collection_cart_items (
  quantity integer NOT NULL,
  collection_cart_item_id integer NOT NULL,
  variant_id integer NOT NULL,
  created_at timestamp with time zone,
  collection_cart_id integer NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| CREATE TABLE pgsodium.valid_key (
  id uuid,
  key_type USER-DEFINED,
  associated_data text,
  created timestamp with time zone,
  status USER-DEFINED,
  expires timestamp with time zone,
  key_context bytea,
  key_id bigint,
  name text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CREATE TABLE public.images (
  image_id integer NOT NULL,
  folderType text,
  created_at timestamp with time zone,
  filename text,
  image_url text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CREATE TABLE public.extras (
  extraId bigint NOT NULL,
  AdminKey text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CREATE TABLE public.inventory_status (
  variant_id integer,
  total_stock integer,
  sell_price numeric,
  variant_name text,
  available_stock bigint,
  reserved_quantity bigint,
  product_name text
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| CREATE TABLE public.product_discounts (
  end_date timestamp with time zone NOT NULL,
  created_at timestamp with time zone NOT NULL,
  discount_type text NOT NULL,
  is_active boolean NOT NULL,
  amount numeric NOT NULL,
  discount_id integer NOT NULL,
  product_id integer NOT NULL,
  start_date timestamp with time zone NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| CREATE TABLE public.notifications (
  notification_id integer NOT NULL,
  created_at timestamp with time zone NOT NULL,
  product_id integer,
  isRead boolean,
  order_id integer,
  NotificationType text,
  sub_description text,
  description text,
  expires_at timestamp with time zone,
  installment_plan_id integer
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| CREATE TABLE storage.s3_multipart_uploads_parts (
  created_at timestamp with time zone NOT NULL,
  upload_id text NOT NULL,
  bucket_id text NOT NULL,
  key text NOT NULL,
  owner_id text,
  version text NOT NULL,
  etag text NOT NULL,
  size bigint NOT NULL,
  id uuid NOT NULL,
  part_number integer NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| CREATE TABLE pgsodium.masking_rule (
  format_type text,
  key_id_column text,
  relnamespace regnamespace,
  security_invoker boolean,
  key_id text,
  col_description text,
  relname name,
  attrelid oid,
  nonce_column text,
  associated_columns text,
  view_name text,
  attnum integer,
  priority integer,
  attname name
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| CREATE TABLE realtime.messages (
  extension text NOT NULL,
  private boolean,
  id uuid NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  topic text NOT NULL,
  event text,
  inserted_at timestamp without time zone NOT NULL,
  payload jsonb
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| CREATE TABLE public.wishlist (
  wishlist_id bigint NOT NULL,
  product_id integer,
  customer_id integer,
  created_at timestamp with time zone NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| CREATE TABLE storage.vector_indexes (
  name text NOT NULL,
  dimension integer NOT NULL,
  created_at timestamp with time zone NOT NULL,
  distance_metric text NOT NULL,
  id text NOT NULL,
  data_type text NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  metadata_configuration jsonb,
  bucket_id text NOT NULL
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| CREATE TABLE auth.mfa_factors (
  created_at timestamp with time zone NOT NULL,
  secret text,
  updated_at timestamp with time zone NOT NULL,
  phone text,
  friendly_name text,
  id uuid NOT NULL,
  factor_type USER-DEFINED NOT NULL,
  user_id uuid NOT NULL,
  last_challenged_at timestamp with time zone,
  web_authn_aaguid uuid,
  web_authn_credential jsonb,
  status USER-DEFINED NOT NULL,
  last_webauthn_challenge_data jsonb
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| CREATE TABLE pgsodium.decrypted_key (
  key_type USER-DEFINED,
  parent_key uuid,
  decrypted_raw_key bytea,
  status USER-DEFINED,
  raw_key bytea,
  raw_key_nonce bytea,
  expires timestamp with time zone,
  id uuid,
  comment text,
  created timestamp with time zone,
  key_context bytea,
  associated_data text,
  name text,
  key_id bigint
);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |