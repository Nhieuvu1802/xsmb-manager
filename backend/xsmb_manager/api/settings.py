"""Environment-based backend settings."""

from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://xsmb:xsmb@localhost:5432/xsmb"
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 30
    admin_username: str = "admin"
    admin_password: str | None = None
    cors_origins: str = "http://localhost:3000,https://vvn.freedev.app"

    @field_validator("database_url", mode="before")
    @classmethod
    def select_psycopg_driver(cls, value: str) -> str:
        if value.startswith("postgresql://"):
            return value.replace("postgresql://", "postgresql+psycopg://", 1)
        return value

    @property
    def allowed_origins(self) -> list[str]:
        return [origin.strip().rstrip("/") for origin in self.cors_origins.split(",") if origin.strip()]

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
