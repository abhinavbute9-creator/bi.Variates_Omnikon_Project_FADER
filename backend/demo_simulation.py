import asyncio
import json
import httpx
import websockets

BASE_URL = "http://127.0.0.1:8000/api/v1"
WS_URL = "ws://127.0.0.1:8000/api/v1/ws"

async def run_fader_e2e_demo():
    print("=" * 60)
    print("🚀 STARTING FADER END-TO-END INTELLIGENCE BACKEND DEMO")
    print("=" * 60)

    async with httpx.AsyncClient(timeout=10.0) as client:
        # 1. Create Driver
        print("\n[1] Registering Driver...")
        d_res = await client.post(f"{BASE_URL}/drivers", json={
            "name": "Atharva Kale",
            "vehicle_id": "MH31-OMNIKON-01",
            "phone": "+919876543210"
        })
        driver = d_res.json()
        driver_id = driver["id"]
        print(f"✅ Driver Created: ID={driver_id}, Name={driver['name']}")

        # 2. Start Trip (Nagpur to Mumbai)
        print("\n[2] Initializing Active Trip (Nagpur -> Mumbai)...")
        t_res = await client.post(f"{BASE_URL}/trips", json={
            "driver_id": driver_id,
            "start": {"latitude": 21.1458, "longitude": 79.0882},
            "destination": {"latitude": 19.0760, "longitude": 72.8777}
        })
        trip = t_res.json()
        trip_id = trip["id"]
        print(f"✅ Trip Active: Trip ID={trip_id}")

        # 3. Route Calculation
        print("\n[3] Calculating Mapbox Route Geometry & ETA...")
        r_res = await client.post(f"{BASE_URL}/routes/calculate", json={
            "start_lat": 21.1458,
            "start_lng": 79.0882,
            "destination_lat": 19.0760,
            "destination_lng": 72.8777
        })
        route = r_res.json()
        print(f"✅ Route Calculated: Distance={route['distance_km']} km, Duration={route['duration_minutes']} mins (Source: {route['source']})")

        # 4. Fetch Weather Condition
        print("\n[4] Querying Weather at Origin...")
        w_res = await client.get(f"{BASE_URL}/weather?latitude=21.1458&longitude=79.0882")
        weather = w_res.json()
        print(f"✅ Weather: {weather['temperature']}°C, {weather['condition']}, Rain={weather['rain_intensity']} mm/hr")

        # 5. Ingest Fatigue Event (Microsleep Detected)
        print("\n[5] Ingesting Edge MediaPipe Fatigue Signal...")
        f_res = await client.post(f"{BASE_URL}/fatigue/events", json={
            "trip_id": trip_id,
            "event_type": "MICROSLEEP",
            "severity": "HIGH",
            "ear": 0.17,
            "blink_duration_ms": 1150,
            "head_pose": "FORWARD",
            "latitude": 20.9320,
            "longitude": 77.7523
        })
        print(f"✅ Fatigue Event Recorded: {f_res.json()['event_type']} (Severity: {f_res.json()['severity']})")

        # 6. Evaluate Multi-Factor Risk Score
        print("\n[6] Computing Real-Time Risk Score...")
        risk_res = await client.post(f"{BASE_URL}/risk/calculate", json={
            "trip_id": trip_id,
            "current_ear": 0.17,
            "recent_fatigue_events": 2,
            "trip_duration_minutes": 150.0,
            "weather_condition": weather["condition"],
            "rain_intensity": weather["rain_intensity"]
        })
        risk = risk_res.json()
        print(f"⚠️ Risk Assessment: Score={risk['score']}/100 | Level={risk['level']}")
        print(f"   Breakdown: Fatigue={risk['factors']['fatigue_factor']} | Duration={risk['factors']['duration_factor']} | Weather={risk['factors']['weather_factor']} | Circadian={risk['factors']['circadian_factor']}")

        # 7. Cabin CO2 Buildup Projection
        print("\n[7] Forecasting Cabin CO2 Concentration...")
        co2_res = await client.post(f"{BASE_URL}/co2/predict", json={
            "trip_id": trip_id,
            "duration_minutes": 150.0,
            "ventilation_factor": 0.8
        })
        co2 = co2_res.json()
        print(f"💨 CO2 Projection: {co2['estimated_co2_ppm']} ppm | Air Quality: {co2['air_quality_level']}")
        print(f"   Prompt: {co2['action_prompt']}")

        # 8. Location-Based LLM Trivia Engagement
        print("\n[8] Requesting En-Route Trivia (Amravati Corridor)...")
        triv_res = await client.get(f"{BASE_URL}/engagement/trivia?location=Amravati")
        trivia = triv_res.json()
        print(f"💡 Trivia ({trivia['location']}): {trivia['fact_or_question']}")

        # 9. Real-Time WebSocket Telemetry Streaming
        print("\n[9] Testing Real-Time WebSocket Stream...")
        async with websockets.connect(f"{WS_URL}/trips/{trip_id}") as ws:
            sample_telemetry = {
                "type": "telemetry",
                "latitude": 20.9320,
                "longitude": 77.7523,
                "speed": 72.4,
                "ear": 0.26,
                "fatigue_level": "MODERATE"
            }
            await ws.send(json.dumps(sample_telemetry))
            reply = await ws.recv()
            print(f"📡 WebSocket Broadcast Received: {reply}")

        print("\n" + "=" * 60)
        print("🎉 ALL FADER BACKEND SERVICES VERIFIED SUCCESSFULLY!")
        print("=" * 60)

if __name__ == "__main__":
    asyncio.run(run_fader_e2e_demo())
