from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime
import uuid
from app.models.profile import Gender, ActivityLevel


class ProfileUpdateRequest(BaseModel):
    bio: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    gender: Optional[Gender] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    daily_step_goal: Optional[int] = None
    daily_calorie_goal: Optional[int] = None
    activity_level: Optional[ActivityLevel] = None
    specializations: Optional[str] = None
    experience_years: Optional[int] = None

    @field_validator("height_cm")
    @classmethod
    def validate_height(cls, v: float | None) -> float | None:
        if v is not None and not (50 <= v <= 300):
            raise ValueError("Height must be between 50 and 300 cm")
        return v

    @field_validator("weight_kg")
    @classmethod
    def validate_weight(cls, v: float | None) -> float | None:
        if v is not None and not (20 <= v <= 500):
            raise ValueError("Weight must be between 20 and 500 kg")
        return v

    @field_validator("daily_step_goal")
    @classmethod
    def validate_steps(cls, v: int | None) -> int | None:
        if v is not None and not (1000 <= v <= 100000):
            raise ValueError("Step goal must be between 1000 and 100000")
        return v

    @field_validator("daily_calorie_goal")
    @classmethod
    def validate_calories(cls, v: int | None) -> int | None:
        if v is not None and not (500 <= v <= 10000):
            raise ValueError("Calorie goal must be between 500 and 10000")
        return v


class ProfileResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    profile_image_url: Optional[str]
    bio: Optional[str]
    date_of_birth: Optional[datetime]
    gender: Optional[Gender]
    height_cm: Optional[float]
    weight_kg: Optional[float]
    daily_step_goal: int
    daily_calorie_goal: Optional[int]
    activity_level: Optional[ActivityLevel]
    specializations: Optional[str]
    experience_years: Optional[int]
    tdee: Optional[float] = None # calculated, not stored
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True, "use_enum_values": True}


class FullUserResponse(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: str
    trainer_status: str
    is_verified: bool
    profile: Optional[ProfileResponse]

    model_config = {"from_attributes": True, "use_enum_values": True}