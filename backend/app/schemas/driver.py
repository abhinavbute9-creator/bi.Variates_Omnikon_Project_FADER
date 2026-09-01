from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class DriverBase(BaseModel):
    name: str
    phone: Optional[str] = None
    vehicle_id: str


class DriverCreate(DriverBase):
    pass


class DriverUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    vehicle_id: Optional[str] = None


class DriverResponse(DriverBase):
    id: int
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
