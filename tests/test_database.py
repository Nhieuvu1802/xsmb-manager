import pytest

from xsmb_manager.database import SQLiteLotteryRepository, connect


@pytest.fixture
def repository(tmp_path):
    connection = connect(tmp_path / "test.db")
    yield SQLiteLotteryRepository(connection)
    connection.close()


def test_upsert_mb_draw_replaces_existing_results(repository):
    repository.upsert_mb_draw("2026-09-04", [("Giải nhất", 1, "12345")])
    repository.upsert_mb_draw("2026-09-04", [("Giải nhất", 1, "7")])
    rows = repository.connection.execute("SELECT full_number, loto2 FROM results").fetchall()
    assert rows == [("7", "07")]


def test_upsert_rejects_empty_draw(repository):
    with pytest.raises(ValueError, match="ít nhất một số"):
        repository.upsert_mb_draw("2026-09-04", [])


def test_schema_enables_foreign_keys_and_version(repository):
    assert repository.connection.execute("PRAGMA foreign_keys").fetchone()[0] == 1
    assert repository.connection.execute("PRAGMA user_version").fetchone()[0] == 5
