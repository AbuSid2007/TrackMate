import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func
from app.models.notification import Notification, NotificationType


class NotificationService:

    async def create(
        self,
        db: AsyncSession,
        user_id: uuid.UUID,
        type: NotificationType,
        title: str,
        body: str,
        reference_id: str | None = None,
    ) -> Notification:
        notif = Notification(
            user_id=user_id,
            type=type,
            title=title,
            body=body,
            reference_id=reference_id,
        )
        db.add(notif)
        await db.flush()
        return notif

    async def list(
        self, db: AsyncSession, user_id: uuid.UUID, unread_only: bool = False
    ) -> list[Notification]:
        query = select(Notification).where(Notification.user_id == user_id)
        if unread_only:
            query = query.where(Notification.is_read == False)
        query = query.order_by(Notification.created_at.desc()).limit(50)
        result = await db.execute(query)
        return result.scalars().all()

    async def mark_read(self, db: AsyncSession, notification_id: uuid.UUID, user_id: uuid.UUID) -> None:
        result = await db.execute(select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        ))
        notif = result.scalar_one_or_none()
        if notif:
            notif.is_read = True
            await db.flush()

    async def mark_all_read(self, db: AsyncSession, user_id: uuid.UUID) -> None:
        await db.execute(
            update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read == False)
            .values(is_read=True)
        )

    async def delete(self, db: AsyncSession, notification_id: uuid.UUID, user_id: uuid.UUID) -> None:
        result = await db.execute(select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        ))
        notif = result.scalar_one_or_none()
        if notif:
            await db.delete(notif)
            await db.flush()

    async def unread_count(self, db: AsyncSession, user_id: uuid.UUID) -> int:
        result = await db.execute(
            select(func.count(Notification.id)).where(
                Notification.user_id == user_id,
                Notification.is_read == False,
            )
        )
        return result.scalar_one()


notification_service = NotificationService()