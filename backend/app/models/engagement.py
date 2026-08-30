from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class EngagementEvent(Base):
    __tablename__ = "engagement_events"

    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=False)
    prompt_text = Column(String(500), nullable=False)
    location_name = Column(String(100), nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

    trip = relationship("Trip", back_populates="engagement_events")
