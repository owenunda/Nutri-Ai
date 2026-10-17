import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/dio_client.dart';

import 'helpers/fake_hydration_server.dart';

/// Los widgets de la racha de agua llaman al backend por DioClient.instance.
/// En los tests responde un servidor de hidratación en memoria, vacío al
/// empezar cada test, y el resto de las rutas sigue como siempre.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final original = DioClient.instance.httpClientAdapter;
  setUp(() {
    DioClient.instance.httpClientAdapter = FakeHydrationServer(fallback: original);
  });
  tearDown(() {
    DioClient.instance.httpClientAdapter = original;
  });
  await testMain();
}
