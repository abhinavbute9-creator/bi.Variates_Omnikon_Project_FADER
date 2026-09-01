from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles

from app.api.v1 import api_router
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

if settings.CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/", include_in_schema=False)
async def root():
    """The submission URL opens the FADER interface, not a JSON payload."""
    return RedirectResponse(url="/demo/", status_code=307)


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "service": settings.PROJECT_NAME}


@app.get("/app", include_in_schema=False)
async def app_redirect():
    return RedirectResponse(url="/demo/", status_code=307)


_web_demo_dir = Path(__file__).resolve().parent.parent / "web_demo"
if _web_demo_dir.exists():
    app.mount("/demo", StaticFiles(directory=str(_web_demo_dir), html=True), name="demo")
