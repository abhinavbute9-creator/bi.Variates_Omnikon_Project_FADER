from fastapi import APIRouter, HTTPException, status
from app.schemas.route import RouteRequest, RouteResponse
from app.services.mapbox_service import MapboxService

router = APIRouter(prefix="/routes", tags=["Routes"])


@router.post("/calculate", response_model=RouteResponse, status_code=status.HTTP_200_OK)
async def calculate_route(payload: RouteRequest):
    try:
        route = await MapboxService.calculate_route(
            start_lat=payload.start_lat,
            start_lng=payload.start_lng,
            dest_lat=payload.destination_lat,
            dest_lng=payload.destination_lng
        )
        return route
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Route calculation error: {str(e)}"
        )
