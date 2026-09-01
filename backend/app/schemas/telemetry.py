from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, ConfigDict, Field


class TelemetryCreate(BaseModel):
    trip_id: int
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    speed: float = Field(..., ge=0.0, description="Speed in km/h")
    ear: Optional[float] = Field(None, ge=0.0, le=1.0, description="Eye Aspect Ratio")
    fatigue_level: Optional[str] = Field("LOW", description="LOW, MODERATE, HIGH, CRITICAL")
    timestamp: Optional[datetime] = None


class TelemetryResponse(BaseModel):
    id: int
    trip_id: int
    latitude: float
    longitude: float
    speed: float
    ear: Optional[float]
    fatigue_level: str
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)


class LiveTelemetryMessage(BaseModel):
    type: str = "telemetry"
    timestamp: Optional[str] = None
    latitude: float
    longitude: float
    speed: float
    ear: Optional[float] = 0.28
    fatigue_level: Optional[str] = "LOW"
