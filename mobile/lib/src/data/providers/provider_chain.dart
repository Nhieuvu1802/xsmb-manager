/// Chuỗi dự phòng: VVN API → GitHub JSON public → cache SQLite cục bộ.
///
/// Mỗi lần thử đều được ghi log và cập nhật `provider_status`, kể cả khi thất
/// bại, để UI hiển thị đúng nguồn đang dùng và sức khoẻ từng nguồn.
library;

import '../../core/logging/app_logger.dart';
import '../../domain/lottery_domain.dart';
import '../local/local_store.dart';
import '../models/sync_report.dart';
import 'lottery_data_provider.dart';

class ProviderAttempt {
  const ProviderAttempt({
    required this.provider,
    required this.kind,
    required this.ok,
    required this.message,
    this.latencyMs = 0,
    this.recordCount = 0,
  });

  final String provider;
  final ProviderKind kind;
  final bool ok;
  final String message;
  final int latencyMs;
  final int recordCount;
}

class ProviderChainOutcome {
  const ProviderChainOutcome({this.result, required this.attempts});

  final ProviderFetchResult? result;
  final List<ProviderAttempt> attempts;

  bool get hasData => (result?.draws.isNotEmpty) ?? false;
  bool get isEmptySuccess => result != null && result!.draws.isEmpty;
  String get usedProvider => result?.provider ?? 'không có';

  List<String> get messages => <String>[
    for (final attempt in attempts)
      '${attempt.ok ? '✓' : '✗'} ${attempt.provider}: ${attempt.message}',
  ];
}

class LotteryProviderChain {
  LotteryProviderChain({
    required List<LotteryDataProvider> providers,
    this.store,
    AppLogger? logger,
  }) : providers = List<LotteryDataProvider>.unmodifiable(providers),
       _logger = logger ?? appLogger;

  /// Thứ tự ưu tiên: phần tử đầu được thử trước.
  final List<LotteryDataProvider> providers;
  final LocalStore? store;
  final AppLogger _logger;

  List<SourceDescriptor> describeSources() => <SourceDescriptor>[
    for (final provider in providers)
      SourceDescriptor(
        name: provider.name,
        kind: provider.kind,
        available: provider.isAvailable,
        description: provider.isAvailable
            ? provider.availabilityNote
            : '${provider.availabilityNote} (tạm tắt)',
      ),
  ];

  Future<ProviderChainOutcome> fetchByDate({
    required Region region,
    required DateTime date,
  }) => _run(
    region: region,
    request: (provider) =>
        provider.getResultsByDate(region: region, date: date),
  );

  Future<ProviderChainOutcome> fetchLatest({
    required Region region,
    int days = 7,
  }) => _run(
    region: region,
    request: (provider) =>
        provider.getLatestResults(region: region, days: days),
  );

  Future<ProviderChainOutcome> fetchRange({
    required Region region,
    required DateTime start,
    required DateTime end,
  }) => _run(
    region: region,
    request: (provider) =>
        provider.getHistoricalResults(region: region, start: start, end: end),
  );

  /// Thử từng nguồn theo thứ tự, dừng ở nguồn đầu tiên trả dữ liệu.
  Future<ProviderChainOutcome> _run({
    required Region region,
    required Future<ProviderFetchResult> Function(LotteryDataProvider provider)
    request,
  }) async {
    final attempts = <ProviderAttempt>[];
    ProviderFetchResult? emptyResult;

    for (final provider in providers) {
      if (!provider.isAvailable) {
        attempts.add(
          ProviderAttempt(
            provider: provider.name,
            kind: provider.kind,
            ok: false,
            message: provider.availabilityNote,
          ),
        );
        continue;
      }
      final started = DateTime.now();
      try {
        final result = await request(provider);
        final latency = DateTime.now().difference(started).inMilliseconds;
        if (result.draws.isEmpty) {
          attempts.add(
            ProviderAttempt(
              provider: provider.name,
              kind: provider.kind,
              ok: false,
              message: 'Không có kỳ nào.',
              latencyMs: latency,
            ),
          );
          emptyResult ??= result;
          await _record(
            provider: provider.name,
            region: region,
            success: false,
            latencyMs: latency,
            message: 'Không có kỳ nào.',
          );
          continue;
        }
        attempts.add(
          ProviderAttempt(
            provider: provider.name,
            kind: provider.kind,
            ok: true,
            message: '${result.draws.length} kỳ (${latency}ms)',
            latencyMs: latency,
            recordCount: result.draws.length,
          ),
        );
        await _record(
          provider: provider.name,
          region: region,
          success: true,
          latencyMs: latency,
          message: '${result.draws.length} kỳ',
        );
        return ProviderChainOutcome(result: result, attempts: attempts);
      } on ProviderException catch (error) {
        final latency = DateTime.now().difference(started).inMilliseconds;
        _logger.warning('chain', '${error.provider} lỗi: ${error.message}');
        attempts.add(
          ProviderAttempt(
            provider: provider.name,
            kind: provider.kind,
            ok: false,
            message: error.message,
            latencyMs: latency,
          ),
        );
        await _record(
          provider: provider.name,
          region: region,
          success: false,
          latencyMs: latency,
          message: error.message,
        );
      } catch (error) {
        final latency = DateTime.now().difference(started).inMilliseconds;
        _logger.error('chain', '${provider.name} lỗi ngoài dự kiến', error);
        attempts.add(
          ProviderAttempt(
            provider: provider.name,
            kind: provider.kind,
            ok: false,
            message: '$error',
            latencyMs: latency,
          ),
        );
        await _record(
          provider: provider.name,
          region: region,
          success: false,
          latencyMs: latency,
          message: '$error',
        );
      }
    }

    return ProviderChainOutcome(result: emptyResult, attempts: attempts);
  }

  Future<List<ProviderAttempt>> healthCheckAll() async {
    final attempts = <ProviderAttempt>[];
    for (final provider in providers) {
      if (!provider.isAvailable) {
        attempts.add(
          ProviderAttempt(
            provider: provider.name,
            kind: provider.kind,
            ok: false,
            message: provider.availabilityNote,
          ),
        );
        continue;
      }
      final started = DateTime.now();
      try {
        await provider.healthCheck();
        attempts.add(
          ProviderAttempt(
            provider: provider.name,
            kind: provider.kind,
            ok: true,
            message: 'Sẵn sàng',
            latencyMs: DateTime.now().difference(started).inMilliseconds,
          ),
        );
      } on ProviderException catch (error) {
        attempts.add(
          ProviderAttempt(
            provider: provider.name,
            kind: provider.kind,
            ok: false,
            message: error.message,
            latencyMs: DateTime.now().difference(started).inMilliseconds,
          ),
        );
      }
    }
    return attempts;
  }

  Future<void> _record({
    required String provider,
    required Region region,
    required bool success,
    required int latencyMs,
    required String message,
  }) async {
    final target = store;
    if (target == null || !target.isOpen) return;
    try {
      final existing = await target.providerStatuses(region: region);
      ProviderStatusRecord? current;
      for (final item in existing) {
        if (item.provider == provider) {
          current = item;
          break;
        }
      }
      final now = DateTime.now().toIso8601String();
      await target.upsertProviderStatus(
        ProviderStatusRecord(
          provider: provider,
          region: region,
          lastSuccessAt: success ? now : current?.lastSuccessAt,
          lastFailureAt: success ? current?.lastFailureAt : now,
          latencyMs: latencyMs,
          successes: (current?.successes ?? 0) + (success ? 1 : 0),
          failures: (current?.failures ?? 0) + (success ? 0 : 1),
          lastError: success ? current?.lastError : message,
        ),
      );
    } catch (error) {
      _logger.warning('chain', 'Không ghi được provider_status: $error');
    }
  }
}
