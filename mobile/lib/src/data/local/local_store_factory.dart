/// Factory chọn hiện thực LocalStore theo nền tảng khi build.
///
/// Trên web dùng `local_store_web.dart`; trên Android/iOS/desktop dùng SQLite.
/// Cách này giữ cho `sqflite`/`path_provider` không lọt vào bản build web.
library;

import 'local_store.dart';
import 'local_store_native.dart'
    if (dart.library.js_interop) 'local_store_web.dart'
    as impl;

export 'local_store.dart';

Future<LocalStore> createLocalStore() => impl.createLocalStore();
