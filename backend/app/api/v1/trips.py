from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.driver import Driver
from app.models.trip import Trip
from app.schemas.trip import TripCreate, TripResponse

router = APIRouter(prefix="/trips", tags=["Trips"])


@router.post("", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
def create_trip(payload: TripCreate, db: Session = Depends(get_db)):
    # Verify driver exists
    driver = db.query(Driver).filter(Driver.id == payload.driver_id).first()
    if not driver:
        raise HTTPException(status_code=404, detail=f"Driver with id {payload.driver_id} not found")

    trip = Trip(
        driver_id=payload.driver_id,
        status="active",
        start_lat=payload.start.latitude,
        start_lng=payload.start.longitude,
        dest_lat=payload.destination.latitude,
        dest_lng=payload.destination.longitude,
    )
    db.add(trip)
    db.commit()
    db.refresh(trip)
    return trip


@router.get("/{trip_id}", response_model=TripResponse)
def get_trip(trip_id: int, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail=f"Trip with id {trip_id} not found")
    return trip


@router.post("/{trip_id}/end", response_model=TripResponse)
def end_trip(trip_id: int, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail=f"Trip with id {trip_id} not found")

    if trip.status == "completed":
        return trip

    trip.status = "completed"
    trip.ended_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(trip)
    return trip


@router.get("/driver/{driver_id}", response_model=List[TripResponse])
def get_driver_trips(driver_id: int, db: Session = Depends(get_db)):
    driver = db.query(Driver).filter(Driver.id == driver_id).first()
    if not driver:
        raise HTTPException(status_code=404, detail=f"Driver with id {driver_id} not found")

    trips = db.query(Trip).filter(Trip.driver_id == driver_id).order_by(Trip.started_at.desc()).all()
    return trips
