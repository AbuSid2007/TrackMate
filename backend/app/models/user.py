import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Boolean, DateTime, Enum as SAEnum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
import enum
from app.db.base import Base
from app.models.profile import UserProfile

class UserRole(str, enum.Enum):
    TRAINEE = "trainee"
    TRAINER = "trainer"
    ADMIN = "admin"


class TrainerStatus(str, enum.Enum):
    NONE = "none"           # not a trainer applicant
    PENDING = "pending"     # applied, awaiting admin approval
    APPROVED = "approved"   # active trainer
    REJECTED = "rejected"   # admin rejected


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True,
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        SAEnum(UserRole, name="userrole", values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=UserRole.TRAINEE,
    )
    trainer_status: Mapped[TrainerStatus] = mapped_column(
        SAEnum(TrainerStatus, name="trainerstatus", values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=TrainerStatus.NONE,
    )

    # Trainer assignment — a trainee can have one trainer
    trainer_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        default=None,
    )
    trainer: Mapped["User | None"] = relationship(
        "User", foreign_keys=[trainer_id], remote_side="User.id"
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    verification_otp: Mapped[str | None] = mapped_column(String(6), nullable=True, default=None)
    otp_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, default=None)
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    profile: Mapped["UserProfile | None"] = relationship(
        "UserProfile", back_populates="user", uselist=False
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email} role={self.role}>"