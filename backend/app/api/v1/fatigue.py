from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.trip import Trip
from app.models.fatigue_event import FatigueEvent
from app.schemas.fatigue import FatigueEventCreate, FatigueEventResponse, FatigueSummaryResponse

router = APIRouter(prefix="/fatigue", tags=["Fatigue"])


@router.post("/events", response_model=FatigueEventResponse, status_code=status.HTTP_201_CREATED)
def record_fatigue_event(payload: FatigueEventCreate, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.id == payload.trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail=f"Trip with id {payload.trip_id} not found")

    event = FatigueEvent(
        trip_id=payload.trip_id,
        event_type=payload.event_type.upper(),
        severity=payload.severity.upper(),
        ear=payload.ear,
        blink_duration_ms=payload.blink_duration_ms,
        head_pose=payload.head_pose.upper() if payload.head_pose else None,
        latitude=payload.latitude,
        longitude=payload.longitude,
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


@router.get("/trips/{trip_id}", response_model=FatigueSummaryResponse)
def get_trip_fatigue_history(trip_id: int, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail=f"Trip with id {trip_id} not found")

    events = (
        db.query(FatigueEvent)
        .filter(FatigueEvent.trip_id == trip_id)
        .order_by(FatigueEvent.timestamp.desc())
        .all()
    )

    critical_count = sum(1 for e in events if e.severity == "CRITICAL")
    high_count = sum(1 for e in events if e.severity == "HIGH")

    return FatigueSummaryResponse(
        trip_id=trip_id,
        total_events=len(events),
        critical_events=critical_count,
        high_events=high_count,
        events=events
    )
