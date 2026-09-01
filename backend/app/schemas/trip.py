from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class Coordinates(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class TripCreate(BaseModel):
    driver_id: int
    start: Coordinates
    destination: Coordinates


class TripEnd(BaseModel):
    status: str = "completed"


class TripResponse(BaseModel):
    id: int
    driver_id: int
    status: str
    start_lat: float
    start_lng: float
    dest_lat: float
    dest_lng: float
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
