from xsmb_manager.api.main import app


def test_openapi_exposes_docs_routes_and_oauth2():
    schema = app.openapi()
    assert app.docs_url == "/docs"
    assert "/api/v1/auth/token" in schema["paths"]
    assert "/api/v1/sync/mb" in schema["paths"]
    assert "/api/v1/draws/mn" in schema["paths"]
    assert schema["components"]["securitySchemes"]["OAuth2PasswordBearer"]["flows"]["password"]["tokenUrl"] == "/api/v1/auth/token"


def test_openapi_exposes_mobile_contract_routes():
    """App Flutter dựa vào nhóm endpoint này; đổi tên là breaking change."""

    paths = app.openapi()["paths"]

    for path in (
        "/api/v1/health",
        "/api/v1/config",
        "/api/v1/version",
        "/api/v1/xsmb/latest",
        "/api/v1/xsmb/history",
        "/api/v1/xsmb/{draw_date}",
        "/api/v1/xsmn/latest",
        "/api/v1/xsmn/history",
        "/api/v1/xsmn/{draw_date}",
        "/api/v1/history",
    ):
        assert path in paths, path

    response = paths["/api/v1/xsmb/latest"]["get"]["responses"]["200"]
    schema_ref = response["content"]["application/json"]["schema"]["$ref"]
    assert schema_ref.endswith("/DrawListResponse")
