import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lottery_result.dart';
import '../services/api_client.dart';
import '../services/result_cache.dart';
import '../widgets/date_filter.dart';
import '../widgets/result_board.dart';
import '../widgets/statistics_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiClient();
  final _cache = ResultCache();
  final _results = <LotteryRegion, List<LotteryResult>>{
    LotteryRegion.mb: const [],
    LotteryRegion.mn: const [],
  };

  late DateTime _start;
  late DateTime _end;
  LotteryRegion _activeRegion = LotteryRegion.mb;
  int _selectedIndex = 0;
  bool _loading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = _end.subtract(const Duration(days: 6));
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final values = await _api.getResults(
        _activeRegion,
        start: _start,
        end: _end,
      );
      if (!mounted) return;
      setState(() => _results[_activeRegion] = values);
      await _cache.save(_activeRegion, values);
    } catch (error) {
      final cached = await _cache.load(_activeRegion);
      if (!mounted) return;
      if (cached.isNotEmpty) setState(() => _results[_activeRegion] = cached);
      _notice(
        cached.isEmpty
            ? _errorMessage(error)
            : 'Không kết nối được API. Đang hiển thị dữ liệu gần nhất trên máy.',
        error: cached.isEmpty,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _synchronize() async {
    if (_token == null && !await _login()) return;
    setState(() => _loading = true);
    try {
      final count = await _api.synchronize(
        _activeRegion,
        start: _start,
        end: _end,
        token: _token!,
      );
      if (!mounted) return;
      _notice('Đã đồng bộ $count kỳ/đài.');
      setState(() => _loading = false);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      _notice(_errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _login() async {
    final username = TextEditingController();
    final password = TextEditingController();
    final credentials = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập quản trị'),
        content: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: username,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (username.text.trim(), password.text)),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
    username.dispose();
    password.dispose();
    if (credentials == null ||
        credentials.$1.isEmpty ||
        credentials.$2.isEmpty) {
      return false;
    }
    try {
      final token = await _api.login(credentials.$1, credentials.$2);
      if (!mounted) return false;
      setState(() => _token = token);
      _notice('Đã đăng nhập. Token chỉ được giữ trong phiên đang mở.');
      return true;
    } catch (error) {
      if (mounted) _notice(_errorMessage(error), error: true);
      return false;
    }
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
      if (index < 2) {
        _activeRegion = index == 0 ? LotteryRegion.mb : LotteryRegion.mn;
      }
    });
    if (index < 2 && _results[_activeRegion]!.isEmpty) unawaited(_refresh());
  }

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  String _errorMessage(Object error) => error is ApiException
      ? error.message
      : 'Không thể kết nối API. Kiểm tra địa chỉ máy chủ và kết nối mạng.';

  @override
  Widget build(BuildContext context) {
    final regionResults = _results[_activeRegion]!;
    final regionLabel =
        _activeRegion == LotteryRegion.mb ? 'Miền Bắc' : 'Miền Nam';
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xổ số 24/7', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Tra cứu & thống kê', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          if (_selectedIndex < 2)
            IconButton(
              tooltip: 'Đồng bộ từ nguồn',
              onPressed: _loading ? null : _synchronize,
              icon: const Icon(Icons.sync),
            ),
          IconButton(
            tooltip: _token == null ? 'Đăng nhập quản trị' : 'Đăng xuất',
            onPressed: () {
              if (_token == null) {
                unawaited(_login());
              } else {
                setState(() => _token = null);
                _notice('Đã đăng xuất.');
              }
            },
            icon: Icon(_token == null ? Icons.lock_outline : Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            DateFilter(
              start: _start,
              end: _end,
              loading: _loading,
              onChange: (start, end) => setState(() {
                _start = start;
                _end = end;
              }),
              onRefresh: _refresh,
            ),
            Expanded(
              child: _selectedIndex == 2
                  ? StatisticsView(
                      results: regionResults,
                      regionLabel: regionLabel,
                    )
                  : ResultBoard(results: regionResults),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.looks_one_outlined),
            label: 'Miền Bắc',
          ),
          NavigationDestination(
            icon: Icon(Icons.looks_two_outlined),
            label: 'Miền Nam',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
        ],
      ),
    );
  }
}
