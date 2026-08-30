from typing import Optional, Dict, Any
import httpx
import math
from app.core.config import settings
from app.schemas.route import RouteResponse, RouteGeometry


class MapboxService:
    BASE_URL = "https://api.mapbox.com/directions/v5/mapbox/driving"

    @classmethod
    def _haversine_distance_km(cls, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371.0
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = (
            math.sin(d_lat / 2) ** 2
            + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return round(R * c, 2)

    @classmethod
    def _get_fallback_route(
        cls, start_lat: float, start_lng: float, dest_lat: float, dest_lng: float
    ) -> RouteResponse:
        dist_km = cls._haversine_distance_km(start_lat, start_lng, dest_lat, dest_lng)
        # Assume average highway speed of 60 km/h
        duration_mins = round((dist_km / 60.0) * 60.0, 1)

        # Generate interpolated coordinates between start and destination
        steps = 10
        coordinates = []
        for i in range(steps + 1):
            fraction = i / steps
            lat = start_lat + (dest_lat - start_lat) * fraction
            lng = start_lng + (dest_lng - start_lng) * fraction
            coordinates.append([round(lng, 6), round(lat, 6)])

        return RouteResponse(
            distance_km=dist_km,
            duration_minutes=duration_mins,
            geometry=RouteGeometry(type="LineString", coordinates=coordinates),
            source="fallback_simulated"
        )

    @classmethod
    async def calculate_route(
        cls, start_lat: float, start_lng: float, dest_lat: float, dest_lng: float
    ) -> RouteResponse:
        token = settings.MAPBOX_ACCESS_TOKEN
        if not token or token.startswith("pk.demo"):
            return cls._get_fallback_route(start_lat, start_lng, dest_lat, dest_lng)

        url = f"{cls.BASE_URL}/{start_lng},{start_lat};{dest_lng},{dest_lat}"
        params = {
            "access_token": token,
            "geometries": "geojson",
            "overview": "full"
        }

        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                response = await client.get(url, params=params)
                if response.status_code != 200:
                    return cls._get_fallback_route(start_lat, start_lng, dest_lat, dest_lng)

                data = response.json()
                routes = data.get("routes", [])
                if not routes:
                    return cls._get_fallback_route(start_lat, start_lng, dest_lat, dest_lng)

                primary_route = routes[0]
                distance_km = round(primary_route.get("distance", 0) / 1000.0, 2)
                duration_mins = round(primary_route.get("duration", 0) / 60.0, 1)
                coordinates = primary_route.get("geometry", {}).get("coordinates", [])

                return RouteResponse(
                    distance_km=distance_km,
                    duration_minutes=duration_mins,
                    geometry=RouteGeometry(type="LineString", coordinates=coordinates),
                    source="mapbox"
                )
        except Exception:
            return cls._get_fallback_route(start_lat, start_lng, dest_lat, dest_lng)
