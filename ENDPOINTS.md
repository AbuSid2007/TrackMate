# TrackMate API — Endpoint Reference

Base URL: `http://localhost:8000`
All endpoints are prefixed with `/api/v1`
Authentication is cookie-based — cookies are set automatically on login/verify and sent automatically by the browser/Dio client.

---

## Table of Contents
1. [Authentication](#1-authentication)
2. [Profile](#2-profile)
3. [Trainer](#3-trainer)
4. [Admin](#4-admin)
5. [Messaging — REST](#5-messaging--rest)
6. [Messaging — WebSocket](#6-messaging--websocket)
7. [Social](#7-social)
8. [Notifications](#8-notifications)
9. [Fitness](#9-fitness)

---

## 1. Authentication

### POST `/api/v1/auth/register`
Register a new account. Everyone registers as trainee by default. Account is **inactive** until email is verified.

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
- `password` — min 8 chars, at least one uppercase, at least one digit
- `full_name` — min 2 chars
- `apply_as_trainer` — optional, defaults to `false`. Set to `true` to enter trainer approval queue after account is verified.

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
Verify email with the OTP. Activates the account and logs the user in.

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

**Notes:** Sets `access_token` and `refresh_token` httponly cookies. User is logged in immediately.

**Errors:**
- `401` — invalid or expired OTP
- `409` — email already verified

---

### POST `/api/v1/auth/resend-verification`
Resend a new OTP. Generates a fresh code and invalidates the previous one.

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
- `403` — email not verified (a new OTP is automatically sent)

---

### POST `/api/v1/auth/logout`
Logout. Clears session cookies.

**Auth required:** Yes

**Request body:** None

**Response `200`:**
```json
{
  "message": "Logged out successfully"
}
```

---

### POST `/api/v1/auth/refresh`
Refresh the access token using the refresh token cookie. Called automatically by the Dio interceptor on 401.

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

**Errors:**
- `401` — refresh token missing, invalid, or expired

---

### GET `/api/v1/auth/me`
Get the currently authenticated user.

**Auth required:** Yes

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

## 2. Profile

### GET `/api/v1/profile/me`
Get the full profile of the current user including biometrics, goals, and calculated TDEE.

**Auth required:** Yes

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
    "phone_number": null,
    "hourly_rate": null,
    "tdee": null,
    "created_at": "2026-03-01T00:00:00Z",
    "updated_at": "2026-03-01T00:00:00Z"
  }
}
```

**Notes:** Profile is auto-created on first fetch. `tdee` requires `height_cm`, `weight_kg`, `date_of_birth`, `gender`, and `activity_level` to be set — calculated using the Mifflin-St Jeor formula.

---

### PUT `/api/v1/profile/me`
Update any profile field. All fields are optional — only include what you want to change.

**Auth required:** Yes

**Request body (all optional):**
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
  "experience_years": 3,
  "phone_number": "+91-9999999999",
  "hourly_rate": 500.0
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

**Response `200`:** Returns updated `ProfileResponse` with recalculated `tdee`.

---

### GET `/api/v1/profile/me/biometrics`
Get biometrics and goals only.

**Auth required:** Yes

**Response `200`:** Same as `ProfileResponse` above.

---

### PUT `/api/v1/profile/me/biometrics`
Update biometrics and goals. Same request body as `PUT /profile/me`.

**Auth required:** Yes

**Response `200`:** Returns updated `ProfileResponse`.

---

### GET `/api/v1/profile/users/search`
Search for users by name or email.

**Auth required:** Yes

**Query params:**
- `q` (required, min 2 chars) — matched against `full_name` and `email`

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

**Notes:** Returns max 20 results. Excludes current user. Only active and verified users.

---

## 3. Trainer

### POST `/api/v1/trainer/apply`
Submit a trainer application. Only available to trainees. Creates a pending application and updates profile with phone number, hourly rate, and specializations.

**Auth required:** Yes

**Request body (all optional):**
```json
{
  "phone_number": "+91-9999999999",
  "experience_years": 3,
  "about": "Certified personal trainer with 3 years experience",
  "specializations": "strength,hiit,yoga",
  "certifications": "ACE,NASM",
  "hourly_rate": 500.0
}
```

**Response `201`:**
```json
{
  "application_id": "uuid",
  "status": "pending"
}
```

**Errors:**
- `409` — application already submitted

---

### GET `/api/v1/trainer/available`
Browse all approved trainers with their profile info.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "full_name": "Jane Smith",
    "email": "jane@example.com",
    "profile_image_url": null,
    "specializations": "strength,hiit",
    "experience_years": 3,
    "hourly_rate": 500.0,
    "bio": "Certified trainer"
  }
]
```

---

### POST `/api/v1/trainer/request`
Send a request to a trainer. Trainee must not already have a trainer.

**Auth required:** Yes

**Request body:**
```json
{
  "trainer_id": "uuid",
  "goal": "I want to lose 10kg and build core strength"
}
```

**Response `201`:**
```json
{
  "request_id": "uuid",
  "status": "pending"
}
```

**Errors:**
- `404` — trainer not found
- `409` — already have a trainer or request already pending

**Side effects:** Sends a notification to the trainer.

---

### GET `/api/v1/trainer/my-trainer`
Get the current user's assigned trainer.

**Auth required:** Yes

**Response `200`:**
```json
{
  "trainer": {
    "id": "uuid",
    "full_name": "Jane Smith",
    "email": "jane@example.com"
  }
}
```

Returns `{"trainer": null}` if no trainer assigned.

---

### GET `/api/v1/trainer/my-sessions`
Get the current trainee's scheduled sessions from their trainer.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "trainer": {
      "id": "uuid",
      "full_name": "Jane Smith"
    },
    "scheduled_at": "2026-03-25T10:00:00Z",
    "duration_minutes": 60,
    "notes": "Focus on upper body"
  }
]
```

---

### GET `/api/v1/trainer/students`
List all students assigned to the current trainer with adherence stats.

**Auth required:** Trainer only

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "full_name": "John Doe",
    "email": "john@example.com",
    "profile_image_url": null,
    "adherence": 82,
    "workout_score": 75,
    "streak": 7,
    "excellence_pct": 78.5,
    "needs_attention": false
  }
]
```

---

### GET `/api/v1/trainer/students/{trainee_id}`
Get detailed view of a specific student including notes.

**Auth required:** Trainer only

**Response `200`:** Same as student summary above plus:
```json
{
  "notes": [
    {
      "id": "uuid",
      "content": "Great progress this week",
      "created_at": "2026-03-21T10:00:00Z"
    }
  ]
}
```

**Errors:**
- `404` — student not found or not assigned to this trainer

---

### POST `/api/v1/trainer/students/{trainee_id}/notes`
Add a coaching note to a student's profile.

**Auth required:** Trainer only

**Request body:**
```json
{
  "content": "Focus on form over weight this week"
}
```

**Response `201`:**
```json
{
  "note_id": "uuid",
  "content": "Focus on form over weight this week",
  "created_at": "2026-03-21T10:00:00Z"
}
```

---

### GET `/api/v1/trainer/students/{trainee_id}/workouts`
View a student's workout history.

**Auth required:** Trainer only

**Query params:**
- `limit` (optional, default 20, max 100)

**Response `200`:** List of workout sessions with sets. Same format as `GET /fitness/workouts/sessions`.

---

### GET `/api/v1/trainer/students/{trainee_id}/nutrition`
View a student's nutrition logs for a specific date.

**Auth required:** Trainer only

**Query params:**
- `date` (optional, ISO datetime, defaults to today)

**Response `200`:**
```json
{
  "summary": {
    "date": "2026-03-23",
    "total_calories": 1850.5,
    "total_protein_g": 142.0,
    "total_carbs_g": 210.5,
    "total_fat_g": 55.0,
    "meal_count": 3
  },
  "meals": [
    {
      "id": "uuid",
      "food_name": "Chicken Breast",
      "servings": 2.0,
      "calories": 330.0,
      "protein_g": 62.0,
      "logged_at": "2026-03-23T12:00:00Z"
    }
  ]
}
```

---

### GET `/api/v1/trainer/students/{trainee_id}/stats`
View a student's fitness stats — weekly summary, streak, step history, weight trend.

**Auth required:** Trainer only

**Response `200`:**
```json
{
  "weekly": {
    "workouts_completed": 4,
    "calories_burned": 1200.0,
    "total_steps": 52000,
    "step_goal_days_met": 5,
    "streak_days": 7
  },
  "streak_days": 7,
  "steps_history": [
    {"date": "2026-03-17", "steps": 8500}
  ],
  "weight_trend": [
    {"date": "2026-03-01", "weight_kg": 72.5}
  ]
}
```

---

### GET `/api/v1/trainer/stats`
Get the trainer's dashboard statistics.

**Auth required:** Trainer only

**Response `200`:**
```json
{
  "total_students": 8,
  "avg_adherence": 76.5,
  "needs_attention": 2
}
```

---

### GET `/api/v1/trainer/requests`
List pending trainee requests.

**Auth required:** Trainer only

**Response `200`:**
```json
[
  {
    "request_id": "uuid",
    "trainee": {
      "id": "uuid",
      "full_name": "John Doe"
    },
    "goal": "Lose 10kg",
    "status": "pending",
    "created_at": "2026-03-21T10:00:00Z"
  }
]
```

---

### PUT `/api/v1/trainer/requests/{request_id}`
Accept or reject a trainee request.

**Auth required:** Trainer only

**Request body:**
```json
{
  "accept": true
}
```

**Response `200`:**
```json
{
  "request_id": "uuid",
  "status": "accepted"
}
```

**Side effects:** On accept, sets `trainer_id` on the trainee and sends a notification.

---

### GET `/api/v1/trainer/calendar`
Get scheduled sessions for the trainer ordered by date.

**Auth required:** Trainer only

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "trainee": {
      "id": "uuid",
      "full_name": "John Doe"
    },
    "scheduled_at": "2026-03-25T10:00:00Z",
    "duration_minutes": 60,
    "notes": "Upper body focus"
  }
]
```

---

### POST `/api/v1/trainer/calendar/sessions`
Schedule a training session with a student.

**Auth required:** Trainer only

**Request body:**
```json
{
  "trainee_id": "uuid",
  "scheduled_at": "2026-03-25T10:00:00Z",
  "duration_minutes": 60,
  "notes": "Upper body focus"
}
```

**Response `201`:**
```json
{
  "session_id": "uuid",
  "scheduled_at": "2026-03-25T10:00:00Z",
  "duration_minutes": 60
}
```

**Errors:**
- `403` — trainee is not assigned to this trainer

---

## 4. Admin

### GET `/api/v1/admin/stats`
Get platform-wide statistics.

**Auth required:** Admin only

**Response `200`:**
```json
{
  "total_users": 2847,
  "active_trainers": 124,
  "active_sessions": 38,
  "pending_reports": 5,
  "pending_trainer_applications": 12,
  "growth_rate_pct": 4.7
}
```

**Notes:** `active_sessions` is the number of users currently connected via WebSocket. `growth_rate_pct` is a simulated value until real analytics are implemented.

---

### GET `/api/v1/admin/users`
List all users with optional role filter and pagination.

**Auth required:** Admin only

**Query params:**
- `role` (optional) — filter by `trainee`, `trainer`, or `admin`
- `page` (optional, default 1)
- `limit` (optional, default 20, max 100)

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "trainee",
    "trainer_status": "none",
    "is_active": true,
    "is_verified": true,
    "created_at": "2026-03-01T00:00:00Z"
  }
]
```

---

### GET `/api/v1/admin/users/{user_id}`
Get a specific user's full detail including profile.

**Auth required:** Admin only

**Response `200`:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "trainee",
  "trainer_status": "none",
  "is_active": true,
  "is_verified": true,
  "created_at": "2026-03-01T00:00:00Z",
  "profile": {
    "bio": null,
    "height_cm": 175.0,
    "weight_kg": 70.0
  }
}
```

---

### PUT `/api/v1/admin/users/{user_id}/deactivate`
Deactivate a user account. Deactivated users cannot log in.

**Auth required:** Admin only

**Request body:** None

**Response `200`:**
```json
{
  "message": "John Doe deactivated"
}
```

---

### PUT `/api/v1/admin/users/{user_id}/activate`
Reactivate a deactivated user account.

**Auth required:** Admin only

**Request body:** None

**Response `200`:**
```json
{
  "message": "John Doe activated"
}
```

---

### GET `/api/v1/admin/trainer-applications`
List trainer applications with optional status filter.

**Auth required:** Admin only

**Query params:**
- `status` (optional) — `pending`, `approved`, or `rejected`

**Response `200`:**
```json
{
  "summary": {
    "total": 45,
    "pending": 12,
    "approved": 30
  },
  "applications": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "full_name": "Jane Smith",
      "email": "jane@example.com",
      "profile_image_url": null,
      "phone_number": "+91-9999999999",
      "experience_years": 3,
      "about": "Certified trainer",
      "specializations": "strength,hiit",
      "certifications": "ACE,NASM",
      "hourly_rate": 500.0,
      "status": "pending",
      "submitted_at": "2026-03-20T10:00:00Z",
      "reviewed_at": null
    }
  ]
}
```

---

### POST `/api/v1/admin/trainer-applications/{user_id}/approve`
Approve or reject a trainer application.

**Auth required:** Admin only

**Request body:**
```json
{
  "user_id": "uuid",
  "approve": true
}
```

Set `approve: false` to reject.

**Response `200`:** Returns updated user object.

**Side effects:** Sends approval or rejection email to the applicant.

---

### GET `/api/v1/admin/reports`
List all user reports with optional status filter.

**Auth required:** Admin only

**Query params:**
- `status` (optional) — `pending`, `resolved`, or `dismissed`

**Response `200`:**
```json
{
  "summary": {
    "total": 20,
    "pending": 5,
    "resolved": 14
  },
  "reports": [
    {
      "id": "uuid",
      "type": "harassment",
      "reporter": {"id": "uuid", "full_name": "John Doe"},
      "reported_user": {"id": "uuid", "full_name": "Bad Actor"},
      "message_id": "uuid",
      "post_id": null,
      "body": "This user is sending harassing messages",
      "status": "pending",
      "created_at": "2026-03-21T10:00:00Z"
    }
  ]
}
```

---

### PUT `/api/v1/admin/reports/{report_id}/resolve`
Resolve or dismiss a report.

**Auth required:** Admin only

**Request body:**
```json
{
  "dismiss": false
}
```

Set `dismiss: true` to dismiss instead of resolve.

**Response `200`:**
```json
{
  "report_id": "uuid",
  "status": "resolved"
}
```

---

### GET `/api/v1/admin/reports/flagged-messages`
List all pending reports that are specifically about messages, with the message content included.

**Auth required:** Admin only

**Response `200`:**
```json
[
  {
    "report_id": "uuid",
    "message_id": "uuid",
    "message_content": "This is the flagged message content",
    "reporter": {"id": "uuid", "full_name": "John Doe"},
    "reported_user": {"id": "uuid", "full_name": "Bad Actor"},
    "report_type": "harassment",
    "body": "Sending threatening messages",
    "created_at": "2026-03-21T10:00:00Z"
  }
]
```

---

### GET `/api/v1/admin/summary/{user_id}`
Generate a weekly fitness summary for a user.

**Auth required:** Admin only

**Response `200`:**
```json
{
  "user_id": "uuid",
  "week": "2026-W12",
  "summary": "John Doe had a great week. Workout frequency was 4 sessions. Calorie intake was on track. Current streak: 7 days. Overall adherence: 85%.",
  "metrics": {
    "adherence_pct": 85,
    "workout_sessions": 4,
    "calorie_balance": "on track",
    "streak_days": 7
  }
}
```

---

## 5. Messaging — REST

### POST `/api/v1/messaging/conversations`
Start a new direct conversation with another user, or return the existing one.

**Auth required:** Yes

**Request body:**
```json
{
  "other_user_id": "uuid"
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
List all conversations sorted by most recent message.

**Auth required:** Yes

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
Get paginated message history. Returns oldest-first within the page.

**Auth required:** Yes

**Query params:**
- `before` (optional) — ISO datetime for pagination cursor
- `limit` (optional, default 50, max 100)

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
Mark all messages in a conversation as read.

**Auth required:** Yes

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
Soft delete a message. Only the sender can delete their own messages.

**Auth required:** Yes

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
Get online status and last seen of a user.

**Auth required:** Yes

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
Get a one-time WebSocket authentication ticket. Valid for 30 seconds, single use.

**Auth required:** Yes

**Request body:** None

**Response `200`:**
```json
{
  "ticket": "random-secure-string"
}
```

**Usage:** Call this immediately before opening a WebSocket connection.

---

## 6. Messaging — WebSocket

### WS `/api/v1/messaging/ws?ticket={ticket}`

**Authentication:** Pass the ticket from `POST /messaging/ws-ticket` as a query param. Tickets are single-use and expire in 30 seconds.

**On connect:** Server pushes `unread_summary` if there are unread messages.

**Heartbeat:** Send `{"type": "heartbeat"}` every 30 seconds to maintain presence.

---

### Client → Server

#### `send_message`
```json
{
  "type": "send_message",
  "conversation_id": "uuid",
  "content": "Hello!"
}
```

#### `mark_read`
```json
{
  "type": "mark_read",
  "conversation_id": "uuid"
}
```

#### `typing`
Send repeatedly while typing. Auto-expires after 5 seconds.
```json
{
  "type": "typing",
  "conversation_id": "uuid"
}
```

#### `heartbeat`
```json
{
  "type": "heartbeat"
}
```

---

### Server → Client

#### `new_message`
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

Status progression: `sent` → `delivered` → `read`

#### `messages_read`
```json
{
  "type": "messages_read",
  "conversation_id": "uuid",
  "read_by": "uuid"
}
```

#### `typing`
```json
{
  "type": "typing",
  "conversation_id": "uuid",
  "user_id": "uuid"
}
```

#### `heartbeat_ack`
```json
{
  "type": "heartbeat_ack"
}
```

#### `unread_summary`
Pushed on connect if there are unread messages.
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

On receiving: fetch messages with `GET /messaging/conversations/{id}/messages`, then send `mark_read`.

#### `user_online` / `user_offline`
```json
{
  "type": "user_online",
  "user_id": "uuid"
}
```

#### `error`
```json
{
  "type": "error",
  "message": "You are not a member of this conversation"
}
```

---

### WebSocket Close Codes
| Code | Reason |
|------|--------|
| `4001` | Invalid or expired ticket |
| `4001` | User not found or inactive |

---

### Flutter Integration
```dart
// 1. Get ticket
final ticketResponse = await dio.post('/api/v1/messaging/ws-ticket');
final ticket = ticketResponse.data['ticket'];

// 2. Connect
final channel = WebSocketChannel.connect(
  Uri.parse('ws://localhost:8000/api/v1/messaging/ws?ticket=$ticket'),
);

// 3. Listen
channel.stream.listen((message) {
  final data = jsonDecode(message);
  switch (data['type']) {
    case 'new_message': // handle new message
    case 'messages_read': // update read receipts
    case 'typing': // show typing indicator
    case 'unread_summary': // fetch missed messages
    case 'user_online': // update presence
  }
});

// 4. Send message
channel.sink.add(jsonEncode({
  'type': 'send_message',
  'conversation_id': conversationId,
  'content': 'Hello!',
}));

// 5. Heartbeat
Timer.periodic(Duration(seconds: 30), (_) {
  channel.sink.add(jsonEncode({'type': 'heartbeat'}));
});
```

---

## 7. Social

### POST `/api/v1/social/friends/request/{user_id}`
Send a friend request to a user.

**Auth required:** Yes

**Response `201`:**
```json
{
  "request_id": "uuid",
  "status": "pending"
}
```

**Errors:**
- `404` — user not found
- `409` — request already exists or already friends

**Side effects:** Sends a notification to the receiver.

---

### PUT `/api/v1/social/friends/request/{request_id}`
Accept or reject a friend request. Only the receiver can respond.

**Auth required:** Yes

**Request body:**
```json
{
  "request_id": "uuid",
  "accept": true
}
```

**Response `200`:**
```json
{
  "request_id": "uuid",
  "status": "accepted"
}
```

**Side effects:** On accept, sends a notification to the sender.

---

### GET `/api/v1/social/friends/requests`
List pending incoming friend requests.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "request_id": "uuid",
    "sender": {
      "id": "uuid",
      "full_name": "John Doe"
    },
    "created_at": "2026-03-21T10:00:00Z"
  }
]
```

---

### GET `/api/v1/social/friends`
List all accepted friends.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "full_name": "John Doe",
    "email": "john@example.com"
  }
]
```

---

### DELETE `/api/v1/social/friends/{friend_id}`
Remove a friend.

**Auth required:** Yes

**Response `200`:**
```json
{
  "message": "Friend removed"
}
```

---

### GET `/api/v1/social/feed`
Get posts from friends and self, sorted by most recent.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "author": {
      "id": "uuid",
      "full_name": "John Doe"
    },
    "content": "Just finished a 5k run!",
    "like_count": 3,
    "liked_by_me": false,
    "created_at": "2026-03-21T10:00:00Z"
  }
]
```

---

### POST `/api/v1/social/posts`
Create a new post.

**Auth required:** Yes

**Request body:**
```json
{
  "content": "Just finished a 5k run!"
}
```

**Response `201`:**
```json
{
  "id": "uuid",
  "content": "Just finished a 5k run!",
  "created_at": "2026-03-21T10:00:00Z"
}
```

---

### DELETE `/api/v1/social/posts/{post_id}`
Soft delete a post. Only the author can delete.

**Auth required:** Yes

**Response `200`:**
```json
{
  "message": "Post deleted"
}
```

**Errors:**
- `403` — not the author
- `404` — post not found

---

### POST `/api/v1/social/posts/{post_id}/like`
Toggle like on a post. Calling again removes the like.

**Auth required:** Yes

**Response `200`:**
```json
{
  "liked": true
}
```

**Side effects:** On like, sends a notification to the post author (not on unlike).

---

### POST `/api/v1/social/report/message`
Report a message to admin.

**Auth required:** Yes

**Request body:**
```json
{
  "message_id": "uuid",
  "reported_user_id": "uuid",
  "report_type": "harassment",
  "body": "This user is sending threatening messages"
}
```

`report_type` values: `spam`, `harassment`, `inappropriate`, `other`

**Response `201`:**
```json
{
  "report_id": "uuid",
  "status": "pending"
}
```

---

### GET `/api/v1/social/leaderboard`
Get friends ranked by total steps in the last 7 days.

**Auth required:** Yes

**Response `200`:**
```json
[
  {
    "rank": 1,
    "user_id": "uuid",
    "full_name": "John Doe",
    "total_steps": 75000,
    "is_me": false
  },
  {
    "rank": 2,
    "user_id": "uuid",
    "full_name": "You",
    "total_steps": 62000,
    "is_me": true
  }
]
```

---

## 8. Notifications

### GET `/api/v1/notifications`
List notifications for the current user, most recent first (max 50).

**Auth required:** Yes

**Query params:**
- `unread_only` (optional, default `false`) — return only unread notifications

**Response `200`:**
```json
{
  "unread_count": 3,
  "notifications": [
    {
      "id": "uuid",
      "type": "friend_request",
      "title": "New friend request",
      "body": "John Doe sent you a friend request",
      "is_read": false,
      "reference_id": "uuid",
      "created_at": "2026-03-21T10:00:00Z"
    }
  ]
}
```

`type` values: `friend_request`, `friend_accepted`, `trainer_request`, `trainer_accepted`, `trainer_rejected`, `trainer_approved`, `new_message`, `post_like`, `system`

---

### PUT `/api/v1/notifications/{notification_id}/read`
Mark a single notification as read.

**Auth required:** Yes

**Response `200`:**
```json
{
  "message": "Marked as read"
}
```

---

### PUT `/api/v1/notifications/read-all`
Mark all notifications as read.

**Auth required:** Yes

**Response `200`:**
```json
{
  "message": "All marked as read"
}
```

---

### DELETE `/api/v1/notifications/{notification_id}`
Delete a notification.

**Auth required:** Yes

**Response `200`:**
```json
{
  "message": "Deleted"
}
```

---

## 9. Fitness

### GET `/api/v1/fitness/exercises`
Search the exercise library. Returns built-in exercises and custom ones created by the current user.

**Auth required:** Yes

**Query params:**
- `q` (optional) — search term, defaults to empty (returns all)

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "name": "Bench Press",
    "category": "strength",
    "measurement_type": "reps",
    "description": null,
    "is_custom": false
  }
]
```

`category` values: `cardio`, `strength`, `flexibility`, `balance`, `other`
`measurement_type` values: `reps`, `time`

---

### POST `/api/v1/fitness/exercises`
Create a custom exercise.

**Auth required:** Yes

**Request body:**
```json
{
  "name": "Cable Flyes",
  "category": "strength",
  "measurement_type": "reps",
  "description": "Cable crossover chest fly"
}
```

**Response `201`:**
```json
{
  "id": "uuid",
  "name": "Cable Flyes"
}
```

---

### POST `/api/v1/fitness/workouts/sessions`
Start a new workout session.

**Auth required:** Yes

**Request body:**
```json
{
  "name": "Push Day"
}
```

**Response `201`:**
```json
{
  "session_id": "uuid",
  "started_at": "2026-03-23T10:00:00Z"
}
```

---

### PUT `/api/v1/fitness/workouts/sessions/{session_id}/finish`
Finish a workout session. Status changes to `completed`.

**Auth required:** Yes

**Request body:**
```json
{
  "notes": "Great session, hit new PR on bench",
  "calories_burned": 350.0
}
```

**Response `200`:** Full session object with all sets.

---

### GET `/api/v1/fitness/workouts/sessions`
Get completed workout history.

**Auth required:** Yes

**Query params:**
- `limit` (optional, default 20, max 100)

**Response `200`:** List of session objects.

---

### GET `/api/v1/fitness/workouts/sessions/{session_id}`
Get a specific session with all sets.

**Auth required:** Yes

**Response `200`:**
```json
{
  "id": "uuid",
  "name": "Push Day",
  "status": "completed",
  "notes": "Great session",
  "calories_burned": 350.0,
  "started_at": "2026-03-23T10:00:00Z",
  "ended_at": "2026-03-23T11:00:00Z",
  "sets": [
    {
      "id": "uuid",
      "exercise": {
        "id": "uuid",
        "name": "Bench Press"
      },
      "set_number": 1,
      "reps": 10,
      "weight_kg": 80.0,
      "duration_seconds": null
    }
  ]
}
```

---

### POST `/api/v1/fitness/workouts/sessions/{session_id}/sets`
Log a set within a session.

**Auth required:** Yes

**Request body:**
```json
{
  "exercise_id": "uuid",
  "set_number": 1,
  "reps": 10,
  "weight_kg": 80.0,
  "duration_seconds": null,
  "notes": null
}
```

Use `reps` + `weight_kg` for strength exercises. Use `duration_seconds` for time-based exercises.

**Response `201`:**
```json
{
  "set_id": "uuid",
  "set_number": 1,
  "reps": 10,
  "weight_kg": 80.0
}
```

---

### DELETE `/api/v1/fitness/workouts/sets/{set_id}`
Delete a set from a session.

**Auth required:** Yes

**Response `200`:**
```json
{
  "message": "Set deleted"
}
```

---

### GET `/api/v1/fitness/foods/search`
Search for food items via Open Food Facts. Results are biased toward Indian products.

**Auth required:** Yes

**Query params:**
- `q` (required, min 2 chars) — food name to search
- `page` (optional, default 1)

**Response `200`:**
```json
[
  {
    "id": "8901058851812",
    "name": "Maggi Masala Noodles",
    "brand": "Nestle",
    "calories_per_100g": 385.0,
    "protein_per_100g": 9.5,
    "carbs_per_100g": 68.0,
    "fat_per_100g": 8.5,
    "serving_size_g": 70.0,
    "serving_label": "70g"
  }
]
```

**Notes:** Data comes directly from Open Food Facts. Some products may have incomplete nutritional data — values default to `0` when not available.

---

### GET `/api/v1/fitness/foods/barcode/{barcode}`
Get a specific food item by barcode.

**Auth required:** Yes

**Response `200`:** Same format as food search result.

**Errors:**
- `404` — barcode not found in Open Food Facts

---

### POST `/api/v1/fitness/nutrition/meals`
Log a meal. The food data is passed from the client (from the search result) and stored inline.

**Auth required:** Yes

**Request body:**
```json
{
  "food_id": "8901058851812",
  "food_name": "Maggi Masala Noodles",
  "calories_per_100g": 385.0,
  "protein_per_100g": 9.5,
  "carbs_per_100g": 68.0,
  "fat_per_100g": 8.5,
  "serving_size_g": 70.0,
  "serving_label": "70g",
  "servings": 1.5,
  "logged_at": null
}
```

`logged_at` defaults to current time if null.

**Response `201`:**
```json
{
  "meal_id": "uuid",
  "logged_at": "2026-03-23T12:00:00Z"
}
```

---

### GET `/api/v1/fitness/nutrition/meals`
Get all meals logged on a specific date.

**Auth required:** Yes

**Query params:**
- `date` (optional, ISO date, defaults to today)

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "food_id": "8901058851812",
    "food_name": "Maggi Masala Noodles",
    "servings": 1.5,
    "serving_label": "70g",
    "calories": 404.25,
    "protein_g": 9.99,
    "carbs_g": 71.4,
    "fat_g": 8.93,
    "logged_at": "2026-03-23T12:00:00Z"
  }
]
```

---

### GET `/api/v1/fitness/nutrition/summary`
Get daily nutrition totals for a date.

**Auth required:** Yes

**Query params:**
- `date` (optional, defaults to today)

**Response `200`:**
```json
{
  "date": "2026-03-23",
  "total_calories": 1850.5,
  "total_protein_g": 142.0,
  "total_carbs_g": 210.5,
  "total_fat_g": 55.0,
  "meal_count": 4
}
```

---

### DELETE `/api/v1/fitness/nutrition/meals/{meal_id}`
Delete a meal log entry.

**Auth required:** Yes

**Response `200`:**
```json
{
  "message": "Meal deleted"
}
```

---

### POST `/api/v1/fitness/steps`
Log step count for a date. Calling again for the same date updates the existing record (upsert).

**Auth required:** Yes

**Request body:**
```json
{
  "steps": 8500,
  "logged_date": "2026-03-23"
}
```

`logged_date` defaults to today if null.

**Response `200`:**
```json
{
  "date": "2026-03-23",
  "steps": 8500
}
```

---

### GET `/api/v1/fitness/steps/summary`
Get today's step count vs goal.

**Auth required:** Yes

**Response `200`:**
```json
{
  "date": "2026-03-23",
  "steps": 8500,
  "goal": 10000,
  "percentage": 85.0,
  "remaining": 1500
}
```

---

### GET `/api/v1/fitness/steps/history`
Get step history for the last N days.

**Auth required:** Yes

**Query params:**
- `days` (optional, default 7, max 90)

**Response `200`:**
```json
[
  {"date": "2026-03-17", "steps": 9200},
  {"date": "2026-03-18", "steps": 7800}
]
```

---

### GET `/api/v1/fitness/steps/streak`
Get the current step goal streak (consecutive days meeting the goal).

**Auth required:** Yes

**Response `200`:**
```json
{
  "streak_days": 7
}
```

---

### POST `/api/v1/fitness/hydration`
Log water intake.

**Auth required:** Yes

**Request body:**
```json
{
  "amount_ml": 500
}
```

**Response `201`:**
```json
{
  "id": "uuid",
  "amount_ml": 500,
  "logged_at": "2026-03-23T14:00:00Z"
}
```

---

### GET `/api/v1/fitness/hydration/summary`
Get today's total water intake.

**Auth required:** Yes

**Response `200`:**
```json
{
  "date": "2026-03-23",
  "total_ml": 1500,
  "total_l": 1.5,
  "goal_ml": 2500,
  "percentage": 60.0
}
```

---

### POST `/api/v1/fitness/weight`
Log a weight measurement.

**Auth required:** Yes

**Request body:**
```json
{
  "weight_kg": 71.5
}
```

**Response `201`:**
```json
{
  "id": "uuid",
  "weight_kg": 71.5,
  "logged_at": "2026-03-23T08:00:00Z"
}
```

---

### GET `/api/v1/fitness/weight/trend`
Get weight history for the last N days.

**Auth required:** Yes

**Query params:**
- `days` (optional, default 30, max 365)

**Response `200`:**
```json
[
  {"date": "2026-03-01", "weight_kg": 73.0},
  {"date": "2026-03-08", "weight_kg": 72.5},
  {"date": "2026-03-15", "weight_kg": 71.8}
]
```

---

### GET `/api/v1/fitness/stats/weekly`
Get a weekly fitness summary for the current user.

**Auth required:** Yes

**Response `200`:**
```json
{
  "workouts_completed": 4,
  "calories_burned": 1200.0,
  "total_steps": 62000,
  "step_goal_days_met": 5,
  "streak_days": 7
}
```
