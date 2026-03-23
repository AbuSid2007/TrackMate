# TrackMate API — Endpoint Reference

Base URL: `http://localhost:8000`  
All endpoints are prefixed with `/api/v1`  
Authentication is cookie-based — cookies are set automatically on login/register and sent automatically by the browser/Dio client.

---

## Table of Contents
1. [Authentication](#1-authentication)
2. [Profile](#2-profile)
3. [Messaging — REST](#3-messaging--rest)
4. [Messaging — WebSocket](#4-messaging--websocket)

---

## 1. Authentication

### POST `/api/v1/auth/register`
Register a new account. Everyone registers as a trainee by default.  
Set `apply_as_trainer: true` to enter the trainer approval queue.  
Account is **inactive** until email is verified.

**Auth required:** No

**Request body:**
```json
{
  "email": "user@example.com",
  "password": "Password1",
  "full_name": "John Doe",
  "apply_as_trainer": false
}
```

**Validation:**
- `password` — minimum 8 characters, at least one uppercase letter, at least one digit
- `full_name` — minimum 2 characters
- `apply_as_trainer` — optional, defaults to `false`

**Response `201`:**
```json
{
  "message": "Account created. Please check your email to verify your account."
}
```

**Errors:**
- `409` — email already registered

**Side effects:** Sends a 6-digit OTP to the registered email. OTP expires in 10 minutes.

---

### POST `/api/v1/auth/verify-email`
Verify email with the OTP sent on registration. Activates the account.

**Auth required:** No

**Request body:**
```json
{
  "email": "user@example.com",
  "otp": "482910"
}
```

**Response `200`:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "trainee",
    "trainer_status": "none",
    "trainer_id": null,
    "is_active": true,
    "is_verified": true
  },
  "tokens": {
    "access_token": "...",
    "refresh_token": "...",
    "token_type": "bearer"
  }
}
```

**Notes:** Sets `access_token` and `refresh_token` cookies. User is logged in immediately after verification.

**Errors:**
- `401` — invalid or expired OTP
- `409` — email already verified

---

### POST `/api/v1/auth/resend-verification`
Resend a new OTP to the given email. Generates a fresh OTP and invalidates the old one.

**Auth required:** No

**Request body:**
```json
{
  "email": "user@example.com"
}
```

**Response `200`:**
```json
{
  "message": "Verification email sent"
}
```

**Errors:**
- `404` — user not found
- `409` — email already verified

---

### POST `/api/v1/auth/login`
Login with email and password. Role is derived from the database — do not send role from the client.

**Auth required:** No

**Request body:**
```json
{
  "email": "user@example.com",
  "password": "Password1"
}
```

**Response `200`:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "trainee",
    "trainer_status": "none",
    "trainer_id": null,
    "is_active": true,
    "is_verified": true
  },
  "tokens": {
    "access_token": "...",
    "refresh_token": "...",
    "token_type": "bearer"
  }
}
```

**Notes:** Sets `access_token` and `refresh_token` cookies.

**Errors:**
- `401` — invalid email or password
- `403` — account deactivated
- `403` — email not verified (a new OTP is automatically sent to the email)

---

### POST `/api/v1/auth/logout`
Logout the current user. Clears session cookies.

**Auth required:** Yes (cookie)

**Request body:** None

**Response `200`:**
```json
{
  "message": "Logged out successfully"
}
```

---

### POST `/api/v1/auth/refresh`
Refresh the access token using the refresh token cookie.

**Auth required:** Cookie (`refresh_token`)

**Request body:** None

**Response `200`:**
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "bearer"
}
```

**Notes:** Sets new `access_token` and `refresh_token` cookies. Called automatically by the Dio interceptor when a 401 is received.

**Errors:**
- `401` — refresh token missing, invalid, or expired

---

### GET `/api/v1/auth/me`
Get the currently authenticated user.

**Auth required:** Yes (cookie)

**Response `200`:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "trainee",
  "trainer_status": "none",
  "trainer_id": null,
  "is_active": true,
  "is_verified": true
}
```

---

### POST `/api/v1/auth/admin/trainer-applications`
Approve or reject a pending trainer application.

**Auth required:** Yes — Admin only

**Request body:**
```json
{
  "user_id": "uuid-of-applicant",
  "approve": true
}
```

Set `approve: false` to reject.

**Response `200`:** Returns the updated user object.

**Errors:**
- `403` — not an admin
- `404` — user not found
- `409` — user does not have a pending application

**Side effects:** Sends approval or rejection email to the applicant.

---

## 2. Profile

### GET `/api/v1/profile/me`
Get the full profile of the currently authenticated user including biometrics, goals, and calculated TDEE.

**Auth required:** Yes (cookie)

**Response `200`:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "trainee",
  "trainer_status": "none",
  "is_verified": true,
  "profile": {
    "id": "uuid",
    "user_id": "uuid",
    "profile_image_url": null,
    "bio": null,
    "date_of_birth": null,
    "gender": null,
    "height_cm": null,
    "weight_kg": null,
    "daily_step_goal": 10000,
    "daily_calorie_goal": null,
    "activity_level": null,
    "specializations": null,
    "experience_years": null,
    "tdee": null,
    "created_at": "2026-03-01T00:00:00Z",
    "updated_at": "2026-03-01T00:00:00Z"
  }
}
```

**Notes:** Profile is auto-created on first fetch if it doesn't exist. `tdee` is calculated server-side using the Mifflin-St Jeor formula — requires `height_cm`, `weight_kg`, `date_of_birth`, `gender`, and `activity_level` to be set.

---

### PUT `/api/v1/profile/me`
Update any profile field. Only include fields you want to change — all fields are optional.

**Auth required:** Yes (cookie)

**Request body (all fields optional):**
```json
{
  "bio": "Fitness enthusiast",
  "date_of_birth": "2000-01-15T00:00:00Z",
  "gender": "male",
  "height_cm": 175.0,
  "weight_kg": 70.0,
  "daily_step_goal": 12000,
  "daily_calorie_goal": 2500,
  "activity_level": "moderately_active",
  "specializations": "yoga,hiit",
  "experience_years": 3
}
```

**Enum values:**
- `gender`: `male`, `female`, `other`, `prefer_not_to_say`
- `activity_level`: `sedentary`, `lightly_active`, `moderately_active`, `very_active`, `extra_active`

**Validation:**
- `height_cm` — 50 to 300
- `weight_kg` — 20 to 500
- `daily_step_goal` — 1000 to 100000
- `daily_calorie_goal` — 500 to 10000

**Response `200`:** Returns updated `ProfileResponse` with calculated `tdee`.

---

### GET `/api/v1/profile/me/biometrics`
Get only the biometrics and goals portion of the profile.

**Auth required:** Yes (cookie)

**Response `200`:** Same as `ProfileResponse` above.

---

### PUT `/api/v1/profile/me/biometrics`
Update biometrics and goals. Same request body as `PUT /profile/me`.

**Auth required:** Yes (cookie)

**Response `200`:** Returns updated `ProfileResponse`.

---

### GET `/api/v1/profile/users/search`
Search for users by name or email to start a conversation with.

**Auth required:** Yes (cookie)

**Query params:**
- `q` (required, min 2 chars) — search term matched against `full_name` and `email`

**Example:** `GET /api/v1/profile/users/search?q=john`

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "email": "john@example.com",
    "full_name": "John Doe",
    "role": "trainee",
    "trainer_status": "none",
    "trainer_id": null,
    "is_active": true,
    "is_verified": true
  }
]
```

**Notes:** Returns max 20 results. Excludes the current user. Only returns active and verified users.

---

## 3. Messaging — REST

### POST `/api/v1/messaging/conversations`
Start a new direct conversation with another user, or return the existing one if it already exists.

**Auth required:** Yes (cookie)

**Request body:**
```json
{
  "other_user_id": "uuid-of-other-user"
}
```

**Response `201`:**
```json
{
  "conversation_id": "uuid",
  "other_user": {
    "id": "uuid",
    "full_name": "John Doe",
    "email": "john@example.com"
  }
}
```

**Errors:**
- `404` — user not found or not active/verified

---

### GET `/api/v1/messaging/conversations`
List all conversations for the current user, sorted by most recent message.

**Auth required:** Yes (cookie)

**Response `200`:**
```json
[
  {
    "conversation_id": "uuid",
    "other_user": {
      "id": "uuid",
      "full_name": "John Doe"
    },
    "last_message": {
      "content": "Hey there!",
      "sender_id": "uuid",
      "created_at": "2026-03-21T10:00:00Z",
      "status": "read"
    },
    "unread_count": 0,
    "created_at": "2026-03-01T00:00:00Z"
  }
]
```

---

### GET `/api/v1/messaging/conversations/{conversation_id}/messages`
Get paginated message history for a conversation. Returns oldest-first within the page.

**Auth required:** Yes (cookie)

**Query params:**
- `before` (optional) — ISO datetime, fetch messages before this timestamp (for pagination)
- `limit` (optional, default 50, max 100) — number of messages to return

**Example:** `GET /api/v1/messaging/conversations/{id}/messages?limit=50`  
**Paginate:** `GET /api/v1/messaging/conversations/{id}/messages?before=2026-03-21T10:00:00Z&limit=50`

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "conversation_id": "uuid",
    "sender_id": "uuid",
    "content": "Hello!",
    "status": "read",
    "is_deleted": false,
    "created_at": "2026-03-21T10:00:00Z"
  }
]
```

**Errors:**
- `403` — not a member of this conversation
- `404` — conversation not found

---

### PUT `/api/v1/messaging/conversations/{conversation_id}/read`
Mark all messages in a conversation as read and notify the other user via WebSocket.

**Auth required:** Yes (cookie)

**Request body:** None

**Response `200`:**
```json
{
  "message": "Marked as read"
}
```

**Side effects:** If the other user is online, they receive a `messages_read` WebSocket event.

---

### DELETE `/api/v1/messaging/messages/{message_id}`
Soft delete a message. Content is cleared, `is_deleted` is set to `true`.

**Auth required:** Yes (cookie) — must be the message sender

**Response `200`:**
```json
{
  "message": "Deleted",
  "message_id": "uuid"
}
```

**Errors:**
- `403` — not the sender
- `404` — message not found

---

### GET `/api/v1/messaging/users/{user_id}/presence`
Get the online status and last seen time of a user.

**Auth required:** Yes (cookie)

**Response `200`:**
```json
{
  "user_id": "uuid",
  "online": true,
  "last_seen": "2026-03-21T10:00:00Z"
}
```

---

### POST `/api/v1/messaging/ws-ticket`
Get a one-time WebSocket authentication ticket. The ticket is valid for 30 seconds and can only be used once.

**Auth required:** Yes (cookie)

**Request body:** None

**Response `200`:**
```json
{
  "ticket": "random-secure-string"
}
```

**Usage:** Call this immediately before opening a WebSocket connection. Pass the ticket as a query param to the WebSocket URL.

---

## 4. Messaging — WebSocket

### WS `/api/v1/messaging/ws?ticket={ticket}`

Open a persistent WebSocket connection for real-time messaging.

**Authentication:** Pass the ticket obtained from `POST /messaging/ws-ticket` as a query param.  
Tickets are single-use and expire in 30 seconds.

**Connection flow:**
1. Call `POST /api/v1/messaging/ws-ticket` to get a ticket
2. Connect to `ws://localhost:8000/api/v1/messaging/ws?ticket=YOUR_TICKET`
3. On connect, the server pushes an `unread_summary` event if there are unread messages
4. Send a `heartbeat` every 30 seconds to maintain presence

---

### Client → Server Messages

All messages are JSON objects with a `type` field.

#### `send_message`
Send a text message to a conversation.

```json
{
  "type": "send_message",
  "conversation_id": "uuid",
  "content": "Hello!"
}
```

#### `mark_read`
Mark all messages in a conversation as read.

```json
{
  "type": "mark_read",
  "conversation_id": "uuid"
}
```

#### `typing`
Notify the other user that you are typing. Expires automatically after 5 seconds — send repeatedly while typing.

```json
{
  "type": "typing",
  "conversation_id": "uuid"
}
```

#### `heartbeat`
Keep the connection alive and refresh presence TTL. Send every 30 seconds.

```json
{
  "type": "heartbeat"
}
```

---

### Server → Client Events

#### `new_message`
Received when a new message arrives or when your sent message is confirmed.

```json
{
  "type": "new_message",
  "message": {
    "id": "uuid",
    "conversation_id": "uuid",
    "sender_id": "uuid",
    "content": "Hello!",
    "status": "delivered",
    "created_at": "2026-03-21T10:00:00Z"
  }
}
```

**Status values:** `sent` → `delivered` → `read`

#### `messages_read`
Received when the other user reads your messages.

```json
{
  "type": "messages_read",
  "conversation_id": "uuid",
  "read_by": "uuid"
}
```

#### `typing`
Received when the other user is typing.

```json
{
  "type": "typing",
  "conversation_id": "uuid",
  "user_id": "uuid"
}
```

#### `heartbeat_ack`
Confirmation of a heartbeat.

```json
{
  "type": "heartbeat_ack"
}
```

#### `unread_summary`
Pushed on connection if there are unread messages. Use this to fetch missed messages.

```json
{
  "type": "unread_summary",
  "conversations": [
    {
      "conversation_id": "uuid",
      "unread_count": 3
    }
  ]
}
```

**On receiving this:** Call `GET /messaging/conversations/{id}/messages` for each conversation listed, then send `mark_read` after displaying them.

#### `user_online`
Received when a user in your contact list comes online.

```json
{
  "type": "user_online",
  "user_id": "uuid"
}
```

#### `user_offline`
Received when a user in your contact list goes offline.

```json
{
  "type": "user_offline",
  "user_id": "uuid"
}
```

#### `error`
Received when a client message causes a server-side error.

```json
{
  "type": "error",
  "message": "You are not a member of this conversation"
}
```

---

## WebSocket Close Codes

| Code | Reason |
|------|--------|
| `4001` | Invalid or expired ticket |
| `4001` | User not found or inactive |

---

## Integration Notes

### Flutter / Dio
- Cookies are managed automatically by `dio_cookie_manager` on mobile
- On web, the browser handles cookies — set `withCredentials: true` in Dio options
- The Dio interceptor automatically calls `/auth/refresh` on 401 responses and retries the original request
- For WebSocket in Flutter, use the `web_socket_channel` package:

```dart
// 1. Get ticket
final ticketResponse = await dio.post('/messaging/ws-ticket');
final ticket = ticketResponse.data['ticket'];

// 2. Connect
final channel = WebSocketChannel.connect(
  Uri.parse('ws://localhost:8000/api/v1/messaging/ws?ticket=$ticket'),
);

// 3. Listen
channel.stream.listen((message) {
  final data = jsonDecode(message);
  // handle data['type']
});

// 4. Send
channel.sink.add(jsonEncode({
  'type': 'send_message',
  'conversation_id': conversationId,
  'content': 'Hello!',
}));

// 5. Heartbeat every 30 seconds
Timer.periodic(Duration(seconds: 30), (_) {
  channel.sink.add(jsonEncode({'type': 'heartbeat'}));
});
```

### Typical Message Flow
```
User A opens chat with User B
  → POST /messaging/conversations          (get or create conversation)
  → GET  /messaging/conversations/{id}/messages  (load history)
  → POST /messaging/ws-ticket             (get ticket)
  → WS   /messaging/ws?ticket=...         (connect)

User A types
  → send: {"type": "typing", "conversation_id": "..."}

User A sends message
  → send: {"type": "send_message", "conversation_id": "...", "content": "Hello!"}
  ← recv: {"type": "new_message", "message": {..., "status": "delivered"}}  (if B online)

User B receives message (if online)
  ← recv: {"type": "new_message", ...}

User B reads message
  → send: {"type": "mark_read", "conversation_id": "..."}
  User A ← recv: {"type": "messages_read", "conversation_id": "...", "read_by": "..."}

User B was offline, comes back online
  ← recv: {"type": "unread_summary", "conversations": [...]}
  → GET  /messaging/conversations/{id}/messages  (fetch missed messages)
  → send: {"type": "mark_read", "conversation_id": "..."}
```
