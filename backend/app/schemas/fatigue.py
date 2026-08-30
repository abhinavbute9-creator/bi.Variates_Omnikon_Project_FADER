from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field


class FatigueEventCreate(BaseModel):
    trip_id: int
    event_type: str = Field(..., description="MICROSLEEP, YAWN, DISTRACTION, HEAD_NOD")
    severity: str = Field(..., description="LOW, MEDIUM, HIGH, CRITICAL")
    ear: Optional[float] = Field(None, ge=0.0, le=1.0, description="Eye Aspect Ratio")
    blink_duration_ms: Optional[int] = Field(None, ge=0, description="Blink duration in milliseconds")
    head_pose: Optional[str] = Field(None, description="FORWARD, LEFT, RIGHT, DOWN, UP")
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)


class FatigueEventResponse(BaseModel):
    id: int
    trip_id: int
    event_type: str
    severity: str
    ear: Optional[float]
    blink_duration_ms: Optional[int]
    head_pose: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)


class FatigueSummaryResponse(BaseModel):
    trip_id: int
    total_events: int
    critical_events: int
    high_events: int
    events: List[FatigueEventResponse]
