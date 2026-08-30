from pydantic import BaseModel, Field


class WeatherResponse(BaseModel):
    temperature: float = Field(..., description="Temperature in Celsius")
    humidity: float = Field(..., description="Humidity percentage (0-100)")
    wind_speed: float = Field(..., description="Wind speed in km/h")
    rain_intensity: float = Field(default=0.0, description="Rain intensity in mm/hr")
    condition: str = Field(..., description="Normalized condition (e.g. Clear, Cloudy, Rainy)")
    source: str = Field(default="live", description="Data source: live or fallback_simulated")
