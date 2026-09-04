from xsmb_manager.scraper import parse_mb_html


def test_parse_mb_html_reads_xoso_indexed_elements():
    html = b'<div id="mb_prizeDB_item0">12345</div><div id="mb_prize1_item0">54321</div>'
    assert parse_mb_html(html) == {"Đặc biệt": ["12345"], "Giải nhất": ["54321"]}
