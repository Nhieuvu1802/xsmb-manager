from xsmb_manager.api.main import app


def test_openapi_exposes_docs_routes_and_oauth2():
    schema = app.openapi()
    assert app.docs_url == "/docs"
    assert "/api/v1/auth/token" in schema["paths"]
    assert "/api/v1/sync/mb" in schema["paths"]
    assert "/api/v1/draws/mn" in schema["paths"]
    assert schema["components"]["securitySchemes"]["OAuth2PasswordBearer"]["flows"]["password"]["tokenUrl"] == "/api/v1/auth/token"
