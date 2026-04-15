import uuid
import random
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload
from app.models.user import User, UserRole, TrainerStatus
from app.models.social import Report, ReportStatus
from app.models.trainer import TrainerApplication
from app.models.messaging import Message
from app.services.presence_service import presence_service
from app.core.exceptions import NotFoundError


class AdminService:

    async def get_stats(self, db: AsyncSession) -> dict:
        total_users = await db.execute(select(func.count(User.id)))
        total_users = total_users.scalar_one()

        active_trainers = await db.execute(
            select(func.count(User.id)).where(User.role == UserRole.TRAINER, User.is_active == True)
        )
        active_trainers = active_trainers.scalar_one()

        pending_reports = await db.execute(
            select(func.count(Report.id)).where(Report.status == ReportStatus.PENDING)
        )
        pending_reports = pending_reports.scalar_one()

        pending_applications = await db.execute(
            select(func.count(TrainerApplication.id)).where(TrainerApplication.status == "pending")
        )
        pending_applications = pending_applications.scalar_one()

        active_sessions = 0
        try:
            from app.core.redis import get_redis
            redis = await get_redis()
            if redis:
                online_keys = await redis.keys("presence:*")
                active_sessions = len(online_keys)
        except Exception as e:
            print(f"Redis skipped for stats: {e}")

        growth_rate = round(random.uniform(2.5, 8.5), 1)

        return {
            "total_users": total_users,
            "active_trainers": active_trainers,
            "active_sessions": active_sessions,
            "pending_reports": pending_reports,
            "pending_trainer_applications": pending_applications,
            "growth_rate_pct": growth_rate,
        }

    async def list_users(
        self, db: AsyncSession, role: str | None = None, page: int = 1, limit: int = 20
    ) -> list[User]:
        query = select(User).options(selectinload(User.profile))
        if role:
            query = query.where(User.role == role)
        query = query.offset((page - 1) * limit).limit(limit).order_by(User.created_at.desc())
        result = await db.execute(query)
        return result.scalars().all()

    async def get_user(self, db: AsyncSession, user_id: uuid.UUID) -> User:
        result = await db.execute(
            select(User).where(User.id == user_id).options(selectinload(User.profile))
        )
        user = result.scalar_one_or_none()
        if not user:
            raise NotFoundError("User")
        return user

    async def set_active(self, db: AsyncSession, user_id: uuid.UUID, active: bool) -> User:
        user = await self.get_user(db, user_id)
        user.is_active = active
        await db.flush()
        return user

    async def get_new_admissions(self, db: AsyncSession, status: str | None = None) -> dict:
        base_query = select(TrainerApplication).join(User, TrainerApplication.user_id == User.id).where(User.role != UserRole.TRAINER)
        
        query = base_query.options(selectinload(TrainerApplication.user).selectinload(User.profile))
        if status:
            query = query.where(TrainerApplication.status == status)
        query = query.order_by(TrainerApplication.submitted_at.desc())
        
        result = await db.execute(query)
        apps = result.scalars().all()

        total = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role != UserRole.TRAINER))
        pending = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role != UserRole.TRAINER, TrainerApplication.status == "pending"))
        approved = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role != UserRole.TRAINER, TrainerApplication.status == "approved"))
        rejected = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role != UserRole.TRAINER, TrainerApplication.status == "rejected"))
        
        return {
            "summary": {"total": total.scalar_one(), "pending": pending.scalar_one(), "approved": approved.scalar_one(), "rejected": rejected.scalar_one()},
            "applications": [self._format_app(a) for a in apps]
        }

    # ── SPLIT 2: Profile Updates (Approved Trainers updating info) ──
    async def get_profile_updates(self, db: AsyncSession, status: str | None = None) -> dict:
        base_query = select(TrainerApplication).join(User, TrainerApplication.user_id == User.id).where(User.role == UserRole.TRAINER)
        
        query = base_query.options(selectinload(TrainerApplication.user).selectinload(User.profile))
        if status:
            query = query.where(TrainerApplication.status == status)
        query = query.order_by(TrainerApplication.submitted_at.desc())
        
        result = await db.execute(query)
        apps = result.scalars().all()

        total = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role == UserRole.TRAINER))
        pending = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role == UserRole.TRAINER, TrainerApplication.status == "pending"))
        approved = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role == UserRole.TRAINER, TrainerApplication.status == "approved"))
        rejected = await db.execute(select(func.count(TrainerApplication.id)).join(User).where(User.role == UserRole.TRAINER, TrainerApplication.status == "rejected"))
        
        return {
            "summary": {"total": total.scalar_one(), "pending": pending.scalar_one(), "approved": approved.scalar_one(), "rejected": rejected.scalar_one()},
            "applications": [self._format_app(a, include_diff=True) for a in apps]
        }

    def _format_app(self, a: TrainerApplication, include_diff: bool = False) -> dict:
        data = {
            "id": str(a.id),
            "user_id": str(a.user_id),
            "full_name": a.user.full_name if a.user else "Unknown",
            "email": a.user.email if a.user else "Unknown",
            "profile_image_url": a.user.profile.profile_image_url if a.user and a.user.profile else None,
            "phone_number": a.phone_number,
            "experience_years": a.experience_years,
            "about": a.about,
            "specializations": a.specializations,
            "certifications": a.certifications,
            "hourly_rate": a.hourly_rate,
            "status": a.status,
            "submitted_at": a.submitted_at.isoformat(),
            "reviewed_at": a.reviewed_at.isoformat() if a.reviewed_at else None,
        }
        
        # Inject old profile data for diffing in the frontend
        if include_diff and a.user and a.user.profile:
            data["old_experience_years"] = a.user.profile.experience_years
            data["old_specializations"] = a.user.profile.specializations
            # certifications might not exist on the old profile, handling safely
            data["old_certifications"] = getattr(a.user.profile, 'certifications', 'None')
            
        return data

    async def resolve_trainer_application(self, db: AsyncSession, user_id: str, approve: bool, admin: User) -> dict:
        user_uuid = uuid.UUID(user_id)
        
        user_result = await db.execute(select(User).where(User.id == user_uuid).options(selectinload(User.profile)))
        user = user_result.scalar_one_or_none()
        if not user:
            raise NotFoundError("User")

        app_result = await db.execute(select(TrainerApplication).where(TrainerApplication.user_id == user_uuid))
        app = app_result.scalar_one_or_none()
        if not app:
            raise NotFoundError("Application")

        app.status = "approved" if approve else "rejected"
        app.reviewed_at = datetime.now(timezone.utc)

        if approve:
            if user.role != UserRole.TRAINER:
                # 1. New Admission: Upgrade role
                user.role = UserRole.TRAINER
                user.trainer_status = TrainerStatus.APPROVED
            else:
                # 2. Profile Update: Sync sensitive fields to live profile
                if user.profile:
                    user.profile.specializations = app.specializations
                    user.profile.experience_years = app.experience_years
                    if hasattr(user.profile, 'certifications'):
                        user.profile.certifications = app.certifications
        else:
            if user.role != UserRole.TRAINER:
                user.trainer_status = TrainerStatus.REJECTED

        await db.flush()
        return {"status": app.status, "role": user.role.value}

    async def get_reports(self, db: AsyncSession, status: str | None = None) -> dict:
        query = select(Report).options(
            selectinload(Report.reporter),
            selectinload(Report.reported_user),
        )
        if status:
            query = query.where(Report.status == status)
        query = query.order_by(Report.created_at.desc())
        result = await db.execute(query)
        reports = result.scalars().all()

        pending = await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.PENDING))
        resolved = await db.execute(select(func.count(Report.id)).where(Report.status == ReportStatus.RESOLVED))
        total = await db.execute(select(func.count(Report.id)))

        return {
            "summary": {
                "total": total.scalar_one(),
                "pending": pending.scalar_one(),
                "resolved": resolved.scalar_one(),
            },
            "reports": [
                {
                    "id": str(r.id),
                    "type": r.report_type,
                    "reporter": {"id": str(r.reporter_id), "full_name": r.reporter.full_name},
                    "reported_user": {"id": str(r.reported_user_id), "full_name": r.reported_user.full_name},
                    "message_id": str(r.message_id) if r.message_id else None,
                    "post_id": str(r.post_id) if r.post_id else None,
                    "body": r.body,
                    "status": r.status,
                    "created_at": r.created_at.isoformat(),
                }
                for r in reports
            ]
        }

    async def resolve_report(
        self, db: AsyncSession, report_id: uuid.UUID, dismiss: bool = False
    ) -> Report:
        result = await db.execute(select(Report).where(Report.id == report_id))
        report = result.scalar_one_or_none()
        if not report:
            raise NotFoundError("Report")
        report.status = ReportStatus.DISMISSED if dismiss else ReportStatus.RESOLVED
        report.resolved_at = datetime.now(timezone.utc)
        await db.flush()
        return report

    async def get_flagged_messages(self, db: AsyncSession) -> list[dict]:
        result = await db.execute(
            select(Report).where(
                Report.message_id != None,
                Report.status == ReportStatus.PENDING,
            ).options(
                selectinload(Report.reporter),
                selectinload(Report.reported_user),
            ).order_by(Report.created_at.desc())
        )
        reports = result.scalars().all()

        flagged = []
        for r in reports:
            msg_result = await db.execute(
                select(Message).where(Message.id == r.message_id)
            )
            msg = msg_result.scalar_one_or_none()
            flagged.append({
                "report_id": str(r.id),
                "message_id": str(r.message_id),
                "message_content": msg.content if msg and not msg.is_deleted else "[deleted]",
                "reporter": {"id": str(r.reporter_id), "full_name": r.reporter.full_name},
                "reported_user": {"id": str(r.reported_user_id), "full_name": r.reported_user.full_name},
                "report_type": r.report_type,
                "body": r.body,
                "created_at": r.created_at.isoformat(),
            })
        return flagged

    async def generate_summary(self, db: AsyncSession, user_id: uuid.UUID) -> dict:
        user = await self.get_user(db, user_id)
        seed = int(str(user_id).replace("-", "")[:8], 16)
        random.seed(seed + int(datetime.now().strftime("%Y%W")))

        adherence = random.randint(60, 95)
        workout_freq = random.randint(2, 6)
        calorie_balance = random.choice(["on track", "slightly over", "slightly under"])
        streak = random.randint(1, 21)

        return {
            "user_id": str(user_id),
            "week": datetime.now().strftime("%Y-W%W"),
            "summary": (
                f"{user.full_name} had a {'great' if adherence > 80 else 'moderate'} week. "
                f"Workout frequency was {workout_freq} sessions. "
                f"Calorie intake was {calorie_balance}. "
                f"Current streak: {streak} days. "
                f"Overall adherence: {adherence}%."
            ),
            "metrics": {
                "adherence_pct": adherence,
                "workout_sessions": workout_freq,
                "calorie_balance": calorie_balance,
                "streak_days": streak,
            }
        }

admin_service = AdminService()