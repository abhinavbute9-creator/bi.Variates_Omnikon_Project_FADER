from datetime import datetime, timezone
from app.schemas.risk import RiskAssessmentRequest, RiskResponse, FactorBreakdown


class RiskService:
    @classmethod
    def _calculate_circadian_factor(cls) -> float:
        # Check current hour in UTC/local time for circadian biological dip windows
        hour = datetime.now(timezone.utc).hour
        # Peak risk between 2:00 AM - 6:00 AM, secondary dip 14:00 - 16:00
        if 2 <= hour <= 6:
            return 1.0
        elif 14 <= hour <= 16:
            return 0.6
        elif 22 <= hour or hour <= 1:
            return 0.4
        return 0.1

    @classmethod
    def calculate_risk(cls, payload: RiskAssessmentRequest) -> RiskResponse:
        # 1. Fatigue Factor (50% weight)
        # Baseline EAR normal >= 0.28, critical <= 0.18
        ear = payload.current_ear if payload.current_ear is not None else 0.28
        ear_score = max(0.0, min(1.0, (0.30 - ear) / 0.15)) if ear < 0.30 else 0.0
        event_impact = min(1.0, payload.recent_fatigue_events * 0.3)
        fatigue_subtotal = min(1.0, (ear_score * 0.7) + (event_impact * 0.3))

        # 2. Duration Factor (20% weight) - fatigue climbs after 120 mins
        duration = payload.trip_duration_minutes or 0.0
        duration_subtotal = min(1.0, duration / 240.0)

        # 3. Weather Factor (15% weight)
        weather_cond = (payload.weather_condition or "").lower()
        rain = payload.rain_intensity or 0.0
        if "heavy rain" in weather_cond or rain > 3.0:
            weather_subtotal = 0.9
        elif "rain" in weather_cond or rain > 0.0:
            weather_subtotal = 0.6
        elif "overcast" in weather_cond or "fog" in weather_cond:
            weather_subtotal = 0.4
        else:
            weather_subtotal = 0.1

        # 4. Circadian Factor (15% weight)
        circadian_subtotal = cls._calculate_circadian_factor()

        # Weighted calculation
        total_score = int(
            (fatigue_subtotal * 50)
            + (duration_subtotal * 20)
            + (weather_subtotal * 15)
            + (circadian_subtotal * 15)
        )
        total_score = max(0, min(100, total_score))

        # Risk level determination
        if total_score >= 80:
            level = "CRITICAL"
        elif total_score >= 60:
            level = "HIGH"
        elif total_score >= 30:
            level = "MODERATE"
        else:
            level = "LOW"

        return RiskResponse(
            score=total_score,
            level=level,
            factors=FactorBreakdown(
                fatigue_factor=round(fatigue_subtotal * 50, 1),
                duration_factor=round(duration_subtotal * 20, 1),
                weather_factor=round(weather_subtotal * 15, 1),
                circadian_factor=round(circadian_subtotal * 15, 1)
            ),
            model_type="prototype_transparent_v1"
        )
