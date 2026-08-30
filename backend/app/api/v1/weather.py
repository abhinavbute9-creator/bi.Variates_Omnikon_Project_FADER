from fastapi import APIRouter, Query, HTTPException, status
from app.schemas.weather import WeatherResponse
from app.services.weather_service import WeatherService

router = APIRouter(prefix="/weather", tags=["Weather"])


@router.get("", response_model=WeatherResponse, status_code=status.HTTP_200_OK)
async def get_weather(
    latitude: float = Query(..., ge=-90, le=90, description="Latitude coordinate"),
    longitude: float = Query(..., ge=-180, le=180, description="Longitude coordinate"),
):
    try:
        weather = await WeatherService.get_current_weather(latitude=latitude, longitude=longitude)
        return weather
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Weather retrieval failed: {str(e)}"
        )
