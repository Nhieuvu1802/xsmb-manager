"""FastAPI application entry point."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from .auth import hash_password
from .database import SessionLocal, create_schema
from .models import User
from .routes import router
from .settings import get_settings


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    if settings.jwt_secret == "change-me-in-production":
        raise RuntimeError("JWT_SECRET phải được thay đổi trước khi chạy API")
    create_schema()
    if settings.admin_password:
        with SessionLocal() as session:
            if session.scalar(select(User).where(User.username == settings.admin_username)) is None:
                session.add(User(username=settings.admin_username, password_hash=hash_password(settings.admin_password),
                                 is_active=True, is_admin=True))
                session.commit()
    yield


app = FastAPI(
    title="XSMB/XSMN API",
    version="1.0.0",
    description="API kết quả xổ số, đồng bộ nguồn và quản trị người dùng.",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=get_settings().allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)
app.include_router(router, prefix="/api/v1")


@app.get("/health", tags=["System"])
def health() -> dict[str, str]:
    return {"status": "ok"}
