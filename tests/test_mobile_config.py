from pathlib import Path


def test_twa_secrets_and_build_outputs_are_ignored():
    ignored = Path("twa/.gitignore").read_text(encoding="utf-8")
    assert "*.jks" in ignored
    assert "*.keystore" in ignored
    assert "*.aab" in ignored


def test_pwa_has_digital_asset_links_route():
    route = Path("frontend/app/.well-known/assetlinks.json/route.ts").read_text(encoding="utf-8")
    assert "delegate_permission/common.handle_all_urls" in route
    assert "ANDROID_SHA256_FINGERPRINTS" in route


def test_flutter_release_keystore_is_ignored_and_injected_from_secrets():
    ignored = Path("mobile/.gitignore").read_text(encoding="utf-8")
    workflow = Path(".github/workflows/android-release.yml").read_text(encoding="utf-8")
    assert "*.jks" in ignored
    assert "ANDROID_KEYSTORE_BASE64" in workflow
    assert "ANDROID_KEYSTORE_PATH" in workflow
    assert "vn.xsmb.xsmb_manager" in workflow


def test_flutter_ci_does_not_publish_to_google_play():
    workflow = Path(".github/workflows/android-ci.yml").read_text(encoding="utf-8")
    assert "upload-google-play" not in workflow
    assert "workflow_dispatch" in workflow
