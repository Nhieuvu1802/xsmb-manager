"""Public API contracts."""

from datetime import date

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
