from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.base import get_db
from app.models.user import User, UserRole
from app.services.auth_service import auth_service
from app.core.exceptions import ForbiddenError, AuthenticationError


from fastapi import Request, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession

# Adjust these imports based on your exact file structure
from app.core.database import get_db 
from app.services.auth_service import auth_service
from app.models.user import User
from app.core.exceptions import AuthenticationError, ForbiddenError

async def get_current_user(
    request: Request,
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Dependency to get the current user.
    Reads the token from the HttpOnly cookie (or Authorization header as fallback).
    """
    # 1. Look for the token in the cookies first (Flutter uses this)
    token = request.cookies.get("access_token")
    
    # 2. Fallback for Swagger UI or Postman (Authorization Header)
    if not token:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]

    # 3. If completely missing, reject
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 4. Pass the token to your auth_service logic
    try:
        # Python knows this is calling the method inside the auth_service object
        user = await auth_service.get_current_user(db, token)
        return user
    except AuthenticationError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e),
        )


async def require_trainee(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.TRAINEE:
        raise ForbiddenError("Trainee access required")
    return current_user


async def require_trainer(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.TRAINER:
        raise ForbiddenError("Trainer access required")
    return current_user


async def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Admin access required")
    return current_user
