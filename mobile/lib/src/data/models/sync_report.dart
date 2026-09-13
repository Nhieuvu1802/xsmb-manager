/// Kết quả đồng bộ, trạng thái nguồn và lịch sử đồng bộ.
library;

import '../../domain/lottery_domain.dart';
import 'draw_record.dart';

enum SyncOutcome { success, partial, failed, upToDate }

extension SyncOutcomeLabel on SyncOutcome {
  String get label => switch (this) {
    SyncOutcome.success => 'Thành công',
    SyncOutcome.partial => 'Một phần',
    SyncOutcome.failed => 'Thất bại',
    SyncOutcome.upToDate => 'Đã mới nhất',
  };
}

/// Provider thuộc loại nào — dùng cho UI "nguồn đang sử dụng".
enum ProviderKind { backend, github, direct, cache }

class SourceDescriptor {
  const SourceDescriptor({
    required this.name,
    required this.kind,
    required this.available,
    required this.description,
  });

  final String name;
  final ProviderKind kind;
  final bool available;
  final String description;

  String get kindLabel => switch (kind) {
    ProviderKind.backend => 'API của dự án',
    ProviderKind.github => 'GitHub backup',
    ProviderKind.direct => 'Nguồn công khai',
    ProviderKind.cache => 'Bộ nhớ máy',
  };
}

/// Trạng thái sức khoẻ của một provider theo vùng.
class ProviderStatusRecord {
  const ProviderStatusRecord({
    required this.provider,
    required this.region,
    this.lastSuccessAt,
    this.lastFailureAt,
    this.latencyMs = 0,
    this.successes = 0,
    this.failures = 0,
    this.lastError,
  });

  final String provider;
  final Region region;
  final String? lastSuccessAt;
  final String? lastFailureAt;
  final int latencyMs;
  final int successes;
  final int failures;
  final String? lastError;

  ProviderStatusRecord copyWith({
    String? lastSuccessAt,
    String? lastFailureAt,
    int? latencyMs,
    int? successes,
    int? failures,
    String? lastError,
  }) => ProviderStatusRecord(
    provider: provider,
    region: region,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    lastFailureAt: lastFailureAt ?? this.lastFailureAt,
    latencyMs: latencyMs ?? this.latencyMs,
    successes: successes ?? this.successes,
    failures: failures ?? this.failures,
    lastError: lastError ?? this.lastError,
  );

  Map<String, Object?> toRow() => <String, Object?>{
    'provider': provider,
    'region': region.code,
    'last_success_at': lastSuccessAt,
    'last_failure_at': lastFailureAt,
    'latency_ms': latencyMs,
    'successes': successes,
    'failures': failures,
    'last_error': lastError,
  };

  factory ProviderStatusRecord.fromRow(Map<String, Object?> row) =>
      ProviderStatusRecord(
        provider: (row['provider'] ?? '').toString(),
        region: regionFromCode(row['region']?.toString()),
        lastSuccessAt: row['last_success_at']?.toString(),
        lastFailureAt: row['last_failure_at']?.toString(),
        latencyMs: (row['latency_ms'] as num?)?.toInt() ?? 0,
        successes: (row['successes'] as num?)?.toInt() ?? 0,
        failures: (row['failures'] as num?)?.toInt() ?? 0,
        lastError: row['last_error']?.toString(),
      );
}

/// Một dòng lịch sử đồng bộ.
class SyncHistoryRecord {
  const SyncHistoryRecord({
    required this.region,
    required this.startedAt,
    required this.finishedAt,
    required this.provider,
    required this.status,
    this.inserted = 0,
    this.updated = 0,
    this.rejected = 0,
    this.note,
  });

  final Region region;
  final String startedAt;
  final String finishedAt;
  final String provider;
  final SyncOutcome status;
  final int inserted;
  final int updated;
  final int rejected;
  final String? note;

  Map<String, Object?> toRow() => <String, Object?>{
    'region': region.code,
    'started_at': startedAt,
    'finished_at': finishedAt,
    'provider': provider,
    'status': status.name,
    'inserted': inserted,
    'updated': updated,
    'rejected': rejected,
    'note': note,
  };

  factory SyncHistoryRecord.fromRow(Map<String, Object?> row) =>
      SyncHistoryRecord(
        region: regionFromCode(row['region']?.toString()),
        startedAt: (row['started_at'] ?? '').toString(),
        finishedAt: (row['finished_at'] ?? '').toString(),
        provider: (row['provider'] ?? '').toString(),
        status: SyncOutcome.values.firstWhere(
          (item) => item.name == row['status'],
          orElse: () => SyncOutcome.failed,
        ),
        inserted: (row['inserted'] as num?)?.toInt() ?? 0,
        updated: (row['updated'] as num?)?.toInt() ?? 0,
        rejected: (row['rejected'] as num?)?.toInt() ?? 0,
        note: row['note']?.toString(),
      );
}

/// Báo cáo trả về cho UI sau mỗi lần đồng bộ.
class SyncReport {
  const SyncReport({
    required this.region,
    required this.status,
    required this.provider,
    required this.startedAt,
    required this.finishedAt,
    this.inserted = 0,
    this.updated = 0,
    this.rejected = 0,
    this.messages = const <String>[],
    this.latestDate,
    this.attemptedProviders = const <String>[],
  });

  final Region region;
  final SyncOutcome status;
  final String provider;
  final String startedAt;
  final String finishedAt;
  final int inserted;
  final int updated;
  final int rejected;
  final List<String> messages;
  final String? latestDate;
  final List<String> attemptedProviders;

  int get newRecords => inserted + updated;

  String get summary {
    if (status == SyncOutcome.upToDate) return 'Dữ liệu đã mới nhất.';
    return '$provider: +$inserted mới, $updated cập nhật, $rejected bị loại';
  }

  factory SyncReport.failed({
    required Region region,
    required String startedAt,
    required List<String> messages,
    List<String> attemptedProviders = const <String>[],
  }) => SyncReport(
    region: region,
    status: SyncOutcome.failed,
    provider: attemptedProviders.isEmpty ? 'không có' : attemptedProviders.last,
    startedAt: startedAt,
    finishedAt: DateTime.now().toIso8601String(),
    messages: messages,
    attemptedProviders: attemptedProviders,
  );
}
