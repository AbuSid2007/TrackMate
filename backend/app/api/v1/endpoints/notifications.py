import uuid
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.api.v1.deps import get_current_user
from app.models.user import User
from app.services.notification_service import notification_service

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", status_code=status.HTTP_200_OK)
async def list_notifications(
    unread_only: bool = Query(default=False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    notifications = await notification_service.list(db, current_user.id, unread_only)
    unread_count = await notification_service.unread_count(db, current_user.id)
    return {
        "unread_count": unread_count,
        "notifications": [
            {
                "id": str(n.id),
                "type": n.type,
                "title": n.title,
                "body": n.body,
                "is_read": n.is_read,
                "reference_id": n.reference_id,
                "created_at": n.created_at.isoformat(),
            }
            for n in notifications
        ]
    }


@router.put("/{notification_id}/read", status_code=status.HTTP_200_OK)
async def mark_read(
    notification_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await notification_service.mark_read(db, notification_id, current_user.id)
    return {"message": "Marked as read"}


@router.put("/read-all", status_code=status.HTTP_200_OK)
async def mark_all_read(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await notification_service.mark_all_read(db, current_user.id)
    return {"message": "All marked as read"}


@router.delete("/{notification_id}", status_code=status.HTTP_200_OK)
async def delete_notification(
    notification_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await notification_service.delete(db, notification_id, current_user.id)
    return {"message": "Deleted"}