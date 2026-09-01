from app.schemas.co2 import CO2PredictionRequest, CO2PredictionResponse


class CO2Service:
    AMBIENT_BASELINE_PPM = 420

    @classmethod
    def predict_co2(cls, payload: CO2PredictionRequest) -> CO2PredictionResponse:
        # Base cabin accumulation rate: ~3.5 ppm/min single occupant closed vehicle
        accumulation_rate = 3.5 / payload.ventilation_factor
        estimated_ppm = int(cls.AMBIENT_BASELINE_PPM + (payload.duration_minutes * accumulation_rate))
        
        # Upper ceiling cap for closed vehicular volume
        estimated_ppm = min(2500, estimated_ppm)

        if estimated_ppm >= 1500:
            level = "HAZARDOUS"
            break_needed = True
            prompt = "Critical CO2 concentration detected. Open cabin windows immediately and pull over for a break."
        elif estimated_ppm >= 1000:
            level = "ELEVATED"
            break_needed = True
            prompt = "Elevated cabin CO2 levels. Switch HVAC to fresh air intake or crack a window."
        elif estimated_ppm >= 700:
            level = "MODERATE"
            break_needed = False
            prompt = "Air quality acceptable. Normal cabin circulation."
        else:
            level = "OPTIMAL"
            break_needed = False
            prompt = "Fresh air quality optimal."

        return CO2PredictionResponse(
            trip_id=payload.trip_id,
            estimated_co2_ppm=estimated_ppm,
            air_quality_level=level,
            break_recommended=break_needed,
            action_prompt=prompt,
            model_type="prototype_simulation_model"
        )
