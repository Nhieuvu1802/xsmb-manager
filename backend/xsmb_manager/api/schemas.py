"""Public API contracts."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=80, pattern=r"^[A-Za-z0-9_.-]+$")
    password: str = Field(min_length=12, max_length=128)
    is_admin: bool = False


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    username: str
    is_active: bool
    is_admin: bool


class ResultRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    draw_date: date
    prize: str
    position: int
    full_number: str
    loto2: str


class MNResultRead(ResultRead):
    province: str


class SyncRequest(BaseModel):
    start_date: date
    end_date: date


class SyncResponse(BaseModel):
    saved: int
    errors: list[str]


class PrizeRead(BaseModel):
    """Một giải trong kỳ quay, dạng app Flutter đọc trực tiếp."""

    prize: str
    position: int
    value: str


class DrawRead(BaseModel):
    """Một kỳ quay hoàn chỉnh của một đài."""

    region: str
    date: date
    station: str
    source: str
    verification: str = "VERIFIED"
    collected_at: datetime | None = None
    draw_code: str
    results: list[PrizeRead]


class DrawListResponse(BaseModel):
    region: str
    count: int
    draws: list[DrawRead]


class HealthResponse(BaseModel):
    status: str
    database: str
    time: datetime
    apiVersion: str = "v1"
    lastDataUpdate: date | None = None
    providers: list[str] = Field(default_factory=list)


class PublicConfigResponse(BaseModel):
    apiBaseUrl: str
    apiVersion: str = "v1"
    maintenance: bool = False
    minimumAppVersion: str
    githubFallbackEnabled: bool = True


class VersionResponse(BaseModel):
    apiVersion: str = "v1"
    appVersion: str
