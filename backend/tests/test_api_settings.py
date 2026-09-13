from xsmb_manager.api.settings import Settings


def test_render_postgres_url_selects_psycopg_driver():
    settings = Settings(database_url="postgresql://user:pass@db:5432/xsmb")
    assert settings.database_url.startswith("postgresql+psycopg://")


def test_cors_origins_are_normalized():
    settings = Settings(cors_origins="https://one.example/, https://two.example")
    assert settings.allowed_origins == ["https://one.example", "https://two.example"]
