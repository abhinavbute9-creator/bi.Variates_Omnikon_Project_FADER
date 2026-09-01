from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class Trip(Base):
    __tablename__ = "trips"

    id = Column(Integer, primary_key=True, index=True)
    driver_id = Column(Integer, ForeignKey("drivers.id"), nullable=False)
    status = Column(String(20), default="active", nullable=False)
    
    start_lat = Column(Float, nullable=False)
    start_lng = Column(Float, nullable=False)
    dest_lat = Column(Float, nullable=False)
    dest_lng = Column(Float, nullable=False)

    started_at = Column(DateTime(timezone=True), server_default=func.now())
    ended_at = Column(DateTime(timezone=True), nullable=True)

    driver = relationship("Driver", back_populates="trips")
    telemetry = relationship("Telemetry", back_populates="trip")
    fatigue_events = relationship("FatigueEvent", back_populates="trip")
    engagement_events = relationship("EngagementEvent", back_populates="trip")
