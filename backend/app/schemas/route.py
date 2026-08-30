from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field


class RouteRequest(BaseModel):
    start_lat: float = Field(..., ge=-90, le=90)
    start_lng: float = Field(..., ge=-180, le=180)
    destination_lat: float = Field(..., ge=-90, le=90)
    destination_lng: float = Field(..., ge=-180, le=180)


class RouteGeometry(BaseModel):
    type: str = "LineString"
    coordinates: List[List[float]]


class RouteResponse(BaseModel):
    distance_km: float
    duration_minutes: float
    geometry: RouteGeometry
    source: str = "mapbox"  # "mapbox" or "fallback_simulated"
