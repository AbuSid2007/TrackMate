from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User
from app.models.profile import UserProfile, ActivityLevel
from app.schemas.profile import ProfileUpdateRequest, ProfileResponse
from app.core.exceptions import NotFoundError
import math


class ProfileService:

    async def get_or_create_profile(
        self, db: AsyncSession, user: User
    ) -> UserProfile:
        result = await db.execute(
            select(UserProfile).where(UserProfile.user_id == user.id)
        )
        profile = result.scalar_one_or_none()
        if not profile:
            profile = UserProfile(user_id=user.id)
            db.add(profile)
            await db.flush()
            await db.refresh(profile)
        return profile

    async def update_profile(
        self, db: AsyncSession, user: User, payload: ProfileUpdateRequest
    ) -> UserProfile:
        profile = await self.get_or_create_profile(db, user)
        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(profile, field, value)
        await db.flush()
        await db.refresh(profile)
        return profile

    def calculate_tdee(self, profile: UserProfile) -> float | None:
        if not all([
            profile.height_cm,
            profile.weight_kg,
            profile.date_of_birth,
            profile.gender,
            profile.activity_level,
        ]):
            return None

        from datetime import datetime, timezone
        age = (datetime.now(timezone.utc) - profile.date_of_birth).days // 365

        # Mifflin-St Jeor BMR
        if profile.gender.value == "male":
            bmr = 10 * profile.weight_kg + 6.25 * profile.height_cm - 5 * age + 5
        else:
            bmr = 10 * profile.weight_kg + 6.25 * profile.height_cm - 5 * age - 161

        multipliers = {
            "sedentary": 1.2,
            "lightly_active": 1.375,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extra_active": 1.9,
        }
        return round(bmr * multipliers.get(profile.activity_level.value, 1.2), 1)


profile_service = ProfileService()