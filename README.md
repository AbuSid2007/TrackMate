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
1. User registers with `apply_as_trainer: true`
2. Account is created with `trainer_status: pending`
3. Admin reviews and approves or rejects via API
4. On approval, role is updated to `trainer` and user receives an email notification
5. On rejection, user receives a rejection email

### Email Notifications
| Trigger | Email sent |
|---------|-----------|
| Registration | OTP verification code (expires in 10 minutes) |
| Login attempt (unverified) | New OTP resent automatically |
| Trainer approved | Approval notification |
| Trainer rejected | Rejection notification |

### Messaging
- Real-time direct messaging via WebSocket
- Secure ticket-based WebSocket authentication (no tokens in URL)
- Read/delivered receipts
- Typing indicators
- Online/offline presence with last seen
- Offline message delivery via DB + unread summary on reconnect

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
- WebSockets — real-time messaging
