from fastapi import APIRouter
from app.api.v1.drivers import router as drivers_router
from app.api.v1.trips import router as trips_router
from app.api.v1.routes import router as routes_router
from app.api.v1.weather import router as weather_router
from app.api.v1.fatigue import router as fatigue_router
from app.api.v1.telemetry import router as telemetry_router
from app.api.v1.realtime import router as realtime_router
from app.api.v1.risk import router as risk_router
from app.api.v1.co2 import router as co2_router
from app.api.v1.engagement import router as engagement_router

api_router = APIRouter()
api_router.include_router(drivers_router)
api_router.include_router(trips_router)
api_router.include_router(routes_router)
api_router.include_router(weather_router)
api_router.include_router(fatigue_router)
api_router.include_router(telemetry_router)
api_router.include_router(realtime_router)
api_router.include_router(risk_router)
api_router.include_router(co2_router)
api_router.include_router(engagement_router)
