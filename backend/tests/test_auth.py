import jwt

from xsmb_manager.api.auth import create_access_token, hash_password, verify_password
from xsmb_manager.api.settings import get_settings


def test_password_hash_round_trip():
    encoded = hash_password("a-strong-test-password")
    assert encoded != "a-strong-test-password"
    assert verify_password("a-strong-test-password", encoded)
    assert not verify_password("wrong-password", encoded)


def test_access_token_contains_subject(monkeypatch):
    secret = "test-secret-that-is-definitely-long-enough"
    monkeypatch.setenv("JWT_SECRET", secret)
    get_settings.cache_clear()
    token = create_access_token("alice")
    payload = jwt.decode(token, secret, algorithms=["HS256"])
    assert payload["sub"] == "alice"
    assert "exp" in payload
    get_settings.cache_clear()
