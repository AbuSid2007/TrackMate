from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from sqlalchemy import select

from app.core.config import settings
from app.core.security import hash_password
from app.db.base import AsyncSessionLocal
from app.models.user import User, UserRole, TrainerStatus
from app.api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Seed admin account from env variables if it doesn't exist yet
    if settings.ADMIN_EMAIL and settings.ADMIN_PASSWORD:
        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(User).where(User.email == settings.ADMIN_EMAIL)
            )
            if not result.scalar_one_or_none():
                admin = User(
                    email=settings.ADMIN_EMAIL,
                    hashed_password=hash_password(settings.ADMIN_PASSWORD),
                    full_name=settings.ADMIN_FULL_NAME,
                    role=UserRole.ADMIN,
                    trainer_status=TrainerStatus.NONE,
                    is_active=True,
                    is_verified=True,
                )
                db.add(admin)
                await db.commit()
                print(f"[Startup] Admin account created: {settings.ADMIN_EMAIL}")

    print(f"TrackMate API starting in [{settings.APP_ENV}] mode")
    yield
    print("TrackMate API shutting down")


app = FastAPI(
    title="TrackMate API",
    description="Fitness tracking platform",
    version="1.0.0",
    docs_url="/docs" if settings.is_development else None,
    redoc_url="/redoc" if settings.is_development else None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/health", tags=["Health"])
async def health_check():
    return JSONResponse(content={"status": "healthy", "service": "trackmate-api"})