import json
from fastapi import WebSocket
from typing import Dict


class ConnectionManager:
    def __init__(self):
        # user_id -> WebSocket
        self._connections: Dict[str, WebSocket] = {}

    async def connect(self, user_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections[user_id] = websocket

    def disconnect(self, user_id: str) -> None:
        self._connections.pop(user_id, None)

    def is_connected(self, user_id: str) -> bool:
        return user_id in self._connections

    async def send(self, user_id: str, payload: dict) -> bool:
        """Send to a specific user. Returns True if delivered."""
        ws = self._connections.get(user_id)
        if ws:
            try:
                await ws.send_text(json.dumps(payload))
                return True
            except Exception:
                self.disconnect(user_id)
        return False

    async def broadcast(self, user_ids: list[str], payload: dict) -> None:
        for user_id in user_ids:
            await self.send(user_id, payload)


manager = ConnectionManager()