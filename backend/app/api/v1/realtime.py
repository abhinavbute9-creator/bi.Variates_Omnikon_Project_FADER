import json
from datetime import datetime, timezone
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.websocket.manager import manager

router = APIRouter(tags=["Real-time"])


@router.websocket("/ws/trips/{trip_id}")
async def trip_realtime_websocket(websocket: WebSocket, trip_id: int):
    await manager.connect(trip_id, websocket)
    try:
        while True:
            raw_data = await websocket.receive_text()
            try:
                data = json.loads(raw_data)
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({"error": "INVALID_JSON"}))
                continue

            # Process incoming telemetry or ping message
            msg_type = data.get("type", "telemetry")
            if msg_type == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))
                continue

            # Extract metrics sent from device
            speed = data.get("speed", 0.0)
            ear = data.get("ear", 0.28)
            fatigue_lvl = data.get("fatigue_level", "LOW")
            lat = data.get("latitude", 0.0)
            lng = data.get("longitude", 0.0)

            # Compute real-time response payload for Flutter dashboard
            response_payload = {
                "type": "trip_update",
                "trip_id": trip_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "location": {
                    "latitude": lat,
                    "longitude": lng,
                },
                "telemetry": {
                    "speed": speed,
                    "ear": ear,
                },
                "fatigue": {
                    "level": fatigue_lvl,
                },
                "status": "active"
            }

            # Broadcast to all listeners subscribed to this trip_id
            await manager.broadcast_to_trip(trip_id, response_payload)

    except WebSocketDisconnect:
        manager.disconnect(trip_id, websocket)
    except Exception:
        manager.disconnect(trip_id, websocket)
