from typing import Optional
import math

import httpx

from app.core.config import settings
from app.schemas.route import RouteResponse, RouteGeometry


class MapboxService:
    """Road routing with resilient public-demo fallbacks.

    Order of preference:
    1. Mapbox Directions when a real token is configured.
    2. OSRM's public routing service for a real roadway geometry without a key.
    3. A Haversine estimate with straight interpolation, clearly labelled as simulated.

    The frontend hides the map when only the simulated fallback is available so a
    straight line is never presented as a real roadway route.
    """

    MAPBOX_URL = "https://api.mapbox.com/directions/v5/mapbox/driving"
    OSRM_URL = "https://router.project-osrm.org/route/v1/driving"

    @classmethod
    def _haversine_distance_km(cls, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        radius_km = 6371.0
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = (
            math.sin(d_lat / 2) ** 2
            + math.cos(math.radians(lat1))
            * math.cos(math.radians(lat2))
            * math.sin(d_lon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return round(radius_km * c, 2)

    @classmethod
    def _get_fallback_route(
        cls,
        start_lat: float,
        start_lng: float,
        dest_lat: float,
        dest_lng: float,
    ) -> RouteResponse:
        dist_km = cls._haversine_distance_km(start_lat, start_lng, dest_lat, dest_lng)
        duration_mins = round(dist_km, 1)  # 60 km/h demo assumption

        coordinates = []
        steps = 10
        for i in range(steps + 1):
            fraction = i / steps
            lat = start_lat + (dest_lat - start_lat) * fraction
            lng = start_lng + (dest_lng - start_lng) * fraction
            coordinates.append([round(lng, 6), round(lat, 6)])

        return RouteResponse(
            distance_km=dist_km,
            duration_minutes=duration_mins,
            geometry=RouteGeometry(type="LineString", coordinates=coordinates),
            source="fallback_simulated",
        )

    @classmethod
    async def _mapbox_route(
        cls,
        client: httpx.AsyncClient,
        start_lat: float,
        start_lng: float,
        dest_lat: float,
        dest_lng: float,
    ) -> Optional[RouteResponse]:
        token = settings.MAPBOX_ACCESS_TOKEN
        if not token or token.startswith("pk.demo"):
            return None

        url = f"{cls.MAPBOX_URL}/{start_lng},{start_lat};{dest_lng},{dest_lat}"
        response = await client.get(
            url,
            params={
                "access_token": token,
                "geometries": "geojson",
                "overview": "full",
                "steps": "false",
            },
        )
        response.raise_for_status()
        data = response.json()
        routes = data.get("routes") or []
        if not routes:
            return None
        primary = routes[0]
        coordinates = (primary.get("geometry") or {}).get("coordinates") or []
        if len(coordinates) < 2:
            return None
        return RouteResponse(
            distance_km=round(float(primary.get("distance", 0)) / 1000.0, 2),
            duration_minutes=round(float(primary.get("duration", 0)) / 60.0, 1),
            geometry=RouteGeometry(type="LineString", coordinates=coordinates),
            source="mapbox",
        )

    @classmethod
    async def _osrm_route(
        cls,
        client: httpx.AsyncClient,
        start_lat: float,
        start_lng: float,
        dest_lat: float,
        dest_lng: float,
    ) -> Optional[RouteResponse]:
        url = f"{cls.OSRM_URL}/{start_lng},{start_lat};{dest_lng},{dest_lat}"
        response = await client.get(
            url,
            params={"overview": "full", "geometries": "geojson", "steps": "false"},
            headers={"User-Agent": "FADER-Hackathon-Prototype/1.0"},
        )
        response.raise_for_status()
        data = response.json()
        if data.get("code") != "Ok":
            return None
        routes = data.get("routes") or []
        if not routes:
            return None
        primary = routes[0]
        coordinates = (primary.get("geometry") or {}).get("coordinates") or []
        if len(coordinates) < 2:
            return None
        return RouteResponse(
            distance_km=round(float(primary.get("distance", 0)) / 1000.0, 2),
            duration_minutes=round(float(primary.get("duration", 0)) / 60.0, 1),
            geometry=RouteGeometry(type="LineString", coordinates=coordinates),
            source="osrm",
        )

    @classmethod
    async def calculate_route(
        cls,
        start_lat: float,
        start_lng: float,
        dest_lat: float,
        dest_lng: float,
    ) -> RouteResponse:
        try:
            async with httpx.AsyncClient(timeout=6.0, follow_redirects=True) as client:
                # Prefer a configured commercial provider because it offers the most
                # predictable service. Without a token, OSRM gives the hackathon demo
                # a genuine roadway route without exposing credentials in the browser.
                try:
                    mapbox = await cls._mapbox_route(
                        client, start_lat, start_lng, dest_lat, dest_lng
                    )
                    if mapbox:
                        return mapbox
                except (httpx.HTTPError, ValueError, TypeError):
                    pass

                try:
                    osrm = await cls._osrm_route(
                        client, start_lat, start_lng, dest_lat, dest_lng
                    )
                    if osrm:
                        return osrm
                except (httpx.HTTPError, ValueError, TypeError):
                    pass
        except Exception:
            pass

        return cls._get_fallback_route(start_lat, start_lng, dest_lat, dest_lng)
