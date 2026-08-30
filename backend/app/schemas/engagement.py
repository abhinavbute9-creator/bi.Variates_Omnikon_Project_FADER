from typing import Optional
from pydantic import BaseModel, Field


class EngagementTriviaResponse(BaseModel):
    location: str
    fact_or_question: str
    category: str = "local_trivia"
    source: str = Field(..., description="gemini_llm or fallback_cache")
