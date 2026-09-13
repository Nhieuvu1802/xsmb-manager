"""SQLAlchemy models shared by PostgreSQL and isolated tests."""

from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, ForeignKeyConstraint, Index, String, UniqueConstraint, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Draw(Base):
    __tablename__ = "draws"
    draw_date: Mapped[date] = mapped_column(Date, primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Result(Base):
    __tablename__ = "results"
    __table_args__ = (
        UniqueConstraint("draw_date", "prize", "position"),
        Index("idx_results_date_loto", "draw_date", "loto2"),
        Index("idx_results_loto_date", "loto2", "draw_date"),
    )
    id: Mapped[int] = mapped_column(primary_key=True)
    draw_date: Mapped[date] = mapped_column(ForeignKey("draws.draw_date", ondelete="CASCADE"), nullable=False)
    prize: Mapped[str] = mapped_column(String(80))
    position: Mapped[int]
    full_number: Mapped[str] = mapped_column(String(16))
    loto2: Mapped[str] = mapped_column(String(2), index=True)


class MNDraw(Base):
    __tablename__ = "mn_draws"
    draw_date: Mapped[date] = mapped_column(Date, primary_key=True)
    province: Mapped[str] = mapped_column(String(80), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class MNResult(Base):
    __tablename__ = "mn_results"
    __table_args__ = (
        ForeignKeyConstraint(["draw_date", "province"], ["mn_draws.draw_date", "mn_draws.province"], ondelete="CASCADE"),
        UniqueConstraint("draw_date", "province", "prize", "position"),
        Index("idx_mn_results_province_date_loto", "province", "draw_date", "loto2"),
    )
    id: Mapped[int] = mapped_column(primary_key=True)
    draw_date: Mapped[date] = mapped_column(Date, nullable=False)
    province: Mapped[str] = mapped_column(String(80))
    prize: Mapped[str] = mapped_column(String(80))
    position: Mapped[int]
    full_number: Mapped[str] = mapped_column(String(16))
    loto2: Mapped[str] = mapped_column(String(2), index=True)


class SyncLog(Base):
    __tablename__ = "sync_log"
    id: Mapped[int] = mapped_column(primary_key=True)
    region: Mapped[str] = mapped_column(String(10), index=True)
    draw_date: Mapped[date] = mapped_column(Date, index=True)
    source: Mapped[str] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(30))
    details: Mapped[str | None] = mapped_column(String(500))
    synced_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
