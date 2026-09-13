"""HTTP routes for authentication, draws, and synchronization."""

from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..scraper import RequestsLotteryScraper
from ..services import LotterySyncService
from .auth import authenticate_user, create_access_token, get_current_user, hash_password, require_admin
from .database import PostgresLotteryRepository, get_session
from .models import Draw, MNDraw, SyncLog, User
from .schemas import (
    DrawListResponse,
    DrawRead,
    HealthResponse,
    MNResultRead,
    PrizeRead,
    PublicConfigResponse,
    ResultRead,
    SyncRequest,
    SyncResponse,
    Token,
    UserCreate,
    UserRead,
    VersionResponse,
)

router = APIRouter()

REGION_LABELS = {"mb": "Miền Bắc", "mn": "Miền Nam"}
MB_STATION = "Hội đồng XSKT miền Bắc"


def _region_code(value: str) -> str:
    normalized = value.strip().lower()
    if normalized not in REGION_LABELS:
        raise HTTPException(
            status_code=422,
            detail="region chỉ nhận 'mb' hoặc 'mn' (miền Trung chưa có dữ liệu).",
        )
    return normalized


def _sources_for(session: Session, days: list[date]) -> dict[date, str]:
    if not days:
        return {}
    rows = session.execute(
        select(SyncLog.draw_date, SyncLog.source).where(SyncLog.draw_date.in_(days))
    ).all()
    return {row.draw_date: row.source for row in rows}


def _build_payload(
    session: Session,
    region: str,
    start: date | None,
    end: date | None,
    province: str | None = None,
    limit_days: int | None = None,
) -> DrawListResponse:
    """Gộp dữ liệu phẳng trong database thành kỳ quay hoàn chỉnh cho client."""

    repository = PostgresLotteryRepository(session)
    draws: list[DrawRead] = []

    if region == "mb":
        rows = repository.list_mb_results(start, end)
        grouped: dict[date, list] = {}
        for row in rows:
            grouped.setdefault(row.draw_date, []).append(row)
        selected = sorted(grouped.items(), reverse=True)
        if limit_days:
            selected = selected[:limit_days]
        sources = _sources_for(session, [item[0] for item in selected])
        for draw_date, items in selected:
            draws.append(
                DrawRead(
                    region=region,
                    date=draw_date,
                    station=MB_STATION,
                    source=sources.get(draw_date, "database"),
                    draw_code=f"MB-{draw_date:%Y%m%d}",
                    results=[PrizeRead(prize=item.prize, position=item.position, value=item.full_number) for item in items],
                )
            )
        return DrawListResponse(region=region, count=len(draws), draws=draws)

    rows = repository.list_mn_results(start, end, province)
    grouped_mn: dict[tuple[date, str], list] = {}
    for row in rows:
        grouped_mn.setdefault((row.draw_date, row.province), []).append(row)
    ordered = sorted(grouped_mn.items(), key=lambda item: (item[0][0], item[0][1]), reverse=True)
    if limit_days:
        days_seen = sorted({key[0] for key in grouped_mn}, reverse=True)[:limit_days]
        ordered = [item for item in ordered if item[0][0] in days_seen]
    sources = _sources_for(session, sorted({item[0][0] for item in ordered}))
    for (draw_date, station), items in ordered:
        draws.append(
            DrawRead(
                region=region,
                date=draw_date,
                station=station,
                source=sources.get(draw_date, "database"),
                draw_code=f"MN-{draw_date:%Y%m%d}-{station}",
                results=[PrizeRead(prize=item.prize, position=item.position, value=item.full_number) for item in items],
            )
        )
    return DrawListResponse(region=region, count=len(draws), draws=draws)



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


@router.get("/health", response_model=HealthResponse, tags=["System"])
def api_health(session: Session = Depends(get_session)) -> HealthResponse:
    """Health check cho client mobile/web (không cần xác thực)."""

    session.execute(select(1))
    mb_latest = session.scalar(select(func.max(Draw.draw_date)))
    mn_latest = session.scalar(select(func.max(MNDraw.draw_date)))
    latest = max((day for day in (mb_latest, mn_latest) if day is not None), default=None)
    return HealthResponse(
        status="ok",
        database="ok",
        time=datetime.now(timezone.utc),
        lastDataUpdate=latest,
        providers=[],
    )


@router.get("/config", response_model=PublicConfigResponse, tags=["System"])
def public_config() -> PublicConfigResponse:
    """Cấu hình public an toàn để website và app dùng chung."""

    return PublicConfigResponse(
        apiBaseUrl="https://api.vvn.freedev.app/v1",
        minimumAppVersion="2.0.0",
    )


@router.get("/version", response_model=VersionResponse, tags=["System"])
def version() -> VersionResponse:
    return VersionResponse(appVersion="2.7.0")


@router.get("/xsmb/latest", response_model=DrawListResponse, tags=["Results"])
def xsmb_latest(
    days: int = Query(7, ge=1, le=90, description="Số kỳ gần nhất cần lấy"),
    session: Session = Depends(get_session),
) -> DrawListResponse:
    """Các kỳ XSMB gần nhất, mỗi kỳ kèm đầy đủ 27 giải."""

    return _build_payload(session, "mb", None, None, limit_days=days)


@router.get("/xsmb/history", response_model=DrawListResponse, tags=["Results"])
def xsmb_history(
    start: date | None = Query(None),
    end: date | None = Query(None),
    session: Session = Depends(get_session),
) -> DrawListResponse:
    if start and end and start > end:
        raise HTTPException(status_code=422, detail="start phải nhỏ hơn hoặc bằng end")
    return _build_payload(session, "mb", start, end)


@router.get("/xsmb/{draw_date}", response_model=DrawListResponse, tags=["Results"])
def xsmb_by_date(draw_date: date, session: Session = Depends(get_session)) -> DrawListResponse:
    """Kết quả XSMB của đúng một ngày."""

    return _build_payload(session, "mb", draw_date, draw_date)


@router.get("/xsmn/latest", response_model=DrawListResponse, tags=["Results"])
def xsmn_latest(
    days: int = Query(7, ge=1, le=90),
    province: str | None = Query(None, min_length=2, max_length=80),
    session: Session = Depends(get_session),
) -> DrawListResponse:
    """Các kỳ XSMN gần nhất, mỗi đài là một bản ghi riêng."""

    normalized = province.strip() if province else None
    return _build_payload(session, "mn", None, None, province=normalized, limit_days=days)


@router.get("/xsmn/history", response_model=DrawListResponse, tags=["Results"])
def xsmn_history(
    start: date | None = Query(None),
    end: date | None = Query(None),
    province: str | None = Query(None, min_length=2, max_length=80),
    session: Session = Depends(get_session),
) -> DrawListResponse:
    if start and end and start > end:
        raise HTTPException(status_code=422, detail="start phải nhỏ hơn hoặc bằng end")
    normalized = province.strip() if province else None
    return _build_payload(session, "mn", start, end, province=normalized)


@router.get("/xsmn/{draw_date}", response_model=DrawListResponse, tags=["Results"])
def xsmn_by_date(
    draw_date: date,
    province: str | None = Query(None, min_length=2, max_length=80),
    session: Session = Depends(get_session),
) -> DrawListResponse:
    """Kết quả XSMN của một ngày, có thể lọc theo đài."""

    normalized = province.strip() if province else None
    return _build_payload(session, "mn", draw_date, draw_date, province=normalized)


@router.get("/history", response_model=DrawListResponse, tags=["Results"])
def history(
    region: str = Query("mb", description="mb hoặc mn"),
    start: date | None = Query(None),
    end: date | None = Query(None),
    province: str | None = Query(None, min_length=2, max_length=80),
    session: Session = Depends(get_session),
) -> DrawListResponse:
    """Lịch sử theo khoảng ngày, dùng cho đồng bộ và backtest."""

    code = _region_code(region)
    if start and end and start > end:
        raise HTTPException(status_code=422, detail="start phải nhỏ hơn hoặc bằng end")
    normalized = province.strip() if province else None
    return _build_payload(session, code, start, end, province=normalized)
