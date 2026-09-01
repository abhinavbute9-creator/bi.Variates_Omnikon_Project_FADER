"""End-to-end smoke test for the FADER backend and bundled browser demo.

Runs against a temporary SQLite database so it never mutates backend/fader.db.
Execute from backend/ with:
    python scripts/smoke_test.py
"""
from __future__ import annotations

import os
import sys
import tempfile
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

# Environment must be configured before importing the app/database modules.
_tmp_dir = tempfile.TemporaryDirectory(prefix="fader_smoke_")
_db_path = Path(_tmp_dir.name) / "fader_smoke.db"
os.environ["DATABASE_URL"] = f"sqlite:///{_db_path.as_posix()}"
os.environ["MAPBOX_ACCESS_TOKEN"] = "pk.demo_token_fader"
os.environ["WEATHER_API_KEY"] = "demo_weather_key"

from fastapi.testclient import TestClient  # noqa: E402
from app.core.database import Base, engine  # noqa: E402
import app.models.driver  # noqa: F401,E402
import app.models.trip  # noqa: F401,E402
import app.models.telemetry  # noqa: F401,E402
import app.models.fatigue_event  # noqa: F401,E402
import app.models.engagement  # noqa: F401,E402
from app.main import app  # noqa: E402


def assert_status(response, expected: int = 200):
    assert response.status_code == expected, f"{response.request.method} {response.request.url}: {response.status_code} {response.text}"
    return response


def main() -> None:
    Base.metadata.create_all(bind=engine)
    client = TestClient(app)

    assert_status(client.get("/"))
    assert_status(client.get("/health"))
    demo = assert_status(client.get("/demo/"))
    assert "FADER" in demo.text and "INITIALIZE ROUTING" in demo.text
    assert_status(client.get("/demo/app.js"))
    assert_status(client.get("/demo/styles.css"))

    driver = assert_status(
        client.post("/api/v1/drivers", json={"name": "Smoke Driver", "phone": None, "vehicle_id": "SMOKE-01"}),
        201,
    ).json()
    updated = assert_status(
        client.put(f"/api/v1/drivers/{driver['id']}", json={"vehicle_id": "SMOKE-02"})
    ).json()
    assert updated["vehicle_id"] == "SMOKE-02"

    trip = assert_status(
        client.post(
            "/api/v1/trips",
            json={
                "driver_id": driver["id"],
                "start": {"latitude": 21.1458, "longitude": 79.0882},
                "destination": {"latitude": 17.3850, "longitude": 78.4867},
            },
        ),
        201,
    ).json()
    trip_id = trip["id"]

    route = assert_status(
        client.post(
            "/api/v1/routes/calculate",
            json={
                "start_lat": 21.1458,
                "start_lng": 79.0882,
                "destination_lat": 17.3850,
                "destination_lng": 78.4867,
            },
        )
    ).json()
    assert route["distance_km"] > 0 and len(route["geometry"]["coordinates"]) >= 2

    weather = assert_status(client.get("/api/v1/weather?latitude=21.1458&longitude=79.0882")).json()
    assert "temperature" in weather and "condition" in weather

    trivia = assert_status(client.get("/api/v1/engagement/trivia?location=Nagpur")).json()
    assert trivia["fact_or_question"]

    risk = assert_status(
        client.post(
            "/api/v1/risk/calculate",
            json={
                "trip_id": trip_id,
                "current_ear": 0.17,
                "recent_fatigue_events": 3,
                "trip_duration_minutes": 180,
                "weather_condition": weather["condition"],
                "rain_intensity": weather["rain_intensity"],
            },
        )
    ).json()
    assert 0 <= risk["score"] <= 100

    co2 = assert_status(
        client.post("/api/v1/co2/predict", json={"trip_id": trip_id, "duration_minutes": 180, "ventilation_factor": 1.0})
    ).json()
    assert co2["estimated_co2_ppm"] >= 420

    telemetry = assert_status(
        client.post(
            "/api/v1/telemetry",
            json={
                "trip_id": trip_id,
                "latitude": 21.1458,
                "longitude": 79.0882,
                "speed": 62,
                "ear": 0.24,
                "fatigue_level": "MODERATE",
            },
        ),
        201,
    ).json()
    assert telemetry["trip_id"] == trip_id

    event = assert_status(
        client.post(
            "/api/v1/fatigue/events",
            json={
                "trip_id": trip_id,
                "event_type": "MICROSLEEP",
                "severity": "HIGH",
                "ear": 0.17,
                "blink_duration_ms": 1100,
                "head_pose": "DOWN",
                "latitude": 21.1458,
                "longitude": 79.0882,
            },
        ),
        201,
    ).json()
    assert event["severity"] == "HIGH"

    summary = assert_status(client.get(f"/api/v1/fatigue/trips/{trip_id}")).json()
    assert summary["total_events"] == 1 and summary["high_events"] == 1
    history = assert_status(client.get(f"/api/v1/telemetry/trips/{trip_id}?limit=10")).json()
    assert len(history) == 1

    with client.websocket_connect(f"/api/v1/ws/trips/{trip_id}") as socket:
        socket.send_json({"type": "ping"})
        assert socket.receive_json()["type"] == "pong"
        socket.send_json(
            {
                "type": "telemetry",
                "speed": 63,
                "ear": 0.23,
                "fatigue_level": "MODERATE",
                "latitude": 21.1458,
                "longitude": 79.0882,
            }
        )
        ws_update = socket.receive_json()
        assert ws_update["type"] == "trip_update" and ws_update["trip_id"] == trip_id

    ended = assert_status(client.post(f"/api/v1/trips/{trip_id}/end")).json()
    assert ended["status"] == "completed"

    print("FADER smoke test: PASS")
    print(f"  driver={driver['id']} trip={trip_id}")
    print(f"  route={route['distance_km']} km / {route['duration_minutes']} min ({route['source']})")
    print(f"  weather={weather['temperature']} C {weather['condition']} ({weather['source']})")
    print(f"  risk={risk['score']}/100 {risk['level']}")
    print(f"  co2={co2['estimated_co2_ppm']} ppm {co2['air_quality_level']}")
    print("  HTTP persistence + WebSocket + browser demo assets verified")


if __name__ == "__main__":
    try:
        main()
    finally:
        _tmp_dir.cleanup()
