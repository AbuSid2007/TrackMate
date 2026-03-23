# TrackMate

A fitness tracking platform connecting trainees with trainers, built with Flutter (frontend) and FastAPI (backend).

---

## Project Structure

```
trackmate/
├── mobile/          # Flutter app
└── backend/         # FastAPI backend
```

---

## Features

### Authentication
- Email/password registration with OTP email verification
- Account is inactive until email is verified
- Login derives role from database — no client-side role selection
- Cookie-based JWT authentication (httponly, secure)
- Automatic token refresh via Dio interceptor
- Logout clears session cookies

### Roles
| Role | Description |
|------|-------------|
| `trainee` | Default role on registration |
| `trainer` | Requires admin approval after applying |
| `admin` | Seeded from environment variables on startup |

### Trainer Application Flow
1. User registers normally (becomes trainee)
2. User submits trainer application via `POST /trainer/apply`
3. Admin reviews and approves or rejects
4. On approval, role is updated to `trainer` and user receives email notification
5. On rejection, user receives rejection email

### Trainee → Trainer Request Flow
1. Trainee browses available trainers via `GET /trainer/available`
2. Trainee sends request with goal via `POST /trainer/request`
3. Trainer sees pending requests via `GET /trainer/requests`
4. Trainer accepts or rejects via `PUT /trainer/requests/{id}`
5. On accept, `trainer_id` is set on the trainee and a notification is sent

### Email Notifications
| Trigger | Email sent |
|---------|-----------|
| Registration | OTP verification code (expires in 10 minutes) |
| Login attempt (unverified) | New OTP resent automatically |
| Trainer approved | Approval notification |
| Trainer rejected | Rejection notification |
| Friend request accepted | Notification to sender |
| Trainer request accepted/rejected | Notification to trainee |

### Messaging
- Real-time direct messaging via WebSocket
- Secure one-time ticket-based WebSocket authentication (no tokens in URL)
- Read/delivered receipts
- Typing indicators
- Online/offline presence with last seen
- Offline message delivery via DB — unread summary pushed on reconnect

### Social
- Friends system — send, accept, reject requests
- Friends-only post feed with likes
- Step count leaderboard among friends
- Report messages to admin

### Fitness Tracking
- Workout sessions with sets (reps, weight, duration)
- Food logging via Open Food Facts API — no API key required, Indian food coverage
- Daily step tracking with goals and streaks
- Hydration logging
- Weight trend tracking
- Weekly stats summary

---

## Backend Setup

### Requirements
- Python 3.12+
- PostgreSQL
- Redis
- Gmail account with App Password for SMTP

### Installation
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Environment Variables
Create a `.env` file in the `backend/` directory:

```env
# Database
DATABASE_URL=postgresql+asyncpg://postgres:password@localhost:5432/trackmate

# JWT
SECRET_KEY=your-secret-key-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Cookie
COOKIE_SECURE=false
COOKIE_SAMESITE=lax

# App
APP_ENV=development
APP_HOST=0.0.0.0
APP_PORT=8000
CORS_ORIGINS=["http://localhost:3000"]

# Redis
REDIS_URL=redis://localhost:6379

# Email (Gmail App Password)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=you@gmail.com
SMTP_PASSWORD=your_16_char_app_password
EMAIL_FROM=you@gmail.com
EMAIL_FROM_NAME=TrackMate
FRONTEND_URL=http://localhost:3000

# Admin seed (created on startup if not exists)
ADMIN_EMAIL=admin@trackmate.com
ADMIN_PASSWORD=AdminPass123
ADMIN_FULL_NAME=Admin
```

### Redis Setup
```bash
# Ubuntu / WSL
sudo apt install redis-server
sudo service redis-server start

# Verify
redis-cli ping  # should return PONG
```

### Database Migration
```bash
alembic upgrade head
```

### Running the Backend
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at `http://localhost:8000/docs` in development mode.

---

## Frontend Setup

### Requirements
- Flutter 3.x
- Dart SDK >= 3.3.0

### Installation
```bash
cd mobile
flutter pub get
```

### Running on Web
```bash
flutter run -d chrome --web-port 3000
```

### Running on Android Emulator
```bash
flutter emulators --launch <emulator_id>
flutter run
```

---

## Database Schema

### users
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `email` | String | Unique, indexed |
| `hashed_password` | String | bcrypt hashed |
| `full_name` | String | |
| `role` | Enum | `trainee`, `trainer`, `admin` |
| `trainer_status` | Enum | `none`, `pending`, `approved`, `rejected` |
| `trainer_id` | UUID FK | Assigned trainer (nullable) |
| `is_active` | Boolean | False until email verified |
| `is_verified` | Boolean | Email verification status |
| `verification_otp` | String | 6-digit OTP (nullable) |
| `otp_expires_at` | DateTime | OTP expiry (nullable) |
| `created_at` | DateTime | |
| `updated_at` | DateTime | |

### user_profiles
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `profile_image_url` | String | Optional |
| `bio` | Text | Optional |
| `date_of_birth` | DateTime | Optional |
| `gender` | Enum | `male`, `female`, `other`, `prefer_not_to_say` |
| `height_cm` | Float | Optional |
| `weight_kg` | Float | Optional |
| `daily_step_goal` | Integer | Default 10000 |
| `daily_calorie_goal` | Integer | Optional |
| `activity_level` | Enum | `sedentary`, `lightly_active`, `moderately_active`, `very_active`, `extra_active` |
| `specializations` | String | Trainer only, comma-separated |
| `experience_years` | Integer | Trainer only |
| `phone_number` | String | Optional |
| `hourly_rate` | Float | Trainer only |

### conversations
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `created_at` | DateTime | |

### conversation_members
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `conversation_id` | UUID FK | References conversations.id |
| `user_id` | UUID FK | References users.id |
| `last_read_at` | DateTime | For unread count calculation |
| `joined_at` | DateTime | |

### messages
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `conversation_id` | UUID FK | References conversations.id |
| `sender_id` | UUID FK | References users.id |
| `content` | Text | Message content |
| `status` | Enum | `sent`, `delivered`, `read` |
| `is_deleted` | Boolean | Soft delete |
| `created_at` | DateTime | Indexed |
| `updated_at` | DateTime | |

### friend_requests
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `sender_id` | UUID FK | References users.id |
| `receiver_id` | UUID FK | References users.id |
| `status` | Enum | `pending`, `accepted`, `rejected` |
| `created_at` | DateTime | |

### posts
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `author_id` | UUID FK | References users.id |
| `content` | Text | |
| `is_deleted` | Boolean | Soft delete |
| `created_at` | DateTime | |

### post_likes
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `post_id` | UUID FK | References posts.id |
| `user_id` | UUID FK | References users.id |
| `created_at` | DateTime | |

### reports
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `reporter_id` | UUID FK | References users.id |
| `reported_user_id` | UUID FK | References users.id |
| `message_id` | UUID FK | References messages.id (nullable) |
| `post_id` | UUID FK | References posts.id (nullable) |
| `report_type` | Enum | `spam`, `harassment`, `inappropriate`, `other` |
| `body` | Text | Report description |
| `status` | Enum | `pending`, `resolved`, `dismissed` |
| `resolved_at` | DateTime | Nullable |
| `created_at` | DateTime | |

### trainer_applications
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `phone_number` | String | Optional |
| `experience_years` | Integer | Optional |
| `about` | Text | Optional |
| `specializations` | String | Comma-separated |
| `certifications` | String | Comma-separated |
| `hourly_rate` | Float | Optional |
| `status` | String | `pending`, `approved`, `rejected` |
| `submitted_at` | DateTime | |
| `reviewed_at` | DateTime | Nullable |

### trainer_requests
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `trainee_id` | UUID FK | References users.id |
| `trainer_id` | UUID FK | References users.id |
| `goal` | Text | Trainee's stated goal |
| `status` | Enum | `pending`, `accepted`, `rejected` |
| `created_at` | DateTime | |

### trainer_sessions
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `trainer_id` | UUID FK | References users.id |
| `trainee_id` | UUID FK | References users.id |
| `scheduled_at` | DateTime | |
| `duration_minutes` | Integer | Default 60 |
| `notes` | Text | Optional |
| `created_at` | DateTime | |

### trainer_notes
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `trainer_id` | UUID FK | References users.id |
| `trainee_id` | UUID FK | References users.id |
| `content` | Text | |
| `created_at` | DateTime | |

### notifications
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `type` | Enum | `friend_request`, `friend_accepted`, `trainer_request`, `trainer_accepted`, `trainer_rejected`, `trainer_approved`, `new_message`, `post_like`, `system` |
| `title` | String | |
| `body` | Text | |
| `is_read` | Boolean | Default false |
| `reference_id` | String | ID of related object (nullable) |
| `created_at` | DateTime | |

### exercises
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `name` | String | Indexed |
| `category` | Enum | `cardio`, `strength`, `flexibility`, `balance`, `other` |
| `measurement_type` | Enum | `reps`, `time` |
| `description` | Text | Optional |
| `is_custom` | Boolean | False for built-in |
| `created_by` | UUID FK | References users.id (nullable) |
| `created_at` | DateTime | |

### workout_sessions
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `name` | String | Optional |
| `status` | Enum | `in_progress`, `completed`, `cancelled` |
| `notes` | Text | Optional |
| `calories_burned` | Float | Optional |
| `started_at` | DateTime | |
| `ended_at` | DateTime | Nullable |
| `created_at` | DateTime | |

### workout_sets
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `session_id` | UUID FK | References workout_sessions.id |
| `exercise_id` | UUID FK | References exercises.id |
| `set_number` | Integer | |
| `reps` | Integer | Nullable |
| `weight_kg` | Float | Nullable |
| `duration_seconds` | Integer | Nullable |
| `notes` | String | Optional |
| `created_at` | DateTime | |

### meal_logs
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `food_id` | String | Open Food Facts barcode/id |
| `food_name` | String | Stored inline |
| `calories_per_100g` | Float | |
| `protein_per_100g` | Float | |
| `carbs_per_100g` | Float | |
| `fat_per_100g` | Float | |
| `serving_size_g` | Float | |
| `serving_label` | String | e.g. "100g", "1 cup" |
| `servings` | Float | Number of servings logged |
| `logged_at` | DateTime | Indexed |
| `created_at` | DateTime | |

### step_logs
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `steps` | Integer | |
| `logged_date` | Date | One record per day (upsert) |
| `created_at` | DateTime | |

### hydration_logs
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `amount_ml` | Integer | |
| `logged_at` | DateTime | |

### weight_logs
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID FK | References users.id |
| `weight_kg` | Float | |
| `logged_at` | DateTime | |

---

## Tech Stack

### Frontend
- Flutter + Dart
- `flutter_bloc` — state management
- `go_router` — navigation
- `dio` + `dio_cookie_manager` — HTTP client with cookie support
- `get_it` — dependency injection
- `dartz` — functional error handling
- `equatable` — value equality

### Backend
- FastAPI
- SQLAlchemy (async) + PostgreSQL
- Alembic — migrations
- Redis — presence, typing indicators, WebSocket tickets
- `python-jose` — JWT
- `passlib` + bcrypt — password hashing
- `pydantic-settings` — environment config
- `smtplib` — email delivery
- `httpx` — async HTTP client for Open Food Facts
- WebSockets — real-time messaging
