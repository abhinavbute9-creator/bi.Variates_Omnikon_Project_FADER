from fastapi import APIRouter, HTTPException, status
from app.schemas.risk import RiskAssessmentRequest, RiskResponse
from app.services.risk_service import RiskService

router = APIRouter(prefix="/risk", tags=["Risk Engine"])


@router.post("/calculate", response_model=RiskResponse, status_code=status.HTTP_200_OK)
def calculate_risk_score(payload: RiskAssessmentRequest):
    try:
        return RiskService.calculate_risk(payload)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Risk calculation failure: {str(e)}"
        )
