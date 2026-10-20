import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/game/domain/otter_skin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Una nutria del catálogo sin su carpeta en pubspec.yaml solo fallaría al
  // elegirla en la app.
  test('cada nutria del catálogo tiene sus spritesheets', () async {
    for (final skin in OtterSkin.all) {
      for (final sheet in [
        skin.idleSheet,
        skin.happinessSheet,
        skin.sleepSheet,
        skin.wakeSheet,
      ]) {
        // Se decodifica de verdad: un WebP mal convertido fallaría acá.
        final bytes = await rootBundle.load(sheet);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final image = (await codec.getNextFrame()).image;
        expect((image.width, image.height), (3072, 512), reason: sheet);
      }
      expect(skin.petFrame, inInclusiveRange(0, 5));
    }
  });

  test('los ids no se repiten y uno desconocido vuelve a la clásica', () {
    final ids = OtterSkin.all.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(OtterSkin.byId('no_existe'), OtterSkin.normal);
    expect(OtterSkin.byId(null), OtterSkin.normal);
  });
}
