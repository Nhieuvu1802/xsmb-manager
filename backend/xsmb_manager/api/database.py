"""Database engine, sessions, and PostgreSQL repository."""

from datetime import date

from sqlalchemy import create_engine, delete, select
from sqlalchemy.orm import Session, sessionmaker

from ..config import MN_EXPECTED_PRIZES
from ..ports import MBPrizeMap, MBResult
from .models import Base, Draw, MNDraw, MNResult, Result, SyncLog
from .settings import get_settings

settings = get_settings()
engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def create_schema() -> None:
    Base.metadata.create_all(engine)


def get_session():
    with SessionLocal() as session:
        yield session


class PostgresLotteryRepository:
    """SQLAlchemy implementation of the shared repository port."""

    def __init__(self, session: Session):
        self.session = session

    def upsert_mb_draw(self, draw_date: str, results: list[MBResult]) -> None:
        if not results:
            raise ValueError("Cần nhập ít nhất một số")
        parsed_date = date.fromisoformat(draw_date)
        if self.session.get(Draw, parsed_date) is None:
            self.session.add(Draw(draw_date=parsed_date))
        self.session.execute(delete(Result).where(Result.draw_date == parsed_date))
        self.session.add_all(Result(draw_date=parsed_date, prize=prize, position=position,
                                    full_number=number, loto2=number.zfill(2)[-2:])
                             for prize, position, number in results)
        self.session.commit()

    def upsert_mn_draw(self, draw_date: str, province: str, prizes: MBPrizeMap) -> None:
        rows = [(prize, position, number) for prize in MN_EXPECTED_PRIZES
                for position, number in enumerate(prizes.get(prize, []), 1)]
        if len(rows) != 18:
            raise ValueError(f"{province} chưa đủ 18 số")
        parsed_date, key = date.fromisoformat(draw_date), {"draw_date": date.fromisoformat(draw_date), "province": province}
        if self.session.get(MNDraw, key) is None:
            self.session.add(MNDraw(**key))
        self.session.execute(delete(MNResult).where(MNResult.draw_date == parsed_date, MNResult.province == province))
        self.session.add_all(MNResult(draw_date=parsed_date, province=province, prize=prize, position=position,
                                      full_number=number, loto2=number.zfill(2)[-2:])
                             for prize, position, number in rows)
        self.session.commit()

    def log_sync(self, region: str, draw_date: str, source: str, details: str) -> None:
        self.session.add(SyncLog(region=region, draw_date=date.fromisoformat(draw_date), source=source,
                                 status="success", details=details))
        self.session.commit()

    def list_mb_results(self, start: date | None = None, end: date | None = None) -> list[Result]:
        statement = select(Result)
        if start: statement = statement.where(Result.draw_date >= start)
        if end: statement = statement.where(Result.draw_date <= end)
        return list(self.session.scalars(statement.order_by(Result.draw_date.desc(), Result.prize, Result.position)))

    def list_mn_results(
        self,
        start: date | None = None,
        end: date | None = None,
        province: str | None = None,
    ) -> list[MNResult]:
        statement = select(MNResult)
        if start:
            statement = statement.where(MNResult.draw_date >= start)
        if end:
            statement = statement.where(MNResult.draw_date <= end)
        if province:
            statement = statement.where(MNResult.province == province)
        return list(
            self.session.scalars(
                statement.order_by(
                    MNResult.draw_date.desc(),
                    MNResult.province,
                    MNResult.prize,
                    MNResult.position,
                )
            )
        )
