import uuid
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func
from sqlalchemy.orm import selectinload
from app.models.social import FriendRequest, FriendRequestStatus, Post, PostLike, Report, ReportStatus, ReportType
from app.models.user import User
from app.core.exceptions import NotFoundError, ConflictError, ForbiddenError
from app.models.notification import NotificationType
from app.services.notification_service import notification_service


class SocialService:

    # ── Friends ──────────────────────────────────────────────────────────────

    async def send_friend_request(
        self, db: AsyncSession, sender: User, receiver_id: uuid.UUID
    ) -> FriendRequest:
        if str(sender.id) == str(receiver_id):
            raise ConflictError("Cannot send friend request to yourself")

        existing = await db.execute(
            select(FriendRequest).where(
                or_(
                    and_(FriendRequest.sender_id == sender.id, FriendRequest.receiver_id == receiver_id),
                    and_(FriendRequest.sender_id == receiver_id, FriendRequest.receiver_id == sender.id),
                )
            )
        )
        if existing.scalar_one_or_none():
            raise ConflictError("Friend request already exists")

        receiver = await db.execute(select(User).where(User.id == receiver_id))
        receiver = receiver.scalar_one_or_none()
        if not receiver:
            raise NotFoundError("User")

        req = FriendRequest(sender_id=sender.id, receiver_id=receiver_id)
        db.add(req)
        await db.flush()

        await notification_service.create(
            db, receiver_id, NotificationType.FRIEND_REQUEST,
            "New friend request",
            f"{sender.full_name} sent you a friend request",
            reference_id=str(req.id),
        )
        return req

    async def respond_to_friend_request(
        self, db: AsyncSession, request_id: uuid.UUID, user: User, accept: bool
    ) -> FriendRequest:
        result = await db.execute(
            select(FriendRequest).where(
                FriendRequest.id == request_id,
                FriendRequest.receiver_id == user.id,
                FriendRequest.status == FriendRequestStatus.PENDING,
            )
        )
        req = result.scalar_one_or_none()
        if not req:
            raise NotFoundError("Friend request")

        req.status = FriendRequestStatus.ACCEPTED if accept else FriendRequestStatus.REJECTED
        await db.flush()

        if accept:
            await notification_service.create(
                db, req.sender_id, NotificationType.FRIEND_ACCEPTED,
                "Friend request accepted",
                f"{user.full_name} accepted your friend request",
                reference_id=str(req.id),
            )
            
            # 🔥 NEW: Automatically start a chat and send a system message
            from app.services.messaging_service import messaging_service
            conv = await messaging_service.get_or_create_conversation(db, user.id, req.sender_id)
            await messaging_service.save_message(
                db, conv.id, user.id, 
                "System: You are now friends! Say hi to your new friend."
            )
            
        return req

    async def get_friends(self, db: AsyncSession, user_id: uuid.UUID) -> list[User]:
        result = await db.execute(
            select(FriendRequest).where(
                and_(
                    FriendRequest.status == FriendRequestStatus.ACCEPTED,
                    or_(
                        FriendRequest.sender_id == user_id,
                        FriendRequest.receiver_id == user_id,
                    )
                )
            ).options(selectinload(FriendRequest.sender), selectinload(FriendRequest.receiver))
        )
        requests = result.scalars().all()
        friends = []
        for req in requests:
            friend = req.receiver if str(req.sender_id) == str(user_id) else req.sender
            friends.append(friend)
        return friends

    async def remove_friend(self, db: AsyncSession, user_id: uuid.UUID, friend_id: uuid.UUID) -> None:
        result = await db.execute(
            select(FriendRequest).where(
                FriendRequest.status == FriendRequestStatus.ACCEPTED,
                or_(
                    and_(FriendRequest.sender_id == user_id, FriendRequest.receiver_id == friend_id),
                    and_(FriendRequest.sender_id == friend_id, FriendRequest.receiver_id == user_id),
                )
            )
        )
        req = result.scalar_one_or_none()
        if not req:
            raise NotFoundError("Friendship")
            
        await db.delete(req)
        
        # 🔥 NEW: Automatically send a separation system message
        from app.services.messaging_service import messaging_service
        conv = await messaging_service.get_or_create_conversation(db, user_id, friend_id)
        await messaging_service.save_message(
            db, conv.id, user_id, 
            "System: You are no longer friends."
        )
        
        await db.flush()

    async def get_pending_requests(self, db: AsyncSession, user_id: uuid.UUID) -> list[FriendRequest]:
        result = await db.execute(
            select(FriendRequest).where(
                FriendRequest.receiver_id == user_id,
                FriendRequest.status == FriendRequestStatus.PENDING,
            ).options(selectinload(FriendRequest.sender))
        )
        return result.scalars().all()

    # ── Posts ─────────────────────────────────────────────────────────────────

    async def _get_friend_ids(self, db: AsyncSession, user_id: uuid.UUID) -> list[uuid.UUID]:
        friends = await self.get_friends(db, user_id)
        return [f.id for f in friends]

    async def create_post(self, db: AsyncSession, author: User, content: str) -> Post:
        post = Post(author_id=author.id, content=content)
        db.add(post)
        await db.flush()
        await db.refresh(post)
        return post

    async def get_feed(self, db: AsyncSession, user: User) -> list[dict]:
        friend_ids = await self._get_friend_ids(db, user.id)
        visible_ids = friend_ids + [user.id]

        result = await db.execute(
            select(Post).where(
                Post.author_id.in_(visible_ids),
                Post.is_deleted == False,
            )
            .options(selectinload(Post.author), selectinload(Post.likes))
            .order_by(Post.created_at.desc())
            .limit(50)
        )
        posts = result.scalars().all()

        return [
            {
                "id": str(p.id),
                "author": {"id": str(p.author_id), "full_name": p.author.full_name},
                "content": p.content,
                "like_count": len(p.likes),
                "liked_by_me": any(str(l.user_id) == str(user.id) for l in p.likes),
                "created_at": p.created_at.isoformat(),
            }
            for p in posts
        ]

    async def delete_post(self, db: AsyncSession, post_id: uuid.UUID, user: User) -> None:
        result = await db.execute(select(Post).where(Post.id == post_id))
        post = result.scalar_one_or_none()
        if not post:
            raise NotFoundError("Post")
        if str(post.author_id) != str(user.id):
            raise ForbiddenError("Not your post")
        post.is_deleted = True
        await db.flush()

    async def toggle_like(self, db: AsyncSession, post_id: uuid.UUID, user: User) -> bool:
        result = await db.execute(
            select(PostLike).where(PostLike.post_id == post_id, PostLike.user_id == user.id)
        )
        like = result.scalar_one_or_none()
        if like:
            await db.delete(like)
            await db.flush()
            return False
        else:
            post_result = await db.execute(select(Post).where(Post.id == post_id))
            post = post_result.scalar_one_or_none()
            if not post or post.is_deleted:
                raise NotFoundError("Post")
            new_like = PostLike(post_id=post_id, user_id=user.id)
            db.add(new_like)
            await db.flush()
            if str(post.author_id) != str(user.id):
                await notification_service.create(
                    db, post.author_id, NotificationType.POST_LIKE,
                    "New like",
                    f"{user.full_name} liked your post",
                    reference_id=str(post_id),
                )
            return True

    # ── Reports ───────────────────────────────────────────────────────────────

    async def report_message(
        self,
        db: AsyncSession,
        reporter: User,
        message_id: uuid.UUID,
        reported_user_id: uuid.UUID,
        report_type: ReportType,
        body: str,
    ) -> Report:
        report = Report(
            reporter_id=reporter.id,
            reported_user_id=reported_user_id,
            message_id=message_id,
            report_type=report_type,
            body=body,
        )
        db.add(report)
        await db.flush()
        return report


social_service = SocialService()