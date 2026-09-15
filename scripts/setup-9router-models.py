#!/usr/bin/env python3
"""
setup-9router-models.py — Auto-configure optimal AI models on 9Router

Connects to a running 9Router and configures optimal 3-tier model combos.
Tier 1: Subscription (Claude Code, Codex, Gemini)
Tier 2: Cheap (GLM $0.60/1M, MiniMax $0.20/1M, Kimi $9/mo)
Tier 3: FREE (iFlow, Qwen, Kiro, OpenCode, OpenRouter, NVIDIA NIM)

Usage:
    python scripts/setup-9router-models.py                  # full setup
    python scripts/setup-9router-models.py --action list     # list models
    python scripts/setup-9router-models.py --action combos   # show combos
    python scripts/setup-9router-models.py --action guide    # manual guide
    python scripts/setup-9router-models.py --action verify   # verify only
    python scripts/setup-9router-models.py --url http://host:20128 --password PWD
"""

import argparse, json, logging, sys, urllib.error, urllib.request

logging.basicConfig(level=logging.INFO, format="%(asctime)s [9router-setup] %(levelname)s %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
log = logging.getLogger("9router-setup")

DEFAULT_URL = "http://localhost:20128"
DEFAULT_PASSWORD = "123456"

OPTIMAL_COMBOS = [
    {"name": "Claude Elite", "desc": "Best quality: Claude Opus → GLM (cheap) → iFlow (free)", "models": [
        {"model": "cc/claude-opus-4-6", "tier": 1}, {"model": "glm/glm-5.1", "tier": 2}, {"model": "iflow/claude-opus-4-6", "tier": 3}]},
    {"name": "Claude Fast", "desc": "Fast + cheap: Claude Sonnet → MiniMax → Qwen (free)", "models": [
        {"model": "cc/claude-sonnet-4-5", "tier": 1}, {"model": "minimax/MiniMax-M2.7", "tier": 2}, {"model": "qwen/qwen3-coder-plus", "tier": 3}]},
    {"name": "Gemini Pro", "desc": "All-rounder: Gemini Pro → GLM → OpenCode (free)", "models": [
        {"model": "gemini/gemini-3.1-pro-preview", "tier": 1}, {"model": "glm/glm-5.1", "tier": 2}, {"model": "oc/claude-opus-4-6", "tier": 3}]},
    {"name": "Codex Value", "desc": "Budget: Codex → DeepSeek (cheap) → OpenRouter (free)", "models": [
        {"model": "codex/gpt-5-codex", "tier": 1}, {"model": "deepseek/deepseek-v3.2", "tier": 2}, {"model": "openrouter/google-gemini-3.1-flash-lite-preview", "tier": 3}]},
    {"name": "Copilot Hybrid", "desc": "Copilot sub: Copilot Claude → Kimi → NVIDIA NIM (free)", "models": [
        {"model": "copilot/claude-sonnet-4.5", "tier": 1}, {"model": "kimi/kimi-k2.5", "tier": 2}, {"model": "nim/qwen/qwen3-coder-480b-a35b-instruct", "tier": 3}]},
]

FREE_MODELS = ["iflow/claude-opus-4-6", "qwen/qwen3-coder-plus", "oc/claude-opus-4-6",
    "kiro/claude-opus-4-6", "openrouter/google-gemini-3.1-flash-lite-preview",
    "nim/qwen/qwen3-coder-480b-a35b-instruct", "gemini/gemini-2.5-flash"]


# ── HTTP helpers ────────────────────────────────────────────────
def api_request(base_url: str, path: str, method: str = "GET",
                data: dict | None = None, token: str | None = None):
    url = f"{base_url}{path}"
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            content = resp.read().decode()
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        log.warning("API %s %s → %d", method, path, e.code)
        return None
    except Exception as e:
        log.warning("API %s %s failed: %s", method, path, e)
        return None


def login(base_url: str, password: str) -> str | None:
    log.info("Logging in to 9Router at %s ...", base_url)
    for path in ["/api/auth/login", "/api/login"]:
        result = api_request(base_url, path, "POST", {"password": password})
        if result and "token" in result:
            log.info("✅ Login successful")
            return result["token"]
    log.warning("⚠️  Login failed — will try unauthenticated mode")
    return None


# ── Provider auto-configuration ─────────────────────────────────
PROVIDER_PAYLOADS = [
    {"id": "claude-code", "name": "Claude Code", "enabled": True,
     "apiKeyEnv": "ANTHROPIC_API_KEY", "models": ["claude-opus-4-6", "claude-sonnet-4-5"]},
    {"id": "glm", "name": "GLM Coding", "enabled": True,
     "apiKeyEnv": "GLM_API_KEY", "models": ["glm-5.1", "codegeex-5"]},
    {"id": "minimax", "name": "MiniMax", "enabled": True,
     "apiKeyEnv": "MINIMAX_API_KEY", "models": ["MiniMax-M2.7"]},
    {"id": "kimi", "name": "Kimi", "enabled": True,
     "apiKeyEnv": "KIMI_API_KEY", "models": ["kimi-k2.5"]},
    {"id": "iflow", "name": "iFlow (FREE)", "enabled": True,
     "apiKeyEnv": "IFLOW_API_KEY", "models": ["claude-opus-4-6", "claude-sonnet-4-5"]},
    {"id": "qwen", "name": "Qwen (FREE)", "enabled": True,
     "apiKeyEnv": "QWEN_API_KEY", "models": ["qwen3-coder-plus"]},
    {"id": "opencode", "name": "OpenCode Free", "enabled": True,
     "apiKeyEnv": "", "models": ["claude-opus-4-6", "claude-sonnet-4-5"]},
    {"id": "kiro", "name": "Kiro (FREE via AWS)", "enabled": True,
     "apiKeyEnv": "", "models": ["claude-opus-4-6", "claude-sonnet-4-5"]},
    {"id": "gemini", "name": "Google Gemini", "enabled": True,
     "apiKeyEnv": "GOOGLE_API_KEY",
     "models": ["gemini-3.1-pro-preview", "gemini-3-flash-preview", "gemini-2.5-flash"]},
    {"id": "openrouter", "name": "OpenRouter (FREE)", "enabled": True,
     "apiKeyEnv": "OPENROUTER_API_KEY",
     "models": ["google-gemini-3.1-flash-lite-preview"]},
    {"id": "nvidia", "name": "NVIDIA NIM (FREE)", "enabled": True,
     "apiKeyEnv": "NVIDIA_API_KEY", "models": ["qwen/qwen3-coder-480b-a35b-instruct"]},
    {"id": "deepseek", "name": "DeepSeek", "enabled": True,
     "apiKeyEnv": "DEEPSEEK_API_KEY", "models": ["deepseek-v3.2", "deepseek-coder-v3"]},
    {"id": "openai", "name": "OpenAI", "enabled": True,
     "apiKeyEnv": "OPENAI_API_KEY", "models": ["gpt-5-codex", "gpt-4.1"]},
    {"id": "xai", "name": "xAI Grok", "enabled": True,
     "apiKeyEnv": "XAI_API_KEY", "models": ["grok-3"]},
    {"id": "mistral", "name": "Mistral", "enabled": True,
     "apiKeyEnv": "MISTRAL_API_KEY", "models": ["codestral-latest"]},
]


def configure_providers(base_url: str, token: str | None) -> None:
    log.info("Configuring providers...")
    for p in PROVIDER_PAYLOADS:
        result = api_request(base_url, "/api/providers", "POST", p, token)
        log.info("  %s %s", "✅" if result else "⏭️", p["name"])


def get_models(base_url: str, token: str | None) -> list[str]:
    result = api_request(base_url, "/v1/models", "GET", token=token)
    if result and isinstance(result, dict) and "data" in result:
        return [m.get("id", "") for m in result["data"]]
    return []


def verify_setup(base_url: str, token: str | None) -> dict:
    log.info("Verifying 9Router setup...")
    models = get_models(base_url, token)
    result = {
        "models_available": len(models),
        "has_free": any("iflow/" in m or "qwen/" in m or "oc/" in m for m in models),
        "has_cheap": any("glm/" in m or "minimax/" in m for m in models),
    }
    test = api_request(base_url, "/v1/chat/completions", "POST",
        {"model": "iflow/claude-opus-4-6",
         "messages": [{"role": "user", "content": "Say 'hello' in one word"}],
         "max_tokens": 10, "stream": False}, token)
    result["test_ok"] = test is not None
    return result


# ── CLI commands ────────────────────────────────────────────────
TIER_LABEL = {1: "Tier 1 (Sub)", 2: "Tier 2 (Cheap)", 3: "Tier 3 (FREE)"}


def cmd_list_models(base_url: str, token: str | None) -> None:
    models = get_models(base_url, token)
    if not models:
        log.warning("No models found. Configure providers in Dashboard first.")
        return
    log.info("Available models (%d):", len(models))
    for m in sorted(models):
        star = " ★" if any(f["model"] == m for c in OPTIMAL_COMBOS for f in c["models"]) else ""
        log.info("  %s%s", m, star)


def cmd_print_combos() -> None:
    log.info("Optimal 3-Tier Model Combos")
    log.info("=" * 70)
    for i, c in enumerate(OPTIMAL_COMBOS, 1):
        log.info("\nCombo %d: %s", i, c["name"])
        log.info("  %s", c["desc"])
        for m in c["models"]:
            log.info("  → [%s] %s", TIER_LABEL[m["tier"]], m["model"])
    log.info("\nFree backup models: %s", ", ".join(FREE_MODELS))


def cmd_print_guide() -> None:
    print("""
╔══════════════════════════════════════════════════════════════════╗
║           9Router Optimal Model Configuration Guide             ║
╠══════════════════════════════════════════════════════════════════╣
║  1. Start:   docker compose -f compose.proxy-pool.yaml up -d   ║
║  2. Dashboard: http://localhost:20128                           ║
║  3. Login with INITIAL_PASSWORD from .env.proxy-pool            ║
║  4. Add providers + API keys in Dashboard → Providers           ║
║  5. Create combos in Dashboard → Combos                         ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────────┐ ║
║  │ COMBO 1: "Claude Elite" (Best Quality)                     │ ║
║  │  cc/claude-opus-4-6 → glm/glm-5.1 → iflow/claude-opus-4-6 │ ║
║  ├─────────────────────────────────────────────────────────────┤ ║
║  │ COMBO 2: "Claude Fast" (Fast + Cheap)                      │ ║
║  │  cc/claude-sonnet-4-5 → minimax/MiniMax-M2.7 →            │ ║
║  │  qwen/qwen3-coder-plus                                     │ ║
║  ├─────────────────────────────────────────────────────────────┤ ║
║  │ COMBO 3: "Gemini Pro" (All-Rounder)                        │ ║
║  │  gemini/gemini-3.1-pro-preview → glm/glm-5.1 →            │ ║
║  │  oc/claude-opus-4-6                                        │ ║
║  ├─────────────────────────────────────────────────────────────┤ ║
║  │ COMBO 4: "Codex Value" (Budget)                            │ ║
║  │  codex/gpt-5-codex → deepseek/deepseek-v3.2 →             │ ║
║  │  openrouter/google-gemini-3.1-flash-lite-preview           │ ║
║  ├─────────────────────────────────────────────────────────────┤ ║
║  │ COMBO 5: "Copilot Hybrid" (Copilot Subscription)           │ ║
║  │  copilot/claude-sonnet-4.5 → kimi/kimi-k2.5 →             │ ║
║  │  nim/qwen/qwen3-coder-480b-a35b-instruct                  │ ║
║  └─────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  6. Point tools to http://localhost:20128                        ║
║     Claude Code:  ANTHROPIC_BASE_URL=http://localhost:20128/v1   ║
║     Cursor:       Settings → Models → API Base URL               ║
║     Cline:        Settings → API Base URL                        ║
║     Codex:        OPENAI_BASE_URL=http://localhost:20128/v1      ║
╚══════════════════════════════════════════════════════════════════╝
""")


# ── Main ────────────────────────────────────────────────────────
def main() -> None:
    parser = argparse.ArgumentParser(description="Auto-configure optimal models on 9Router")
    parser.add_argument("--url", default=DEFAULT_URL, help="9Router base URL")
    parser.add_argument("--password", default=DEFAULT_PASSWORD, help="9Router admin password")
    parser.add_argument("--action", choices=["setup", "verify", "list", "combos", "guide"],
                        default="setup", help="Action to perform")
    args = parser.parse_args()

    if args.action in ("guide", "combos"):
        (cmd_print_guide if args.action == "guide" else cmd_print_combos)()
        return

    # Check reachability
    try:
        urllib.request.urlopen(f"{args.url}/v1/models", timeout=5)
    except Exception:
        log.error("❌ Cannot reach 9Router at %s", args.url)
        log.error("   Start it: docker compose -f compose.proxy-pool.yaml up -d 9router")
        sys.exit(1)
    log.info("✅ 9Router is running at %s", args.url)

    token = login(args.url, args.password)

    if args.action == "list":
        cmd_list_models(args.url, token)
        return

    if args.action == "setup":
        log.info("\n═══ Step 1: Configure providers ═══")
        configure_providers(args.url, token)
        log.info("\n═══ Step 2: Optimal combos ═══")
        cmd_print_combos()
        log.info("\n═══ Step 3: Verify ═══")
        v = verify_setup(args.url, token)
        log.info("  Models:  %d", v["models_available"])
        log.info("  Free:    %s", "✅" if v["has_free"] else "❌")
        log.info("  Cheap:   %s", "✅" if v["has_cheap"] else "❌")
        log.info("  Test:    %s", "✅" if v["test_ok"] else "⚠️  (manual Dashboard setup needed)")
        if not v["test_ok"]:
            log.info("\n  → Open Dashboard: %s to add providers + combos", args.url)

    elif args.action == "verify":
        v = verify_setup(args.url, token)
        log.info("Models: %d | Free: %s | Cheap: %s | Test: %s",
                 v["models_available"],
                 "✅" if v["has_free"] else "❌",
                 "✅" if v["has_cheap"] else "❌",
                 "✅" if v["test_ok"] else "❌")


if __name__ == "__main__":
    main()



