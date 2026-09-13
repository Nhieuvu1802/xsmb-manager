/// Màn hình lỗi khởi động + bắt lỗi toàn cục.
///
/// Bản release không có "red screen" như bản debug: nếu `main()` ném lỗi trước
/// `runApp` (ví dụ không mở được SQLite) thì người dùng chỉ thấy nền trắng của
/// LaunchTheme và không biết chuyện gì xảy ra. File này bảo đảm **mọi** lỗi
/// khởi động đều trở thành màn hình đọc được, kèm nút thử lại và thông tin
/// chẩn đoán (phiên bản app, host API, stack trace).
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import 'theme.dart';

/// Gắn hook bắt lỗi toàn cục cho cả lỗi build widget lẫn lỗi async.
void installGlobalErrorHandlers() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    previous?.call(details);
    appLogger.error('flutter', details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    appLogger.error('platform', '$error', stackTrace);
    // Đã ghi log: không để lỗi async làm app thoát hoặc màn hình trắng.
    return true;
  };
  ErrorWidget.builder = (FlutterErrorDetails details) => StartupErrorView(
    title: 'Lỗi hiển thị',
    message: details.exceptionAsString(),
    compact: true,
  );
}

/// Nội dung màn hình lỗi; dùng lại cho cả `ErrorWidget.builder`.
class StartupErrorView extends StatelessWidget {
  const StartupErrorView({
    required this.title,
    required this.message,
    this.details,
    this.stackTrace,
    this.onRetry,
    this.retryLabel = 'Thử lại',
    this.busy = false,
    this.compact = false,
    super.key,
  });

  final String title;
  final String message;
  final String? details;
  final StackTrace? stackTrace;
  final Future<void> Function()? onRetry;
  final String retryLabel;
  final bool busy;

  /// Chế độ thu gọn cho `ErrorWidget.builder`: chỉ tiêu đề + thông báo.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const palette = AppPalette.dark;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: palette.bg,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 12 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.panelRaised,
                    borderRadius: BorderRadius.circular(AppPalette.radius),
                    border: Border.all(color: palette.coral),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.error_outline,
                            color: palette.coral,
                            size: compact ? 18 : 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: palette.text,
                                fontSize: compact ? 13 : 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (compact) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.mutedBright,
                            fontSize: 11,
                          ),
                        ),
                      ] else ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Phiên bản ${AppConfig.appVersionLabel} · '
                          'API ${ApiConfig.host} · dữ liệu đã lưu vẫn dùng được.',
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                        ..._sections(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sections() => <Widget>[
    if (details != null) ...<Widget>[
      const SizedBox(height: 14),
      SelectableText(
        details!,
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    ],
    if (stackTrace != null) ...<Widget>[
      const SizedBox(height: 10),
      SelectableText(
        '$stackTrace',
        maxLines: 14,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10.5,
          fontFamily: 'monospace',
        ),
      ),
    ],
    if (onRetry != null) ...<Widget>[
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: busy ? null : () => onRetry!(),
        icon: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 18),
        label: Text(busy ? 'Đang thử lại…' : retryLabel),
      ),
    ],
  ];
}

/// App thay thế khi khởi động thất bại: hiện lỗi và cho phép chạy lại bootstrap.
class StartupFailureApp extends StatefulWidget {
  const StartupFailureApp({
    required this.error,
    required this.stackTrace,
    required this.bootstrap,
    super.key,
  });

  final Object error;
  final StackTrace stackTrace;

  /// Hàm dựng cây widget gốc; trả về `StartupFailureApp` nếu vẫn lỗi.
  final Future<Widget> Function() bootstrap;

  @override
  State<StartupFailureApp> createState() => _StartupFailureAppState();
}

class _StartupFailureAppState extends State<StartupFailureApp> {
  late Object _error = widget.error;
  late StackTrace _stackTrace = widget.stackTrace;
  Widget? _child;
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      final result = await widget.bootstrap();
      if (!mounted) return;
      if (result is StartupFailureApp) {
        setState(() {
          _error = result.error;
          _stackTrace = result.stackTrace;
          _busy = false;
        });
        return;
      }
      setState(() {
        _child = result;
        _busy = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    if (child != null) return child;
    return MaterialApp(
      title: 'Thống Kê 24',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(AppPalette.dark),
      home: Scaffold(
        body: StartupErrorView(
          title: 'Không khởi động được',
          message:
              'Ứng dụng gặp lỗi khi chuẩn bị dữ liệu cục bộ nên chưa mở được '
              'giao diện. Chi tiết bên dưới giúp xác định nguyên nhân:\n\n'
              '$_error',
          // Không trỏ sang tab "Nguồn & cài đặt": khi màn hình này hiện thì
          // giao diện chính chưa được dựng nên không có tab nào để xem.
          details:
              'dữ liệu: SQLite cục bộ, dự phòng API ${ApiConfig.host}\n'
              'build: ${AppConfig.appVersionLabel}\n'
              'Bấm "Thử lại" để chạy lại bước chuẩn bị; nếu vẫn lỗi, gửi phần '
              'chẩn đoán này để kiểm tra.',
          stackTrace: _stackTrace,
          onRetry: _retry,
          busy: _busy,
        ),
      ),
    );
  }
}
