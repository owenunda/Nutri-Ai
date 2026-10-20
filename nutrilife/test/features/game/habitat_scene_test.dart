import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/game/domain/habitat_scene.dart';

Future<ui.Image> decode(String asset) async {
  final bytes = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada lugar tiene su fondo de día y de noche', () async {
    for (final scene in HabitatScene.all) {
      for (final asset in [scene.dayAsset, scene.nightAsset]) {
        final image = await decode(asset);
        expect((image.width, image.height), (1440, 2560), reason: asset);
      }
    }
  });

  test('el foco existe prendido y apagado', () async {
    for (final asset in [
      'assets/game/habitat/foco_encendido.webp',
      'assets/game/habitat/foco_apagado.webp',
    ]) {
      final image = await decode(asset);
      expect((image.width, image.height), (270, 521), reason: asset);
    }
  });

  test('los ids no se repiten y uno desconocido vuelve a la habitación', () {
    final ids = HabitatScene.all.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(HabitatScene.byId('no_existe'), HabitatScene.habitacion);
  });

  test('es de noche desde las 19:00 hasta las 5:59', () {
    DateTime at(int hour, [int minute = 0]) =>
        DateTime(2026, 10, 20, hour, minute);
    expect(HabitatScene.isNightAt(at(5, 59)), isTrue);
    expect(HabitatScene.isNightAt(at(6)), isFalse);
    expect(HabitatScene.isNightAt(at(18, 59)), isFalse);
    expect(HabitatScene.isNightAt(at(19)), isTrue);
  });
}
