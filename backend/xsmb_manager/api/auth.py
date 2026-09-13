"""Password hashing, JWT creation, and FastAPI auth dependencies."""

from datetime import datetime, timedelta, timezone

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import get_session
from .models import User
from .settings import get_settings

password_hash = PasswordHash.recommended()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(password: str, encoded: str) -> bool:
    return password_hash.verify(password, encoded)


def create_access_token(username: str) -> str:
    settings = get_settings()
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_minutes)
    return jwt.encode({"sub": username, "exp": expires}, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def authenticate_user(session: Session, username: str, password: str) -> User | None:
    user = session.scalar(select(User).where(User.username == username))
    if user is None or not user.is_active or not verify_password(password, user.password_hash):
        return None
    return user


def get_current_user(token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)) -> User:
    credentials_error = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                                      detail="Token không hợp lệ hoặc đã hết hạn",
                                      headers={"WWW-Authenticate": "Bearer"})
    try:
        payload = jwt.decode(token, get_settings().jwt_secret, algorithms=[get_settings().jwt_algorithm])
        username = payload.get("sub")
        if not username:
            raise credentials_error
    except InvalidTokenError as exc:
        raise credentials_error from exc
    user = session.scalar(select(User).where(User.username == username))
    if user is None or not user.is_active:
        raise credentials_error
    return user


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cần quyền quản trị")
    return user
