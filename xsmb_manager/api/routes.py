"""HTTP routes for authentication, draws, and synchronization."""

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..scraper import RequestsLotteryScraper
from ..services import LotterySyncService
from .auth import authenticate_user, create_access_token, get_current_user, hash_password, require_admin
from .database import PostgresLotteryRepository, get_session
from .models import User
from .schemas import MNResultRead, ResultRead, SyncRequest, SyncResponse, Token, UserCreate, UserRead

router = APIRouter()


@router.post("/auth/token", response_model=Token, tags=["Authentication"])
def login(form: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)) -> Token:
    user = authenticate_user(session, form.username, form.password)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Sai tài khoản hoặc mật khẩu",
                            headers={"WWW-Authenticate": "Bearer"})
    return Token(access_token=create_access_token(user.username))


@router.get("/auth/me", response_model=UserRead, tags=["Authentication"])
def me(user: User = Depends(get_current_user)) -> User:
    return user


@router.post("/users", response_model=UserRead, status_code=status.HTTP_201_CREATED, tags=["Users"])
def create_user(payload: UserCreate, _: User = Depends(require_admin), session: Session = Depends(get_session)) -> User:
    if session.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=409, detail="Tên đăng nhập đã tồn tại")
    user = User(username=payload.username, password_hash=hash_password(payload.password),
                is_active=True, is_admin=payload.is_admin)
    session.add(user); session.commit(); session.refresh(user)
    return user


@router.get("/draws/mb", response_model=list[ResultRead], tags=["Results"])
def list_mb_results(start: date | None = Query(None), end: date | None = Query(None),
                    session: Session = Depends(get_session)):
    if start and end and start > end:
        raise HTTPException(status_code=422, detail="start phải nhỏ hơn hoặc bằng end")
    return PostgresLotteryRepository(session).list_mb_results(start, end)


@router.get("/draws/mn", response_model=list[MNResultRead], tags=["Results"])
def list_mn_results(
    start: date | None = Query(None),
    end: date | None = Query(None),
    province: str | None = Query(None, min_length=2, max_length=80),
    session: Session = Depends(get_session),
):
    if start and end and start > end:
        raise HTTPException(status_code=422, detail="start phải nhỏ hơn hoặc bằng end")
    normalized_province = province.strip() if province else None
    return PostgresLotteryRepository(session).list_mn_results(start, end, normalized_province)


@router.post("/sync/mb", response_model=SyncResponse, tags=["Synchronization"])
def sync_mb(payload: SyncRequest, _: User = Depends(require_admin), session: Session = Depends(get_session)) -> SyncResponse:
    if payload.start_date > payload.end_date:
        raise HTTPException(status_code=422, detail="start_date phải nhỏ hơn hoặc bằng end_date")
    saved, errors = LotterySyncService(PostgresLotteryRepository(session), RequestsLotteryScraper(record_health=False)).sync_mb_range(payload.start_date, payload.end_date)
    return SyncResponse(saved=saved, errors=errors)


@router.post("/sync/mn", response_model=SyncResponse, tags=["Synchronization"])
def sync_mn(payload: SyncRequest, _: User = Depends(require_admin), session: Session = Depends(get_session)) -> SyncResponse:
    if payload.start_date > payload.end_date:
        raise HTTPException(status_code=422, detail="start_date phải nhỏ hơn hoặc bằng end_date")
    saved, errors = LotterySyncService(PostgresLotteryRepository(session), RequestsLotteryScraper(record_health=False)).sync_mn_range(payload.start_date, payload.end_date)
    return SyncResponse(saved=saved, errors=errors)
