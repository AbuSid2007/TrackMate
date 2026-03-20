from fastapi import APIRouter, Depends, status, Response, Request, Cookie, Body
from sqlalchemy.ext.asyncio import AsyncSession
import uuid


from app.db.base import get_db
from app.schemas.auth import (
    RegisterRequest, LoginRequest, AuthResponse, TokenResponse,
    UserResponse, MessageResponse, ApproveTrainerRequest,
    ResendVerificationRequest, VerifyEmailRequest
)
from app.services.auth_service import auth_service
from app.api.v1.deps import get_current_user, require_admin
from app.models.user import User
from app.core.config import settings
from app.core.exceptions import AuthenticationError, ConflictError

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _set_auth_cookies(response: Response, tokens: TokenResponse) -> None:
    secure = settings.COOKIE_SECURE
    same_site = settings.COOKIE_SAMESITE.lower()
    if same_site not in ("none", "lax", "strict"):
        same_site = "lax"
    if same_site == "none" and not secure:
        same_site = "lax"

    response.set_cookie(
        key="access_token", value=tokens.access_token,
        httponly=True, secure=secure, samesite=same_site,
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60, path="/",
    )
    response.set_cookie(
        key="refresh_token", value=tokens.refresh_token,
        httponly=True, secure=secure, samesite=same_site,
        max_age=settings.REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60, path="/",
    )


def _clear_auth_cookies(response: Response) -> None:
    response.delete_cookie("access_token", path="/")
    response.delete_cookie("refresh_token", path="/")


@router.post("/register", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def register(
    payload: RegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    return await auth_service.register(db, payload)


@router.post("/login", response_model=AuthResponse, status_code=status.HTTP_200_OK)
async def login(
    payload: LoginRequest, response: Response, db: AsyncSession = Depends(get_db),
) -> AuthResponse:
    auth = await auth_service.login(db, payload)
    _set_auth_cookies(response, auth.tokens)
    return auth


@router.post("/refresh", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def refresh_token(
    response: Response,
    refresh_token: str | None = Cookie(default=None),
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    if not refresh_token:
        raise AuthenticationError("Refresh token required")
    tokens = await auth_service.refresh(db, refresh_token)
    _set_auth_cookies(response, tokens)
    return tokens


@router.get("/me", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def get_me(current_user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.model_validate(current_user)


@router.post("/logout", response_model=MessageResponse, status_code=status.HTTP_200_OK)
async def logout(
    response: Response, current_user: User = Depends(get_current_user),
) -> MessageResponse:
    _clear_auth_cookies(response)
    return MessageResponse(message="Logged out successfully")


@router.post("/verify-email", response_model=AuthResponse, status_code=status.HTTP_200_OK)
async def verify_email(
    payload: VerifyEmailRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
) -> AuthResponse:
    auth = await auth_service.verify_email(db, payload.email, payload.otp)
    _set_auth_cookies(response, auth.tokens)
    return auth

@router.post("/admin/trainer-applications", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def approve_trainer(
    payload: ApproveTrainerRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
) -> UserResponse:
    user = await auth_service.approve_trainer(db, str(payload.user_id), payload.approve, admin)
    return UserResponse.model_validate(user)


@router.post("/admin/assign-trainer", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def assign_trainer(
    trainee_id: uuid.UUID,
    trainer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin),
) -> UserResponse:
    trainee = await auth_service.assign_trainer(db, str(trainee_id), str(trainer_id))
    return UserResponse.model_validate(trainee)

@router.post("/resend-verification", response_model=MessageResponse, status_code=status.HTTP_200_OK)
async def resend_verification(
    payload: ResendVerificationRequest,
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    await auth_service.resend_verification(db, payload.email)
    return MessageResponse(message="Verification email sent")