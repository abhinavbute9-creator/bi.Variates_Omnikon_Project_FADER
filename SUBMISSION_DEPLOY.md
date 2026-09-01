# FADER — Midnight Submission Deployment

## What this package is

This is the submission build of FADER. It intentionally uses **one public web service**:

- FastAPI serves the HTML/CSS/JS FADER interface.
- The same FastAPI process serves `/api/v1/*` and `/api/v1/ws/*`.
- The browser therefore talks to the backend on the **same public domain**.
- Visiting the domain root `/` automatically opens `/demo/`.

This avoids separate frontend/backend URLs, CORS configuration, and accidental `127.0.0.1` references in a public submission.

## Fastest deployment: Render + GitHub

1. Create a new GitHub repository, e.g. `fader-submission`.
2. Upload **the contents of this folder** to the repository root. `Dockerfile` and `render.yaml` must be at the repository root.
3. In Render choose **New → Web Service**.
4. Connect the GitHub repository.
5. Choose **Docker** if Render asks for a runtime. The included `Dockerfile` is complete.
6. Choose the **Free** compute plan if appropriate for the hackathon demo.
7. Set health check to `/health` if Render does not pick it up from `render.yaml`.
8. Deploy.
9. When Render reports **Live**, open the generated `https://<name>.onrender.com` URL.
10. That root URL should redirect directly to the FADER splash interface. Submit that root URL.

## Environment variables

None are mandatory for the demo.

Optional improvements:

- `MAPBOX_ACCESS_TOKEN=<real public Mapbox token>` — gives Mapbox roadway routing.
- `WEATHER_API_KEY=<Tomorrow.io key>` — gives live weather.

Without a Mapbox token, the backend attempts the public OSRM roadway service. If roadway routing cannot be reached, the UI intentionally hides the map instead of displaying a misleading straight-line route.

The database defaults to SQLite. On a free ephemeral service it can reset after a restart/redeploy; this is acceptable for a hackathon demo but not production persistence.

## What to test before submitting the URL

1. Root URL displays FADER splash.
2. Tap the pupil.
3. Nagpur → Hyderabad → `INITIALIZE ROUTING`.
4. Dashboard loads.
5. Backend indicator says online.
6. Road route appears if the route service is available.
7. Weather appears.
8. `ENGAGEMENT CHECK` refreshes the prompt.
9. `SEND TELEMETRY FRAME` increments telemetry.
10. `SIMULATE FATIGUE SIGNAL` records an event and changes risk state.
11. `END TRIP` closes the trip.
12. `/docs` opens FastAPI documentation.
13. `/health` returns JSON with `"status":"ok"`.

## Important demo truth

Real camera/MediaPipe EAR inference is not implemented in this build. The fatigue button is explicitly labelled as simulation. The backend fatigue-event recording, telemetry, risk calculation, CO2 model, route/weather calls, persistence, engagement endpoint and WebSocket workflow are real application code.
