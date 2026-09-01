from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.trip import Trip
from app.models.telemetry import Telemetry
from app.schemas.telemetry import TelemetryCreate, TelemetryResponse

router = APIRouter(prefix="/telemetry", tags=["Telemetry"])


@router.post("", response_model=TelemetryResponse, status_code=status.HTTP_201_CREATED)
def record_telemetry(payload: TelemetryCreate, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.id == payload.trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail=f"Trip with id {payload.trip_id} not found")

    telemetry = Telemetry(
        trip_id=payload.trip_id,
        latitude=payload.latitude,
        longitude=payload.longitude,
        speed=payload.speed,
        ear=payload.ear,
        fatigue_level=payload.fatigue_level or "LOW",
    )
    # Preserve an explicit device timestamp when supplied; otherwise let the
    # database server default stamp the row.
    if payload.timestamp is not None:
        telemetry.timestamp = payload.timestamp
    db.add(telemetry)
    db.commit()
    db.refresh(telemetry)
    return telemetry


@router.get("/trips/{trip_id}", response_model=List[TelemetryResponse])
def get_trip_telemetry(trip_id: int, limit: int = 50, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail=f"Trip with id {trip_id} not found")

    points = (
        db.query(Telemetry)
        .filter(Telemetry.trip_id == trip_id)
        .order_by(Telemetry.timestamp.desc())
        .limit(limit)
        .all()
    )
    return points
