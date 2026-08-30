import random
from typing import Optional
from app.schemas.engagement import EngagementTriviaResponse

FALLBACK_KNOWLEDGE_BASE = {
    "nagpur": [
        "Did you know? Nagpur is the geographic center of India, marked by the historical Zero Mile Stone monument.",
        "Nagpur is globally famous for its sweet juicy oranges and is known as the Orange City of India."
    ],
    "amravati": [
        "Approaching Amravati: Known historically for the ancient Ambadevi temple and its rich cultural heritage.",
        "Amravati is the regional administrative and educational center of Vidarbha."
    ],
    "akola": [
        "Entering Akola: Known as the 'Cotton City' due to its extensive cotton trade and agricultural markets.",
        "Akola is situated on the banks of the Morna River in Maharashtra."
    ],
    "aurangabad": [
        "Passing near Chhatrapati Sambhaji Nagar: Home to the UNESCO World Heritage Ajanta and Ellora caves.",
        "The city is famed for its Mughal architecture, notably the Bibi Ka Maqbara."
    ],
    "nashik": [
        "Approaching Nashik: Known as the Wine Capital of India and situated on the banks of the sacred Godavari river.",
        "Nashik hosts the grand Kumbh Mela every 12 years at Trimbakeshwar."
    ],
    "mumbai": [
        "Arriving in Mumbai: India's financial hub, featuring the iconic Gateway of India and the scenic Marine Drive.",
        "Mumbai's Dabbawalas are famous worldwide for their six-sigma operational precision."
    ]
}

DEFAULT_FACTS = [
    "Staying mentally active with quick trivia helps reduce highway monotony and maintains vigilance.",
    "Rolling down your window for 30 seconds improves cabin oxygen circulation and reduces drowsiness."
]


class LLMService:
    @classmethod
    def get_location_trivia(cls, location: Optional[str] = None) -> EngagementTriviaResponse:
        loc_key = (location or "nagpur").strip().lower()

        # Match specific key or partial substring
        matched_facts = None
        for key in FALLBACK_KNOWLEDGE_BASE:
            if key in loc_key:
                matched_facts = FALLBACK_KNOWLEDGE_BASE[key]
                loc_key = key.capitalize()
                break

        if not matched_facts:
            selected_fact = random.choice(DEFAULT_FACTS)
            loc_label = location if location else "En Route"
        else:
            selected_fact = random.choice(matched_facts)
            loc_label = loc_key.capitalize()

        return EngagementTriviaResponse(
            location=loc_label,
            fact_or_question=selected_fact,
            category="local_trivia",
            source="fallback_cache"
        )
