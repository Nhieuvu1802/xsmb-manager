/// Hiện thực LocalStore cho Flutter Web.
library;

import 'local_store.dart';
import 'web_local_store.dart';

Future<LocalStore> createLocalStore() async => WebLocalStore();
