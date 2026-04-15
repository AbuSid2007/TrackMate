import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Float, Integer, DateTime, Enum as SAEnum, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
from app.db.base import Base


class Gender(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"
    PREFER_NOT_TO_SAY = "prefer_not_to_say"


class ActivityLevel(str, enum.Enum):
    SEDENTARY = "sedentary"           # little or no exercise
    LIGHTLY_ACTIVE = "lightly_active" # 1-3 days/week
    MODERATELY_ACTIVE = "moderately_active" # 3-5 days/week
    VERY_ACTIVE = "very_active"       # 6-7 days/week
    EXTRA_ACTIVE = "extra_active"     # physical job + exercise


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    # Basic info
    profile_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
    date_of_birth: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    gender: Mapped[Gender | None] = mapped_column(
        SAEnum(Gender, name="gender", values_callable=lambda x: [e.value for e in x]),
        nullable=True,
    )

    # Biometrics
    height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Goals
    daily_step_goal: Mapped[int] = mapped_column(Integer, default=10000, nullable=False)
    daily_calorie_goal: Mapped[int | None] = mapped_column(Integer, nullable=True)
    activity_level: Mapped[ActivityLevel | None] = mapped_column(
        SAEnum(ActivityLevel, name="activitylevel", values_callable=lambda x: [e.value for e in x]),
        nullable=True,
    )

    # Trainer-specific
    certifications: Mapped[str | None] = mapped_column(String(500), nullable=True) 
    specializations: Mapped[str | None] = mapped_column(String(500), nullable=True)  # comma-separated
    experience_years: Mapped[int | None] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    hourly_rate: Mapped[float | None] = mapped_column(Float, nullable=True)

    user: Mapped["User"] = relationship("User", back_populates="profile")