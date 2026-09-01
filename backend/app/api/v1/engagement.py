from typing import Optional
from fastapi import APIRouter, Query, HTTPException, status
from app.schemas.engagement import EngagementTriviaResponse
from app.services.llm_service import LLMService

router = APIRouter(prefix="/engagement", tags=["Driver Engagement"])


@router.get("/trivia", response_model=EngagementTriviaResponse, status_code=status.HTTP_200_OK)
def get_engagement_trivia(
    location: Optional[str] = Query(None, description="Current city, town, or landmark name")
):
    try:
        return LLMService.get_location_trivia(location=location)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Engagement service error: {str(e)}"
        )
