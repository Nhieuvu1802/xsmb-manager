/// Hiện thực LocalStore cho Android/iOS/desktop.
library;

import 'local_store.dart';
import 'sqlite_local_store.dart';

Future<LocalStore> createLocalStore() async => SqliteLocalStore();
