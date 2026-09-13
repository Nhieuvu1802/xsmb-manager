# Thống Kê 24 — app Flutter (Android + Web)

App duy nhất cho Android và Web: lấy kết quả XSMB/XSMN từ nhiều nguồn có dự phòng, lưu database cục bộ, tính chỉ số 00–99, xếp hạng theo **Điểm thống kê** và kiểm chứng bằng backtest walk-forward.

## Kiến trúc

```text
lib/
├── main.dart                     # bootstrap: store, chuỗi provider, repository, theme
└── src/
    ├── core/
    │   ├── config/app_config.dart     # timeout, retry, URL API mặc định, khoá lưu
    │   ├── network/json_http_client.dart  # timeout + retry + log + đo độ trễ
    │   └── utils/lottery_dates.dart   # ngày ISO, giờ VN, lịch đài XSMN
    ├── data/
    │   ├── models/                    # DrawRecord, PrizeRecord, SyncReport, prediction, backtest
    │   ├── local/                     # LocalStore: SQLite (native) / localStorage (web)
    │   ├── providers/                 # LotteryDataProvider + 3 nguồn + chuỗi dự phòng
    │   └── repositories/              # LotteryRepository: kiểm tra → tải → kiểm định → ghi
    ├── domain/
    │   ├── statistics/                # engine 00–99: rolling, gap, EWMA, momentum, stability
    │   ├── archive/                   # kho số dạng tidy `id | date | variable | value`
    │   ├── generator/                 # "Bộ tính số": trọng số theo lịch sử + seed tái lập
    │   ├── scoring/                   # PredictionEngine → Điểm thống kê 0–100
    │   └── backtest/                  # walk-forward + baseline tần suất/ngẫu nhiên
    ├── logic/                         # công thức thuần port từ bản web (parity vectors)
    └── ui/                            # shell + theme + tabs
```

### Chuỗi nguồn dữ liệu

```text
BackendApiProvider (ApiConfig.baseUrl → Cloudflare Worker xsmb-api.nhieuvu1802.workers.dev/v1)
      ↓ lỗi / timeout / dữ liệu sai schema
GitHubJsonProvider (public-data JSON — chỉ bật khi GITHUB_FALLBACK_ENABLED=true)
      ↓ lỗi
LocalCacheProvider (database cục bộ — luôn có, kể cả khi mất mạng)
```

Mỗi lần thử đều ghi `provider_status` (thành công/lỗi, độ trễ, lỗi gần nhất) và log; UI hiển thị nguồn đang dùng.

> **Nguồn GitHub mặc định đang tắt.** Repo `xsmb-manager` hiện private nên
> `raw.githubusercontent.com/.../public-data/...` trả 404 → `GitHubJsonProvider`
> được tạo với `enabled: ApiConfig.githubFallbackEnabled` (mặc định `false`).
> Chuỗi thực tế vì vậy là **Worker → cache cục bộ**. Khi snapshot được công khai,
> build lại với `--dart-define=GITHUB_FALLBACK_ENABLED=true`
> (có thể đổi URL bằng `--dart-define=GITHUB_PUBLIC_DATA_BASE_URL=...`).

### Model dùng chung (STEP 5)

Một kỳ quay chỉ có một hình dạng dữ liệu đi qua mọi tầng, khai báo tại
`lib/src/data/models/lottery_models.dart` cùng `DrawRecord`:

| Tầng | Kiểu | Ghi chú |
| --- | --- | --- |
| JSON Worker v1 | `draws[].results[]` | `prize`, `position`, `value`, `station`, `source` |
| Dữ liệu | `DrawRecord` (+ bí danh `LotteryResult`), `PrizeRecord`, `LotteryStation` | `fromJson`/`toJson` là hợp đồng duy nhất |
| UI | `LotteryDraw`, `PrizeResult` | `DrawRecord.toDomain()` là cầu nối duy nhất |
| Vận hành | `DatasetMeta`, `SystemStatus`, `DataSourceKind` | `datasetVersion`/`datasetDate`/nguồn/cache |

### Database cục bộ (Phase 5)

| Bảng | Khoá duy nhất | Vai trò |
| --- | --- | --- |
| `draws` | `region + draw_date + station` | kỳ quay |
| `draw_results` | `region + draw_date + station + prize + position` | từng giải, có `loto2` để lập chỉ mục |
| `stations` | `region + code` | danh mục đài |
| `sync_history` | — | lịch sử đồng bộ |
| `provider_status` | `provider + region` | sức khoẻ nguồn |
| `prediction_runs` / `prediction_results` | `run_id + number` | lượt xếp hạng đã lưu |
| `backtest_runs` | `region + created_at + model + window_days` | kết quả backtest |
| `dataset_meta` | `region` | `datasetVersion`/`datasetDate`/nguồn của lần tải gần nhất (STEP 5) |
| `generated_runs` / `generated_sets` | `run_id + set_index` | bộ số đã sinh kèm seed + cấu hình (tab **Bộ tính số**) |

Schema hiện là **v3** (`kLocalSchemaVersion`); nâng cấp chỉ chạy
`CREATE TABLE IF NOT EXISTS` nên dữ liệu v1/v2 không bị mất.

**Bất biến (đã gây lỗi cài mới):** mọi `PRAGMA` cấp kết nối — `journal_mode = WAL`,
`synchronous`, `foreign_keys`, `busy_timeout` — **chỉ** được đặt trong
`onConfigure`. sqflite chạy `onCreate`/`onUpgrade` bên trong một transaction, mà
SQLite từ chối đổi chế độ journal/mức an toàn lúc đó (`cannot change into wal mode
from within a transaction`, `Safety level may not be changed inside a transaction`);
đặt sai chỗ làm `openDatabase()` ném lỗi ngay trước `runApp()` ⇒ app chỉ còn nền
trắng khi cài mới. `test/data/sqlite_pragma_guard_test.dart` đọc chính mã nguồn
của store để chốt bất biến này.

### Bộ tính số (tab "Bộ tính số")

- Sinh bộ số 00–99 theo 5 chiến lược: `uniform` (rút đều), `hot` (tần suất),
  `cold` (gan), `balanced` (30 kỳ 0,45 + độ mới 0,25 + gan 0,30 từ engine 00–99)
  và `weekday` (số hay về đúng thứ của ngày mục tiêu). Trọng số lấy từ
  `domain/archive/lotto_archive.dart` — kho số dạng tidy giống repo tham chiếu
  `LottoNumberArchive`.
- Rút thăm theo trọng số bằng Efraimidis–Spirakis (`(1/w)·(−ln u)`), **seed tái
  lập được** bằng `Mulberry32` (`logic/seeded_random.dart`): cùng seed + cùng
  cấu hình ⇒ cùng bộ số. Hỗ trợ nhiều bộ mỗi lần sinh, loại trừ số, sắp xếp
  tăng/giảm/không sắp xếp và bóng "đặc biệt" chọn riêng (như
  `Random-Number-Generator`).
- Mỗi bộ được **đối chiếu lịch sử** (`domain/generator/history_match.dart`): bao
  nhiêu kỳ trong cửa sổ có ít nhất một số của bộ, kèm khoảng tin cậy Wilson 95%
  để nói rõ khác biệt so với xác suất lý thuyết chỉ là dao động mẫu.
- Lịch sử sinh lưu trong `generated_runs`/`generated_sets` (schema v3) và nạp lại
  được đúng cấu hình + seed.
- Bản Python sinh ra **đúng cùng bộ số**: `backend/xsmb_manager/generator.py`;
  giá trị vàng nằm ở `test/domain/generator_parity_test.dart` và
  `backend/tests/test_generator.py`.
- Giới hạn: đây là thống kê mô tả quá khứ, **không** phải xác suất trúng; UI luôn
  hiển thị câu cảnh báo `GeneratorOutcome.disclaimer`.

### Đồng bộ và chế độ ngoại tuyến (STEP 7–11)

- Cache trống (cài mới/đổi máy) → tải cửa sổ **bootstrap 365 ngày** rồi các lần
  sau **chỉ tải khoảng còn thiếu** (`AppConfig.bootstrapSyncDays`).
- Máy đã cài từ bản cũ chỉ có vài kỳ (cache **gần như trống**, dưới
  `LotteryRepository.shallowHistoryDays` = 31 ngày) sẽ tự **tải bù cả cửa sổ 365
  ngày** ở lần đồng bộ kế tiếp — không cần xoá app hay cài lại.
- API phục vụ cửa sổ lịch sử đó qua `/v1/{xsmb,xsmn}/history?start=&end=`; snapshot
  dự phòng `public-data/{region}/history.json` (365 ngày, mỗi kỳ giữ đài riêng)
  được Worker bundle sẵn nên lần mở đầu tiên đã có ~1 năm kỳ để thống kê/backtest.
  `GitHubJsonProvider` đọc `history.json` trước, chỉ khi file đó thiếu mới rơi về
  `latest.json` (một ngày).
- API lỗi → chuỗi rơi về `LocalCacheProvider`; app vẫn hiển thị kỳ đã lưu và
  tab **Nguồn & cài đặt** hiện thẻ *Tình trạng hệ thống*: API online/offline,
  endpoint, ngày + phiên bản dataset, lần đồng bộ thành công, ngày cache, nguồn
  đang dùng, phiên bản app.
- Thẻ này **không tự đổi endpoint**: nếu `/v1/config` khai host khác
  (`api.vvn.freedev.app`) thì chỉ cảnh báo, vẫn dùng URL đang chạy được.
- Kỳ nhận về nhưng không hợp lệ (hoặc rỗng) ⇒ báo cáo là **thất bại**, không
  ghi cache và không báo "thành công" giả.

Native dùng SQLite (`sqflite`, WAL, foreign keys). Web dùng `localStorage` giữ cửa sổ dữ liệu gần nhất; lịch sử dài nằm ở backend. Chọn hiện thực bằng conditional import nên `sqflite` không lọt vào bản build web.

## Chạy

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run                                   # debug: cho phép HTTP tới API local
flutter run                                   # mặc định: VVN production API
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787/v1
```

Trong app: mở tab **Nguồn & cài đặt** để đổi URL API, xem trạng thái nguồn, lịch sử đồng bộ, kích thước database và chạy kiểm tra nguồn. Nút **Cập nhật** (nổi) đồng bộ các kỳ còn thiếu; app cũng tự đồng bộ khi mở nhưng **không** tải lại toàn bộ lịch sử.

Bản release chặn HTTP thường (`usesCleartextTraffic="false"`) → API phải là HTTPS. Bản debug cho phép HTTP để dùng `http://10.0.2.2:8000` (emulator) hoặc IP LAN.

## Giao diện

Bảng màu và ngôn ngữ component bám theo trang tham chiếu **xosothongminh.tech**
(Tailwind v4) — xem `lib/src/ui/theme.dart`:

| Token | Sáng (mặc định) | Tối |
| --- | --- | --- |
| Nền app | `slate-50` `#F8FAFC` | `navy-950` `#031027` |
| Thẻ/panel | trắng `#FFFFFF`, viền `slate-200` `#E2E8F0` | `#0A1D38`, viền `slate-800` |
| Màu thương hiệu | cam `orange-600` `#EA580C` (hover `#C2410C`, nền nhạt `orange-100` `#FFEDD5`) | `orange-400` `#FB923C` |
| Dải hero | navy `#031027 → #0B224A` + quầng sáng cam | như bản sáng |
| Thang nhiệt 00–99 | vàng `#F6D35A` → cam `#FB923C` | như bản sáng |

Quy ước: thẻ bo `radius = 12` với bóng `shadow-sm` (1px, alpha 4%), chip/nhãn bo
tròn hoàn toàn, số liệu dùng chữ `w900` + `tabularFigures()`, nhãn khu vực in hoa
màu cam. Component dùng chung nằm ở `lib/src/ui/widgets.dart`: `Panel`,
`PanelHeader`, `PageHeading`, `SectionHeading`, `StatusChip`, `StatTile`,
`ScoreBar`, `SignalCard`, `HeroBand`, `NumberPill`, `AppButton`, `MetricCard`.

Tab **Tổng quan** theo bố cục trang chủ của bản web: dải hero + thẻ "Tóm tắt hôm
nay" → "Lịch quay kế tiếp" → "Tín hiệu thống kê nổi bật" (điểm dữ liệu 0–100 quy
đổi từ z-score: `50 + 20·z`, kẹp 0–100) → thẻ số liệu → kết quả kỳ mới nhất →
nhịp số → bản đồ 00–99 → cặp số/ngày trong tuần. Các tab còn lại kế thừa cùng
theme và component.

## Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release
```

Hoặc dùng script có sẵn (tạo bản universal + tách theo ABI vào `mobile/dist/`):

```bat
tool\build_apk.bat
tool\build_apk.bat https://api.vvn.freedev.app/v1   REM ví dụ ghi đè khi chuyển domain
```

APK release hiện ký bằng keystore debug của Flutter: cài trực tiếp được nhưng **chưa** đủ điều kiện lên Google Play. Muốn phát hành: tạo upload key và đặt `ANDROID_KEYSTORE_PATH`/`ANDROID_KEYSTORE_PASSWORD`/`ANDROID_KEY_ALIAS`/`ANDROID_KEY_PASSWORD` (xem `docs/ANDROID_RELEASE.md`). Không commit keystore hay mật khẩu.

**`versionCode` khác nhau giữa bản universal và bản tách ABI:** Flutter cộng offset
theo ABI khi build `--split-per-abi`, nên cùng `2.0.0+4` ta được universal `4`,
`armeabi-v7a` `1004`, `arm64-v8a` `2004`, `x86_64` `4004`. Hệ quả: cài bản universal
**sau** khi đã cài bản tách ABI sẽ báo `INSTALL_FAILED_VERSION_DOWNGRADE` (Android
coi là hạ cấp, kể cả khi cài đè bằng `adb install -r`). Khi đó gỡ app cũ
(`adb uninstall vn.xsmb.xsmb_manager`) rồi cài lại, hoặc chỉ dùng một loại APK trên
một máy.

## Xử lý sự cố

**Màn hình trắng (hoặc chỉ thấy nền tối) khi vừa cài app.** Từ bản `2.0.0+4` app
không còn "chết im" trước `runApp` nữa:

- Nền cửa sổ Android (`LaunchTheme`/`NormalTheme`, cùng `drawable`/`drawable-v21`)
  dùng màu `tk24_bg` khai báo ở **cả** `values` (`#F8FAFC`, bản sáng mặc định) và
  `values-night` (`#031027`, chế độ tối hệ thống), nên splash luôn cùng tông với
  giao diện thay vì nháy trắng rồi mới vào app.
- Lỗi trong `main()`/`buildRoot()` ⇒ `StartupFailureApp`
  (`lib/src/ui/startup_error_app.dart`): hiện nguyên nhân, stack trace, phiên bản
  build, host API và nút **Thử lại** (chạy lại bootstrap, không cần mở lại app).
- `ErrorWidget.builder` cũng hiện chữ đọc được thay vì ô xám của bản release, và
  `PlatformDispatcher.onError` ghi log lỗi async thay vì để app thoát.
- SQLite tự chữa: file DB hỏng/không nâng cấp được thì tự xoá và tạo lại; nếu vẫn
  không mở được thì chuyển sang DB trong bộ nhớ để UI chạy được (dữ liệu sẽ được
  tải lại từ API ở lần đồng bộ sau).

Bản `2.0.0+3` trở về trước bị trắng màn hình trên máy cài mới vì `PRAGMA` nằm
trong `onCreate` — xem *Bất biến* ở mục **Database cục bộ**.

Muốn log thô khi app vẫn sai:

```bash
adb logcat -c && adb logcat -s flutter:V AndroidRuntime:E
```

Nhật ký trong app (`appLogger`, ví dụ khoá `local-store`) nằm ở thẻ log của tab
**Nguồn & cài đặt**, nhưng chỉ xem được khi giao diện chính đã dựng.

## Điểm thống kê và giới hạn

- Điểm 0–100 là **thứ hạng tương đối** giữa 100 số sau khi chuẩn hoá feature; không phải xác suất trúng.
- Backtest dùng walk-forward: mỗi ngày D chỉ dùng dữ liệu trước D; so với baseline tần suất và baseline ngẫu nhiên có seed; kết quả được nêu rõ nếu mô hình không vượt baseline.
- App không có nạp/rút tiền, ví, đặt cược hay tuyên bố trúng thưởng.

## Kiểm thử

```bash
flutter test        # 190 test: thống kê, scoring, backtest, bộ tính số (sinh số + đối chiếu), provider fallback, SQLite, parser, contract API, repository sync, widget, design system (bảng màu + component giao diện), màn hình lỗi khởi động
flutter test        # 6 test live (gọi API production thật) bị skip mặc định; bật bằng $env:XSM_LIVE_API='1' rồi flutter test test/live/production_api_live_test.dart
```

Bộ vector `test/fixtures/parity_vectors.json` giữ công thức thuần (tần suất, cấu trúc dãy số, ngày trong tuần) trùng bản web; xem `test/fixtures/README.md` để sinh lại.
