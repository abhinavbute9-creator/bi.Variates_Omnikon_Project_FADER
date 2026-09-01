from pydantic import BaseModel, Field


class CO2PredictionRequest(BaseModel):
    trip_id: int
    duration_minutes: float = Field(..., ge=0.0, description="Elapsed drive duration in minutes")
    ventilation_factor: float = Field(default=1.0, ge=0.1, le=2.0, description="1.0 standard, <1.0 recirculating, >1.0 fresh air")


class CO2PredictionResponse(BaseModel):
    trip_id: int
    estimated_co2_ppm: int = Field(..., description="Estimated cabin CO2 in parts-per-million")
    air_quality_level: str = Field(..., description="OPTIMAL, MODERATE, ELEVATED, HAZARDOUS")
    break_recommended: bool
    action_prompt: str
    model_type: str = "prototype_simulation_model"
