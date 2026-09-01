from typing import Dict, Any, Optional
from pydantic import BaseModel, Field


class RiskAssessmentRequest(BaseModel):
    trip_id: int
    current_ear: Optional[float] = Field(0.28, ge=0.0, le=1.0)
    recent_fatigue_events: Optional[int] = Field(0, ge=0)
    trip_duration_minutes: Optional[float] = Field(0.0, ge=0.0)
    weather_condition: Optional[str] = "Clear"
    rain_intensity: Optional[float] = 0.0


class FactorBreakdown(BaseModel):
    fatigue_factor: float
    duration_factor: float
    weather_factor: float
    circadian_factor: float


class RiskResponse(BaseModel):
    score: int = Field(..., ge=0, le=100, description="Composite risk score 0-100")
    level: str = Field(..., description="LOW, MODERATE, HIGH, CRITICAL")
    factors: FactorBreakdown
    model_type: str = "prototype_transparent_v1"
