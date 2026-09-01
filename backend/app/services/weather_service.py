import httpx
from typing import Optional
from app.core.config import settings
from app.schemas.weather import WeatherResponse


class WeatherService:
    TOMORROW_URL = "https://api.tomorrow.io/v4/weather/realtime"

    @classmethod
    def _get_fallback_weather(cls, latitude: float, longitude: float) -> WeatherResponse:
        return WeatherResponse(
            temperature=28.4,
            humidity=65.0,
            wind_speed=14.2,
            rain_intensity=0.0,
            condition="Partly Cloudy",
            source="fallback_simulated"
        )

    @classmethod
    async def get_current_weather(cls, latitude: float, longitude: float) -> WeatherResponse:
        api_key = getattr(settings, "WEATHER_API_KEY", None)
        if not api_key or api_key.startswith("demo_"):
            return cls._get_fallback_weather(latitude, longitude)

        params = {
            "location": f"{latitude},{longitude}",
            "apikey": api_key,
            "units": "metric"
        }

        try:
            async with httpx.AsyncClient(timeout=6.0) as client:
                res = await client.get(cls.TOMORROW_URL, params=params)
                if res.status_code != 200:
                    return cls._get_fallback_weather(latitude, longitude)

                data = res.json().get("data", {}).get("values", {})
                temp = float(data.get("temperature", 28.0))
                humidity = float(data.get("humidity", 60.0))
                wind = float(data.get("windSpeed", 10.0))
                rain = float(data.get("rainIntensity", 0.0))

                condition = "Clear"
                if rain > 1.5:
                    condition = "Heavy Rain"
                elif rain > 0.0:
                    condition = "Rainy"
                elif humidity > 80:
                    condition = "Overcast"
                elif humidity > 60:
                    condition = "Partly Cloudy"

                return WeatherResponse(
                    temperature=round(temp, 1),
                    humidity=round(humidity, 1),
                    wind_speed=round(wind, 1),
                    rain_intensity=round(rain, 1),
                    condition=condition,
                    source="tomorrow.io"
                )
        except Exception:
            return cls._get_fallback_weather(latitude, longitude)
