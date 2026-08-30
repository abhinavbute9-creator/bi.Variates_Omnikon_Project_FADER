from fastapi import APIRouter, HTTPException, status
from app.schemas.co2 import CO2PredictionRequest, CO2PredictionResponse
from app.services.co2_service import CO2Service

router = APIRouter(prefix="/co2", tags=["CO2 Forecasting"])


@router.post("/predict", response_model=CO2PredictionResponse, status_code=status.HTTP_200_OK)
def predict_cabin_co2(payload: CO2PredictionRequest):
    try:
        return CO2Service.predict_co2(payload)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"CO2 calculation failure: {str(e)}"
        )
