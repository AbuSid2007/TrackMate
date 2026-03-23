import json
from datetime import datetime, timezone
from app.core.redis import get_redis
import secrets

PRESENCE_TTL = 35  # seconds — slightly more than heartbeat interval (30s)


class PresenceService:

    async def set_online(self, user_id: str) -> None:
        redis = await get_redis()
        await redis.setex(f"presence:{user_id}", PRESENCE_TTL, "online")
        await redis.set(
            f"last_seen:{user_id}",
            datetime.now(timezone.utc).isoformat(),
        )

    async def set_offline(self, user_id: str) -> None:
        redis = await get_redis()
        await redis.delete(f"presence:{user_id}")
        await redis.set(
            f"last_seen:{user_id}",
            datetime.now(timezone.utc).isoformat(),
        )

    async def is_online(self, user_id: str) -> bool:
        redis = await get_redis()
        return await redis.exists(f"presence:{user_id}") == 1

    async def get_last_seen(self, user_id: str) -> str | None:
        redis = await get_redis()
        return await redis.get(f"last_seen:{user_id}")

    async def set_typing(self, conversation_id: str, user_id: str) -> None:
        redis = await get_redis()
        await redis.setex(f"typing:{conversation_id}:{user_id}", 5, "1")

    async def is_typing(self, conversation_id: str, user_id: str) -> bool:
        redis = await get_redis()
        return await redis.exists(f"typing:{conversation_id}:{user_id}") == 1

    async def heartbeat(self, user_id: str) -> None:
        """Refresh presence TTL — called every 30s from client."""
        redis = await get_redis()
        await redis.setex(f"presence:{user_id}", PRESENCE_TTL, "online")


    async def create_ws_ticket(self, user_id: str) -> str:
        redis = await get_redis()
        ticket = secrets.token_urlsafe(32)
        await redis.setex(f"ws_ticket:{ticket}", 30, user_id)
        return ticket

    async def consume_ws_ticket(self, ticket: str) -> str | None:
        """Returns user_id if valid, None if invalid or expired."""
        redis = await get_redis()
        user_id = await redis.get(f"ws_ticket:{ticket}")
        if user_id:
            await redis.delete(f"ws_ticket:{ticket}")  # one-time use
        return user_id


presence_service = PresenceService()